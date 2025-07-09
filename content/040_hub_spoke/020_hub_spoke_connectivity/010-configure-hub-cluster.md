---
title: "Configure Hub Cluster"
weight: 10
---

<!-- cspell:disable-next-line -->

::video{id=p3_gHW9QX2g}

In this chapter you will create a role that is assumed by ArgoCD service accounts. This role will have assume role permission for other roles.

![Hub Role](/static/images/hub-spoke-hub-role.png)

### 1. Create ArgoCD Hub Role

Now, let's create the IAM role and associated resources:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='24,60,66,73' }
# Variable to save the ArgoCD Role in SSM Parameters
cat <<'EOF' >> ~/environment/hub/variables.tf
variable "ssm_parameter_name_argocd_role_suffix" {
  description = "SSM parameter name for ArgoCD role"
  type        = string
  default     = "argocd-central-role"
}
EOF


cat <<'EOF' >> ~/environment/hub/pod-identity.tf
################################################################################
# ArgoCD EKS Pod Identity Association
################################################################################
resource "aws_iam_role" "argocd_hub" {
  name_prefix = "${local.context_prefix}-argocd-hub"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEksAuthToAssumeRoleForPodIdentity"
        Effect = "Allow"
        Action = ["sts:AssumeRole", "sts:TagSession"]
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "argocd"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["sts:AssumeRole", "sts:TagSession"]
          Effect   = "Allow"
          Resource = "*"
          Condition = {
            StringEquals = {
              "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            }
            ArnEquals = {
              "aws:SourceArn" = module.eks.cluster_arn
            }
          }
        },
      ]
    })
  }

  tags = local.tags
}


# Creating parameter for all clusters to read
resource "aws_ssm_parameter" "argocd_hub_role" {
  name  = "${local.context_prefix}-${var.ssm_parameter_name_argocd_role_suffix}"
  type  = "String"
  value = aws_iam_role.argocd_hub.arn
}

resource "aws_eks_pod_identity_association" "argocd_controller" {
  cluster_name    = module.eks.cluster_name
  namespace       = "argocd"
  service_account = "argocd-application-controller"
  role_arn        = aws_ssm_parameter.argocd_hub_role.value
  tags = local.tags
}
resource "aws_eks_pod_identity_association" "argocd_server" {
  cluster_name    = module.eks.cluster_name
  namespace       = "argocd"
  service_account = "argocd-server"
  role_arn        = aws_ssm_parameter.argocd_hub_role.value
  tags = local.tags
}
EOF
:::
<!-- prettier-ignore-end -->

Line 14: Both AssumeRole and TagSession are required for pod identity  
Line 50: Store hub role ARN in a parameter store. Spoke Cluster terraform module looks the parameter for the arn. It needs this to create trust with the spoke  
Line 56-63: Associate the role with the ArgoCD service accounts

### 2. Apply Terraform

Apply the changes to create the IAM role and associated resources:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
cd ~/environment/hub
terraform init
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->

### 3. Restart ArgoCD Pods to Apply Pod Identity

When we initially installed ArgoCD, there was no pod identity association. The pod identity was added in this chapter. Let's recreate the ArgoCD pods so they get configured for pod identity:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
kubectl rollout restart -n argocd deployment argocd-server --context hub-cluster
kubectl rollout restart -n argocd statefulset argocd-application-controller --context hub-cluster
:::
<!-- prettier-ignore-end -->
