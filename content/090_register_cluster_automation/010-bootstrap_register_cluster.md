---
title: "Bootstrap the Cluster Repository"
weight: 10
---

### 1. ECR ReadOnly access

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cat <<'EOF' >> ~/environment/hub/main.tf
################################################################################
# IAM policy for ECR Helm chart access
################################################################################
resource "aws_iam_policy" "ecr_helm_readonly" {
  name        = "ecr-helm-readonly-policy"
  description = "Read-only access to ECR for Helm charts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:ListImages"
        ]
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "argocd_ecr_helm" {
  role       = aws_iam_role.eks_capability_argocd.name
  policy_arn = aws_iam_policy.ecr_helm_readonly.arn
}
EOF
cd ~/environment/hub
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->

### 2. Register Hub Cluster

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }

cp  /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/bootstrap/register-cluster.yaml $GITOPS_DIR/platform/bootstrap
cd ${GITOPS_DIR}/platform/bootstrap
git add .
git commit -m "add bootstrap cluster registration"
git push 
:::
<!-- prettier-ignore-end -->

### 3. Copy Values

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
mkdir -p $GITOPS_DIR/platform/register-cluster/hub
cp /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/hub-register-cluster-values.yaml $GITOPS_DIR/platform/register-cluster/hub/values.yaml
mkdir -p $GITOPS_DIR/platform/register-cluster/dev
cp /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/dev-register-cluster-values.yaml $GITOPS_DIR/platform/register-cluster/dev/values.yaml
mkdir -p $GITOPS_DIR/platform/register-cluster/prod
cp /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/prod-register-cluster-values.yaml $GITOPS_DIR/platform/register-cluster/prod/values.yaml

cp /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/default-register-cluster-values.yaml $GITOPS_DIR/platform/register-cluster/values.yaml
cd $GITOPS_DIR/platform
git add .
git commit -m "add hub cluster registration values and default registration values"
git push 
:::
<!-- prettier-ignore-end -->
