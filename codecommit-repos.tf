resource "aws_codecommit_repository" "platform" {
  repository_name = "platform"
  description     = "Platform GitOps repository for ArgoCD configurations"

  tags = {
    Name        = "platform"
    Environment = "workshop"
    Purpose     = "gitops"
  }
}

resource "aws_codecommit_repository" "retail_store_app" {
  repository_name = "retail-store-app"
  description     = "Retail store application repository"

  tags = {
    Name        = "retail-store-app"
    Environment = "workshop"
    Purpose     = "application"
  }
}

resource "aws_codecommit_repository" "retail_store_config" {
  repository_name = "retail-store-config"
  description     = "Retail store configuration repository"

  tags = {
    Name        = "retail-store-config"
    Environment = "workshop"
    Purpose     = "configuration"
  }
}

# Outputs for use in scripts
output "platform_clone_url_http" {
  description = "HTTP clone URL for platform repository"
  value       = aws_codecommit_repository.platform.clone_url_http
}

output "retail_store_app_clone_url_http" {
  description = "HTTP clone URL for retail-store-app repository"
  value       = aws_codecommit_repository.retail_store_app.clone_url_http
}

output "retail_store_config_clone_url_http" {
  description = "HTTP clone URL for retail-store-config repository"
  value       = aws_codecommit_repository.retail_store_config.clone_url_http
}

output "codecommit_repositories" {
  description = "All CodeCommit repository information"
  value = {
    platform = {
      name      = aws_codecommit_repository.platform.repository_name
      clone_url = aws_codecommit_repository.platform.clone_url_http
      arn       = aws_codecommit_repository.platform.arn
    }
    retail_store_app = {
      name      = aws_codecommit_repository.retail_store_app.repository_name
      clone_url = aws_codecommit_repository.retail_store_app.clone_url_http
      arn       = aws_codecommit_repository.retail_store_app.arn
    }
    retail_store_config = {
      name      = aws_codecommit_repository.retail_store_config.repository_name
      clone_url = aws_codecommit_repository.retail_store_config.clone_url_http
      arn       = aws_codecommit_repository.retail_store_config.arn
    }
  }
}
