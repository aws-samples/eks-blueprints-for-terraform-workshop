---
title: "Install Argo CD with GitOps Bridge"
weight: 10
---

In this chapter, we will install Argo CD on the hub cluster using GitOps Bridge. It also creates a Kubernetes secret to store metadata like labels and annotations about the cluster.

![EKS Cluster](/static/images/argocd-bootstrap-install.jpg)

### 1. Configure GitOps Bridge

GitOps Bridge handles the initial configuration so you can get Argo CD up and running with minimal setup on your part. It configures loadBalancer to access the dashboard.

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
  environment     = "hub"
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

### 2. Create value file for ArgoCD

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

### 2. Apply Terraform

```bash
cd ~/environment/hub
terraform init
terraform apply -auto-approve
```

### 3. Validate Argo CD install

Get Argo CD dashboard URL:

```bash
argocd_hub_credentials
```

Copy the Argo CD password from the above command and use `admin` username to login to Argo CD UI.

You can click on the output link and select **Open**, to access the Argo CD user interface.

> As we are in a lab workshop, we don't have custom domain, so we uses default one. You can ignore the warning about self signed certificate when you access the dashboard, this is fine for this workshop.

After GitOps Bridge installs Argo CD, you can access the Argo CD dashboard using the default admin user and the auto-generated password.
In the Argo CD UI, you will find the hub cluster already registered under **Settings > Clusters**. This means Argo CD has capability to administer the hub-cluster.

![EKS Cluster](/static/images/argocd-cluster-object.png)

You can also validate that the gitops-bridge as correctly created the secrets for this EKS cluster in the argocd namespace:

```bash
kubectl --context hub-cluster get secrets -n argocd hub-cluster
```

Expected output:
```
NAME          TYPE     DATA   AGE
hub-cluster   Opaque   3      4m41s
```