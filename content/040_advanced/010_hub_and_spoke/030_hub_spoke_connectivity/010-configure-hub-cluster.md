---
title: 'Configure Hub Cluster'
weight: 10
---

In this chapter, you will create a role that is assumed by the Hub Cluster's Argo CD.

![Hub Role](/static/images/hub-spoke-hub-role.png)

### 1. Create Role 

Create a role that can assume any role in the account and that can be assumed by the Argo CD service accounts.

```bash
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

<!--### 3. Annotate Argo CD role -- Satish Is this required?-->

<!--The role created for Argo CD needs to be set on the Argo CD service accounts. This is accomplished by setting the role in the hub cluster's annotation. The ApplicationSet will pick up this annotation and set the role on the Argo CD service accounts.-->

<!--```bash-->
<!--sed -i "s/#enableirsarole //g" ~/environment/hub/main.tf-->
<!--```-->
<!--The code snippet above adds a role annotation. The changes are highlighted as follows:-->

<!--:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='5-5'}-->
<!--addons_metadata = merge(-->
<!--  .-->
<!--  .-->
<!--  {-->
<!--    argocd_iam_role_arn = aws_iam_role.argocd_hub.arn-->
<!--    argocd_namespace    = local.argocd_namespace-->
<!--  }-->
<!--  .-->
<!--  .-->
<!--:::-->


### 3. Apply Terraform

```bash
cd ~/environment/hub
terraform init
terraform apply --auto-approve
```
### 4. Argo CD Pods to use new service account token

When Argo CD was originally installed, there was no pod identity association. The pod identity was added in this chapter. Let's recreate the Argo CD pods so they get setup for pod identity.

```bash
kubectl rollout restart -n argocd deployment argo-cd-argocd-server --context hub
kubectl rollout restart -n argocd statefulset argo-cd-argocd-application-controller --context hub
```