---
title: "Hub-Spoke Access"
weight: 10
---

Hub-Spoke access in ArgoCD involves granting the ArgoCD Capability running on the hub cluster access to spoke clusters (dev and prod). This enables ArgoCD to deploy and manage applications across multiple clusters from a centralized control plane.

### The Challenge

ArgoCD running on the hub cluster needs permissions to:
- Create and manage Kubernetes resources on spoke clusters
- Deploy applications to dev and prod environments
- Monitor application health across all clusters

Without proper access configuration, ArgoCD cannot manage workloads on remote clusters.

### How it Works

We configure cross-cluster access using AWS EKS Access Entries, which provide a secure way to grant IAM principals access to EKS clusters. The ArgoCD Capability service-linked role(AmazonEKSCapabilityArgoCDRole) from the hub cluster is granted cluster admin permissions on both dev and prod spoke clusters.

### 1. Implementation Steps

The configuration uses:
- Remote State Data Source: Retrieves the ArgoCD service role ARN from hub cluster
- EKS Access Entry: Grants the service role access to spoke clusters  
- Cluster Admin Policy: Provides full administrative permissions on spoke clusters

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash }
cat <<'EOF' >> ~/environment/spoke/remote_state.tf
data "terraform_remote_state" "hub" {
  backend = "s3"

  config = {
    bucket = "${data.aws_ssm_parameter.tfstate_bucket.value}"
    key    = "hub/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
EOF

cat <<'EOF' >> ~/environment/spoke/main.tf
################################################################################
# EKS Access Entry for ArgoCD Service Role
################################################################################
resource "aws_eks_access_entry" "argocd_admin" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = data.terraform_remote_state.hub.outputs.eks_capability_argocd_arn
  kubernetes_groups = []
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "argocd_admin_policy" {
  cluster_name  = module.eks.cluster_name
  principal_arn = data.terraform_remote_state.hub.outputs.eks_capability_argocd_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
EOF

cd ~/environment/spoke
terraform workspace select dev
terraform apply --auto-approve
terraform workspace select prod
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->

### 2. Verification Access Entry

After applying the configuration, you can verify the access entries in the AWS Console:

1. Navigate to EKS → Clusters → [ argocd-spoke-dev or argocd-spoke-prod] → Access
2. Confirm the ArgoCD service role(AmazonEKSCapabilityArgoCDRole) appears with cluster admin permissions

![Hub-Spoke Access Architecture](/static/images/hub-spoke-access/hub-spoke-access-entry-dev.png)

This configuration enables ArgoCD on the hub cluster access to both dev and prod spoke clusters.
