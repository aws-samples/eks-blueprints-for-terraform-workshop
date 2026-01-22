---
title: "Webhook Configuration"
weight: 20
hidden: true
---

This configuration sets up an automated webhook system that connects CodeCommit repositories to ArgoCD for on-demand synchronization.

Key Components:

1. API Destination & Connection: Creates a secure webhook endpoint that points to your managed ArgoCD instance (/api/webhook).

2. Two EventBridge Rules that monitor git commit event for retail-store-config and platform repository

3. IAM Role: Grants EventBridge permission to invoke the ArgoCD API destination when repository changes occur.

4. Event Transformation: Converts CodeCommit events into the JSON format ArgoCD expects.

The Flow:
When you commit to either repository's main branch → CodeCommit generates an EventBridge event → EventBridge rule catches it → Transforms the payload → Calls ArgoCD webhook .

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cat <<'EOF' >> ~/environment/hub/main.tf

resource "aws_cloudwatch_event_connection" "argocd" {
  name               = "argocd-webhook-connection"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "X-GitHub-Event"
      value = "push"
    }
  }
}

resource "aws_cloudwatch_event_api_destination" "argocd" {
  name                             = "argocd-api-destination"
  description                      = "Webhook endpoint for Managed Argo CD Capability"
  invocation_endpoint              = "${aws_eks_capability.argocd.configuration.0.argo_cd.0.server_url}/api/webhook"
  http_method                      = "POST"
  connection_arn                   = aws_cloudwatch_event_connection.argocd.arn
  invocation_rate_limit_per_second = 10
}

resource "aws_iam_role" "eb_invocation_role" {
  name = "eventbridge-invoke-argocd-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "events.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "eb_invocation_policy" {
  role = aws_iam_role.eb_invocation_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "events:InvokeApiDestination"
      Effect   = "Allow"
      Resource = [aws_cloudwatch_event_api_destination.argocd.arn]
    }]
  })
}

resource "aws_cloudwatch_event_rule" "retail_store" {
  name        = "refresh-retail-store-config"
  description = "Triggers Argo CD when retail-store-config main branch is updated"
  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    resources   = [aws_codecommit_repository.retail_store_config.arn]
    detail = {
      event         = ["referenceCreated", "referenceUpdated"]
      referenceType = ["branch"]
      referenceName = ["main"]
    }
  })
}

resource "aws_cloudwatch_event_target" "retail_store" {
  rule      = aws_cloudwatch_event_rule.retail_store.name
  arn       = aws_cloudwatch_event_api_destination.argocd.arn
  role_arn  = aws_iam_role.eb_invocation_role.arn
  http_target {
    header_parameters = {
      "Content-Type"   = "application/json"
      "X-GitHub-Event" = "push"
    }
  }
  input_transformer {
    input_paths = { repo = "$.detail.repositoryName" }
    input_template = <<EOT
{
  "repository": {
    "html_url": "${aws_codecommit_repository.retail_store_config.clone_url_http}"
  }
}
EOT
  }
}

resource "aws_cloudwatch_event_rule" "platform" {
  name        = "platform-refresh"
  description = "Triggers Argo CD when Platform main branch is updated"
  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    resources   = [aws_codecommit_repository.platform.arn]
    detail = {
      event         = ["referenceCreated", "referenceUpdated"]
      referenceType = ["branch"]
      referenceName = ["main"]
    }
  })
}

resource "aws_cloudwatch_event_target" "platform" {
  rule      = aws_cloudwatch_event_rule.platform.name
  arn       = aws_cloudwatch_event_api_destination.argocd.arn
  role_arn  = aws_iam_role.eb_invocation_role.arn
  http_target {
    header_parameters = {
      "Content-Type"   = "application/json"
      "X-GitHub-Event" = "push"
    }
  }
  input_transformer {
    input_paths = { repo = "$.detail.repositoryName" }
    input_template = <<EOT
{
  "repository": {
    "html_url": "${aws_codecommit_repository.platform.clone_url_http}"
  }
}
EOT
  }
}
EOF
cd ~/environment/hub
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=terraform}
cat <<'EOF' >> ~/environment/hub/main.tf

################################################################################
# Lambda Function for CodeCommit to ArgoCD Webhook
################################################################################

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
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/codecommit-webhook:*"
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
  filename      = "/home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/lambda/codecommit-webhook.zip"
  function_name = "codecommit-webhook"
  role          = aws_iam_role.codecommit_webhook_lambda.arn
  handler       = "lambda_function.lambda_handler"
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
    custom_data     = aws_eks_capability.argocd.configuration.0.argo_cd.0.server_url
  }
}
EOF

cd ~/environment/hub
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->

