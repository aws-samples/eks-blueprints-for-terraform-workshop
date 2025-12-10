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
# SSO - Create AWS Managed Microsoft AD and integrate with Identity Center
################################################################################

# Create AWS Managed Microsoft AD
resource "aws_directory_service_directory" "main" {
  name     = "argocd.local"
  password = "TempPassword123!"
  size     = "Small"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = local.vpc_id
    subnet_ids = local.private_subnets
  }

  tags = local.tags
}

# Configure Identity Center to use the Managed AD as identity source
resource "terraform_data" "configure_ad_identity_source" {
  depends_on = [terraform_data.validate_sso, aws_directory_service_directory.main]

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for AD to be ready first
      echo "Waiting for Managed AD to be ready..."
      while true; do
        STATUS=$(aws ds describe-directories --directory-ids ${aws_directory_service_directory.main.id} --query 'DirectoryDescriptions[0].Stage' --output text --region ${local.region})
        if [ "$STATUS" = "Active" ]; then
          echo "Managed AD is ready"
          break
        fi
        echo "AD Status: $STATUS, waiting..."
        sleep 30
      done

      # Configure Identity Center to use Active Directory
      echo "Configuring Identity Center to use Active Directory..."
      aws sso-admin put-identity-source \
        --instance-arn ${local.sso_instance_arn} \
        --identity-source ActiveDirectoryIdentitySource='{DirectoryId=${aws_directory_service_directory.main.id}}' \
        --region ${local.region}
      
      echo "Identity source configured successfully"
    EOT
  }
}

# Create AD users and groups via PowerShell commands
resource "terraform_data" "create_ad_users" {
  depends_on = [aws_directory_service_directory.main]

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for AD to be ready
      echo "Waiting for Managed AD to be ready..."
      while true; do
        STATUS=$(aws ds describe-directories --directory-ids ${aws_directory_service_directory.main.id} --query 'DirectoryDescriptions[0].Stage' --output text --region ${local.region})
        if [ "$STATUS" = "Active" ]; then
          echo "Managed AD is ready"
          break
        fi
        echo "AD Status: $STATUS, waiting..."
        sleep 30
      done

      # Get AD admin credentials and endpoints
      AD_ID=${aws_directory_service_directory.main.id}
      AD_DNS=$(aws ds describe-directories --directory-ids $AD_ID --query 'DirectoryDescriptions[0].DnsIpAddrs[0]' --output text --region ${local.region})
      
      echo "AD Directory ID: $AD_ID"
      echo "AD DNS: $AD_DNS"
      echo "Use AWS Systems Manager Session Manager to connect to a domain-joined EC2 instance"
      echo "Then run PowerShell commands to create users and groups"
      echo ""
      echo "PowerShell commands to run on domain-joined instance:"
      echo "New-ADGroup -Name 'ArgocdAdmins' -GroupScope Global -GroupCategory Security"
      echo "New-ADUser -Name 'argocdadmin' -UserPrincipalName 'argocdadmin@argocd.local' -AccountPassword (ConvertTo-SecureString 'argocdonaws' -AsPlainText -Force) -Enabled \$true"
      echo "Add-ADGroupMember -Identity 'ArgocdAdmins' -Members 'argocdadmin'"
    EOT
  }
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
          id   = "ArgocdAdmins"  # AD group name
          type = "SSO_GROUP"
        }
        role = "ADMIN"
      }
    }
  }

  depends_on = [
    terraform_data.configure_ad_identity_source,
    terraform_data.create_ad_users,
    terraform_data.validate_sso
  ]

  tags = local.tags
}

