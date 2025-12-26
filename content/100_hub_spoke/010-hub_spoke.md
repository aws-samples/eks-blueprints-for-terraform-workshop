---
title: "Bootstrap Repo Registration"
weight: 10
---

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }

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
# IAM policy for Secrets Manager read access
################################################################################
resource "aws_eks_access_entry" "argocd_admin" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = data.terraform_remote_state.hub.outputs.eks_capability_argocd_arn
  kubernetes_groups = []
  type             = "STANDARD"
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
