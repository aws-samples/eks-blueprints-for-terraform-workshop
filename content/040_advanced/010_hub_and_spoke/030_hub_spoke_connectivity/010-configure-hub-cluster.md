---
title: "Configure Hub Cluster"
weight: 10
---

In this chapter, you will create a role that is assumed by the Hub Cluster's Argo CD.

![Hub Role](/static/images/hub-spoke-hub-role.jpg)

### 1. Create Role

Create a role named hub-cluster-argocd-hub that can be assumed by the Argo CD service accounts running on the EKS cluster. This IAM role is authorized to assume other IAM roles associated with remote EKS spoke clusters within the same AWS account, allowing the central Argo CD cluster to deploy applications and manage resources across multiple EKS clusters.

The IAM policy aws_assume_policy attached to the hub-cluster-argocd-hub role includes conditions that restrict the role assumption to the current AWS account and the specific EKS cluster where Argo CD is running. This ensures secure and controlled access to the assumed roles, adhering to the principle of least privilege.

By creating this role and policy, you establish a centralized identity management approach, enabling Argo CD to seamlessly deploy applications and manage resources across multiple EKS clusters within the same AWS account while maintaining proper access controls and security best practices.

Add Variable to save ArgoCD Role in SSM Parameters

```json
cat <<'EOF' >> ~/environment/hub/variables.tf
variable "ssm_parameter_name_argocd_role_suffix" {
  description = "SSM parameter name for ArgoCD role"
  type        = string
  default     = "argocd-central-role"
}
EOF
```

```json
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
```

### 2. Apply Terraform

```bash
cd ~/environment/hub
terraform init
terraform apply --auto-approve
```

### 3. Argo CD Pods to use new service account token

When Argo CD was originally installed, there was no pod identity association. The pod identity was added in this chapter. Let's recreate the Argo CD pods so they get setup for pod identity.

```bash
kubectl rollout restart -n argocd deployment argocd-server --context hub-cluster
kubectl rollout restart -n argocd statefulset argocd-application-controller --context hub-cluster
```

You can verify that EKS Pod Identity is correctly applied by looking at the injected environment variables:

```bash
kubectl --context hub-cluster exec -it deployment/argocd-server -n argocd -- env | grep AWS
```

should be like:

```
AWS_CONTAINER_CREDENTIALS_FULL_URI=http://169.254.170.23/v1/credentials
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_DEFAULT_REGION=us-east-2
AWS_REGION=us-east-2
AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE=/var/run/secrets/pods.eks.amazonaws.com/serviceaccount/eks-pod-identity-token
```

:::alert{header=Note type=warning}
After the rollout restart, the argocd Pods are replaced, that means that the port-forward has also been broken. you may need to execute again the command to retrieve access to Argo CD UI.

```bash
argocd_hub_credentials
```

:::
