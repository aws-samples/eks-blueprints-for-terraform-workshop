data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_session_context" "current" {
  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = data.aws_caller_identity.current.arn
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
  }
}

locals{
  context_prefix   = var.project_context_prefix
  name            = "argocd-hub"
  region          = data.aws_region.current.id
  cluster_version = var.kubernetes_version
  enable_irsa = var.enable_irsa

  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_ids["hub"]
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets["hub"]

  authentication_mode = var.authentication_mode

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-samples/eks-blueprints-for-terraform-workshop"
  }
}

data "aws_iam_role" "eks_admin_role_name" {
  name = var.eks_admin_role_name
}

################################################################################
# EKS Cluster
################################################################################
#tfsec:ignore:aws-eks-enable-control-plane-logging
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                              = local.name
  kubernetes_version                = local.cluster_version
  endpoint_public_access    = true

  authentication_mode = local.authentication_mode

  enable_irsa = local.enable_irsa

  # Combine root account, current user/role and additional roles to be able to access the cluster KMS key - required for terraform updates
  kms_key_administrators = distinct(concat([
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"],
    [data.aws_iam_session_context.current.issuer_arn]
  ))

  enable_cluster_creator_admin_permissions = true
  access_entries = {
    # One access entry with a policy associated
    eks_admin = {
      principal_arn     = data.aws_iam_role.eks_admin_role_name.arn
      policy_associations = {
        argocd = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    }
  }

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose","system"]
  }

  tags = local.tags
}


################################################################################
# SSO - Enable IAM Identity Center if not already enabled
################################################################################
resource "terraform_data" "enable_sso" {
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Checking SSO status in region ${local.region}..."
      
      if ! aws sso-admin list-instances --region ${local.region} --output json | jq -e '.Instances | length > 0' > /dev/null 2>&1; then
        echo "Enabling IAM Identity Center..."
        aws sso-admin create-instance --region ${local.region}
        
        # Wait for SSO to be ready
        echo "Waiting for SSO to be ready..."
        for i in {1..60}; do
          if aws sso-admin list-instances --region ${local.region} --output json | jq -e '.Instances[] | select(.Status == "ACTIVE")' > /dev/null 2>&1; then
            echo "SSO is ready - printing instance details:"
            aws sso-admin list-instances --region ${local.region} --output json
            sleep 5  # Extra buffer
            break
          fi
          echo "Waiting for SSO to become ACTIVE... ($i/60)"
          sleep 10
        done
      else
        echo "IAM Identity Center already enabled"
      fi
      
      # Verify SSO is working
      aws sso-admin list-instances --region ${local.region} --output json
    EOT
  }
}

# Get SSO instance details with validation
data "aws_ssoadmin_instances" "main" {
  depends_on = [terraform_data.enable_sso]
}

# Validate that we have SSO instances
locals {
  sso_instances_count   = length(data.aws_ssoadmin_instances.main.arns)
  sso_instance_arn      = local.sso_instances_count > 0 ? tolist(data.aws_ssoadmin_instances.main.arns)[0] : ""
  sso_identity_store_id = local.sso_instances_count > 0 ? tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0] : ""
}

# Validation check
resource "terraform_data" "validate_sso" {
  depends_on = [data.aws_ssoadmin_instances.main]
  
  lifecycle {
    precondition {
      condition     = local.sso_instances_count > 0
      error_message = "No SSO instances found. SSO enablement may have failed."
    }
    
    precondition {
      condition     = local.sso_identity_store_id != ""
      error_message = "SSO identity store ID is empty. SSO may not be properly configured."
    }
  }
}

################################################################################
# Cognito User Pool for Identity Center integration
################################################################################

# Random suffix for unique domain
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Cognito User Pool
resource "aws_cognito_user_pool" "workshop" {
  name = "argocd-workshop-users"
  
  password_policy {
    minimum_length    = 8
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  tags = local.tags
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "workshop" {
  domain       = "argocd-workshop-${random_string.suffix.result}"
  user_pool_id = aws_cognito_user_pool.workshop.id
}

# ArgoCD Admins Group
resource "aws_cognito_user_group" "argocd_admins" {
  name         = "ArgocdAdmins"
  user_pool_id = aws_cognito_user_pool.workshop.id
  description  = "ArgoCD administrators group"
}

# ArgoCD Admin User
resource "aws_cognito_user" "argocd_admin" {
  user_pool_id = aws_cognito_user_pool.workshop.id
  username     = "argocdadmin"
  
  password = "argocdonaws"
}

# Group Membership
resource "aws_cognito_user_in_group" "argocd_admin_membership" {
  user_pool_id = aws_cognito_user_pool.workshop.id
  group_name   = aws_cognito_user_group.argocd_admins.name
  username     = aws_cognito_user.argocd_admin.username
}

################################################################################
# EKS Capability - Create IAM role for ArgoCD capability
################################################################################
resource "aws_iam_role" "eks_capability_argocd" {
  name = "AmazonEKSCapabilityArgoCDRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "capabilities.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = local.tags
}

################################################################################
# Enable ArgoCD capability
################################################################################
resource "aws_eks_capability" "argocd" {
  cluster_name              = module.eks.cluster_name
  capability_name           = "argocd"
  type                      = "ARGOCD"
  role_arn                  = aws_iam_role.eks_capability_argocd.arn
  delete_propagation_policy = "RETAIN"

  configuration {
    argo_cd {
      aws_idc {
        idc_instance_arn = local.sso_instance_arn
      }
      namespace = "argocd"
      
      rbac_role_mapping {
        identity {
          id   = "ArgocdAdmins"  # Cognito group name
          type = "SSO_GROUP"
        }
        role = "ADMIN"
      }
    }
  }

  depends_on = [
    terraform_data.validate_sso,
    aws_cognito_user_pool.workshop
  ]

  tags = local.tags
}

