---
title: 'Install Argo CD with GitOps Bridge'
weight: 10
---

In this chapter, we will install Argo CD on the hub cluster using GitOps Bridge. It also creates a Kubernetes secret to store metadata like labels and annotations about the cluster.

![EKS Cluster](/static/images/argocd-bootstrap-install.png)

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
  source  = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.0.1"
  cluster = {
    cluster_name = module.eks.cluster_name
    environment  = local.environment
    #enablemetadata metadata     = local.addons_metadata
    #enablemetadata addons       = local.addons
  }
  #enableapps apps = local.argocd_apps
  argocd = {
    namespace        = local.argocd_namespace
    chart_version    = "6.7.12"
    timeout          = 600
    create_namespace = false
    set = [
      {
        name  = "server.service.type"
        value = "LoadBalancer"
      }
    ]
  }
  
}

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
export ARGOCD_SERVER=$(kubectl --context hub get svc argo-cd-argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')
echo export ARGOCD_SERVER=\"$ARGOCD_SERVER\" >> ~/.bashrc
echo "https://$ARGOCD_SERVER"
```

You can click on the outputed link and select **Open**, to access the Argo CD user interface.

Get ArgoCD password: 

```bash
ARGOCD_PWD=$(kubectl --context hub -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo export ARGOCD_PWD=\"$ARGOCD_PWD\" >> ~/.bashrc
echo "Argo CD admin password: $ARGOCD_PWD"
```

The user will be **admin** and the password the result of the previous command.

> As we are in a lab workshop, we don't have custom domain, so we uses default one. You can ignore the warning about self signed certificate when you access the dashboard, this is fine for this workshop.

After GitOps Bridge installs Argo CD, you can access the Argo CD dashboard using the default admin user and the auto-generated password. 
In the Argo CD UI, you will find the hub cluster already registered under **Settings > Clusters**. This means Argo CD has capability to administer the hub-cluster.  

![EKS Cluster](/static/images/argocd-cluster-object.png)


You can also validate that the gitops-bridge as correctly created the secrets for this EKS cluster in the argocd namespace:

```bash
kubectl --context hub get secrets -n argocd hub-cluster
```