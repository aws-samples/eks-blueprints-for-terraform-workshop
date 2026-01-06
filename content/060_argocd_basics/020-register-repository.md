---
title: "Register Repository"
weight: 20
---

<!-- cspell:disable-next-line -->

::video{id=t8ESicSaITQ}

ArgoCD needs access to Git repositories( GitHub, Gitlab, Bitbucket, CodeCommit) to pull application manifests and configurations. The approach depends on your repository type:

### 1. Public Repositories:

- No configuration needed
- ArgoCD can access them directly

### 2. Private Repositories

- Register under Settings > Repositories in ArgoCD dashboard
- Provide credentials (username/password, SSH keys, tokens etc)

### 3. AWS CodeCommit & ECR (Our Workshop):

- No manual registration required
- Access granted through EKS capability service-linked role(AmazonEKSCapabilityArgoCDRole)
- IAM permissions allow ArgoCD to authenticate automatically

### 4. Configure Access to CodeCommit and ECR

The commands below add CodeCommit and ECR permissions to the service-linked role, enabling our managed ArgoCD instance to access our private repositories without storing credentials in ArgoCD itself.

![Register CodeCommit ECR](/static/images/argobasics/register-repo-codecommit-ecr.png)

<!-- prettier-ignore-start -->

:::code{showCopyAction=true showLineNumbers=false language=bash}
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

### 5. Validate Service-Linked Role Access

Navigate to the AWS Console to verify that the IAM policies have been successfully attached to the ArgoCD service-linked role.

1. Go to IAM Console → Roles
2. Search for AmazonEKSCapabilityArgoCDRole
3. Click on the role to view its details
4. Navigate to the Permissions tab
5. Verify the following policies are attached:
   - ✅ **codecommit-readonly-policy** (for Git repository access)
   - ✅ **ecr-helm-readonly-policy** (for Helm chart access)

This confirms that ArgoCD now has the necessary permissions to:

- Pull from CodeCommit repositories (platform, retail-store-app, retail-store-config)
- Access ECR registries for Helm charts and container images

![Service Linked Role Access](/static/images/argobasics/register-repo-console.png)
