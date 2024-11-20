---
title: "Install Argo CD with GitOps Bridge"
weight: 10
---

In this chapter, we will install Argo CD on the hub cluster using GitOps Bridge. GitOps Bridge also creates a Kubernetes secret to store metadata like labels and annotations about the cluster.

![EKS Cluster](/static/images/argocd-bootstrap-install.jpg)

### 1. Configure GitOps Bridge

GitOps Bridge handles the initial configuration to get Argo CD up and running with minimal setup. It configures a LoadBalancer to provide access to the dashboard.

```bash
cat <<'EOF' >> ~/environment/hub/main.tf
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
    }
  }
}

locals{
  argocd_namespace = "argocd"
  environment     = "control-plane"
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = local.argocd_namespace
  }
}
################################################################################
# GitOps Bridge: Bootstrap
################################################################################
module "gitops_bridge_bootstrap" {
  source = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.1.0"
  cluster = {
    cluster_name = module.eks.cluster_name
    environment  = local.environment
    #enablemetadata metadata     = local.addons_metadata
    #enablemetadata addons       = local.addons
  }

  #enableapps apps = local.argocd_apps
  argocd = {
    name = "argocd"
    namespace        = local.argocd_namespace
    chart_version    = "7.5.2"
    values = [file("${path.module}/argocd-initial-values.yaml")]
    timeout          = 600
    create_namespace = false
  }
}
EOF

```

### 2. Create value file for Argo CD

```bash
cat <<'EOF' >> ~/environment/hub/argocd-initial-values.yaml
global:
  tolerations:
  - key: "CriticalAddonsOnly"
    operator: "Exists"
controller:
  env:
    - name: ARGOCD_SYNC_WAVE_DELAY
      value: '30'
configs:
  cm:
    ui.bannercontent: "Management Environment"
  params:
    server.insecure: true
    server.basehref: /proxy/8081/
EOF
```

### 3. Apply Terraform

```bash
cd ~/environment/hub
terraform init
terraform apply -auto-approve
```

### 4. Validate Argo CD install

To retrieve the Argo CD dashboard URL, execute:

```bash
argocd_hub_credentials
```

Copy the Argo CD password from the above command and use `admin` as the username to log in to the Argo CD UI.

We can click on the output link and select **Open** to access the Argo CD user interface.

::alert[As this is a lab workshop environment, we do not have a custom domain, so we use the default one. We can ignore the warning about the self-signed certificate when accessing the dashboard.]{header="Note"}

After GitOps Bridge installs Argo CD, we can access the Argo CD dashboard using the default admin user and the auto-generated password.
In the Argo CD UI, we will find the hub cluster already registered under **Settings > Clusters**. This means Argo CD has the capability to administer the hub-cluster.

![EKS Cluster](/static/images/argocd-cluster-object.png)

We can also validate that gitops-bridge has correctly created the secrets for this EKS cluster in the argocd namespace:

```bash
kubectl --context hub-cluster get secrets -n argocd hub-cluster
```

Expected output:

```
NAME          TYPE     DATA   AGE
hub-cluster   Opaque   3      4m41s
```
