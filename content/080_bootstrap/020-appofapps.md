---
title: "Bootstrap"
weight: 20
---

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cat <<'EOF' >> ~/environment/hub/main.tf
################################################################################
# IAM policy for CodeCommit access
################################################################################
resource "aws_iam_policy" "codecommit_readonly" {
  name        = "codecommit-readonly-policy"
  description = "Read-only access to CodeCommit repositories for ArgoCD"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:GitPull",
          "codecommit:ListRepositories",
          "codecommit:ListBranches",
          "codecommit:ListTagsForResource",
          "codecommit:GetRepository",
          "codecommit:GetBranch",
          "codecommit:GetCommit"
        ]
        Resource = [
          aws_codecommit_repository.platform.arn,
          aws_codecommit_repository.retail_store_app.arn,
          aws_codecommit_repository.retail_store_config.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "argocd_codecommit" {
  role       = aws_iam_role.eks_capability_argocd.name
  policy_arn = aws_iam_policy.codecommit_readonly.arn
}
EOF
cd ~/environment/hub
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }

cp  /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/bootstrap/bootstrap.yaml  ~/environment/basics
cd ~/environment/basics
kubectl apply -f bootstrap.yaml
:::
<!-- prettier-ignore-end -->
