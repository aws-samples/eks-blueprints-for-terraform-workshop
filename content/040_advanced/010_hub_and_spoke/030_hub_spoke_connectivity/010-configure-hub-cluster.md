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

<!--:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='29,35,50,56'}-->

```json
cat <<'EOF' >> ~/environment/hub/main.tf

################################################################################
# Argo CD Pod identity EKS Access
################################################################################
data "aws_iam_policy_document" "eks_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole","sts:TagSession"]
  }
}
resource "aws_iam_role" "argocd_hub" {
  name               = "${module.eks.cluster_name}-argocd-hub"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
}
data "aws_iam_policy_document" "aws_assume_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["sts:AssumeRole","sts:TagSession"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["${module.eks.cluster_arn}"]
    }
  }
}

resource "aws_iam_policy" "aws_assume_policy" {
  name        = "${module.eks.cluster_name}-argocd-aws-assume"
  description = "IAM Policy for Argo CD Hub"
  policy      = data.aws_iam_policy_document.aws_assume_policy.json
  tags        = local.tags
}
resource "aws_iam_role_policy_attachment" "aws_assume_policy" {
  role       = aws_iam_role.argocd_hub.name
  policy_arn = aws_iam_policy.aws_assume_policy.arn
}
resource "aws_eks_pod_identity_association" "argocd_app_controller" {
  cluster_name    = module.eks.cluster_name
  namespace       = "argocd"
  service_account = "argocd-application-controller"
  role_arn        = aws_iam_role.argocd_hub.arn
}
resource "aws_eks_pod_identity_association" "argocd_api_server" {
  cluster_name    = module.eks.cluster_name
  namespace       = "argocd"
  service_account = "argocd-server"
  role_arn        = aws_iam_role.argocd_hub.arn
}

EOF
```

<!--:::-->

We also configure EKS Pod Identity, with a Pod association, allowing our Argo CD application server and controller, to assume that role.

### 2. Add outputs

Output the role ARN as it is needed by the spoke cluster to create the trust relationship.

```bash
cat <<'EOF' >> ~/environment/hub/outputs.tf
output "argocd_iam_role_arn" {
  description = "IAM Role for Argo CD Cluster Hub, use to connect to spoke clusters"
  value       = aws_iam_role.argocd_hub.arn
}

EOF
```

### 3. Apply Terraform

```bash
cd ~/environment/hub
terraform init
terraform apply --auto-approve
```

### 4. Argo CD Pods to use new service account token

When Argo CD was originally installed, there was no pod identity association. The pod identity was added in this chapter. Let's recreate the Argo CD pods so they get setup for pod identity.

```bash
kubectl rollout restart -n argocd deployment argo-cd-argocd-server --context hub-cluster
kubectl rollout restart -n argocd statefulset argo-cd-argocd-application-controller --context hub-cluster
```

You can verify that EKS Pod Identity is correctly applied by looking at the injected environment variables:

```bash
kubectl --context hub-cluster exec -it deployment/argo-cd-argocd-server -n argocd -- env | grep AWS
```

should be like:

```
AWS_CONTAINER_CREDENTIALS_FULL_URI=http://169.254.170.23/v1/credentials
AWS_STS_REGIONAL_ENDPOINTS=regional
AWS_DEFAULT_REGION=us-east-2
AWS_REGION=us-east-2
AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE=/var/run/secrets/pods.eks.amazonaws.com/serviceaccount/eks-pod-identity-token
```
