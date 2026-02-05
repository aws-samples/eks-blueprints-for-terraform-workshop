---
title: "Webhook Configuration"
weight: 10
---

This configuration sets up an automated webhook system that connects CodeCommit repositories to ArgoCD for on-demand synchronization.

This approach uses a Lambda function triggered directly by CodeCommit to send webhook notifications to ArgoCD.

Key Components:

1. CodeCommit Trigger: Directly invokes Lambda function when commits are pushed to the main branch.

2. Lambda Function: Processes CodeCommit events and sends formatted webhook payloads to ArgoCD.

The Flow:
When you commit to the platform repository's main branch → CodeCommit trigger fires → Lambda function executes → Retrieves commit details and changed files → Sends GitHub-compatible webhook to ArgoCD.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=terraform}
cat <<'EOF' >> ~/environment/hub/main.tf

################################################################################
# Lambda Function for CodeCommit to ArgoCD Webhook
################################################################################

# Generate webhook secret
resource "random_password" "webhook_secret" {
  length  = 32
  special = false
}

# IAM Role for Lambda
resource "aws_iam_role" "codecommit_webhook_lambda" {
  name = "codecommit-webhook-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Lambda Execution Policy
resource "aws_iam_role_policy" "lambda_execution" {
  name = "lambda-execution-policy"
  role = aws_iam_role.codecommit_webhook_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/codecommit_webhook:*"
        ]
      }
    ]
  })
}

# CodeCommit Access Policy
resource "aws_iam_role_policy" "codecommit_access" {
  name = "codecommit-access-policy"
  role = aws_iam_role.codecommit_webhook_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codecommit:GetCommit",
          "codecommit:GetDifferences",
          "codecommit:GetRepository",
          "codecommit:GitPull"
        ]
        Resource = aws_codecommit_repository.platform.arn
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "codecommit_webhook" {
  filename      = "/home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/lambda/codecommit_webhook.zip"
  function_name = "codecommit_webhook"
  role          = aws_iam_role.codecommit_webhook_lambda.arn
  handler       = "codecommit_webhook.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

}

# Lambda Permission for CodeCommit Trigger
resource "aws_lambda_permission" "codecommit_trigger" {
  statement_id  = "AllowExecutionFromCodeCommit"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.codecommit_webhook.function_name
  principal     = "codecommit.amazonaws.com"
  source_arn    = aws_codecommit_repository.platform.arn
}

# CodeCommit Trigger
resource "aws_codecommit_trigger" "platform_webhook" {
  repository_name = aws_codecommit_repository.platform.repository_name

  trigger {
    name            = "commit"
    events          = ["updateReference"]
    destination_arn = aws_lambda_function.codecommit_webhook.arn
    custom_data     = jsonencode({
      hostname = aws_eks_capability.argocd.configuration.0.argo_cd.0.server_url
      secret   = random_password.webhook_secret.result
    })
  }
}

# Update ArgoCD webhook secret
resource "kubectl_manifest" "argocd_webhook_secret" {
  force_conflicts   = true
  server_side_apply = true
  
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: argocd-webhook-creds-secret
      namespace: argocd
    stringData:
      webhook.github.secret: "${random_password.webhook_secret.result}"
  YAML

  depends_on = [aws_eks_capability.argocd]
}
EOF

cd ~/environment/hub
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->
