---
title: "Webhook Configuration"
weight: 50
---

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