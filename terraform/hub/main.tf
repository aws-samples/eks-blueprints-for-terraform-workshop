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
# Identity Center Users and Groups
################################################################################

# Create ArgoCD Admins Group in Identity Center
resource "aws_identitystore_group" "argocd_admins" {
  identity_store_id = local.sso_identity_store_id
  display_name      = "ArgocdAdmins"
  description       = "ArgoCD administrators group"

  depends_on = [terraform_data.validate_sso]
}

# Create ArgoCD Admin User in Identity Center
resource "aws_identitystore_user" "argocd_admin" {
  identity_store_id = local.sso_identity_store_id
  
  display_name = "ArgoCD Admin"
  user_name    = "argoadmin"
  
  name {
    given_name  = "ArgoCD"
    family_name = "Admin"
  }
  depends_on = [terraform_data.validate_sso]
}
# Add user to group
resource "aws_identitystore_group_membership" "argocd_admin_membership" {
  identity_store_id = local.sso_identity_store_id
  group_id          = aws_identitystore_group.argocd_admins.group_id
  member_id         = aws_identitystore_user.argocd_admin.user_id
}
####### TeamLead #######
resource "aws_identitystore_group" "retail_teamleads" {
  identity_store_id = local.sso_identity_store_id
  display_name      = "RetailStoreTeamLeads"
  description       = "Retail-Store TeamLeads group"

  depends_on = [terraform_data.validate_sso]
}

resource "aws_identitystore_user" "retail_teamlead" {
  identity_store_id = local.sso_identity_store_id
  
  display_name = "Retail Teamlead"
  user_name    = "retailteamlead"
  
  name {
    given_name  = "Team"
    family_name = "Lead"
  }
  depends_on = [terraform_data.validate_sso]
}
# Add user to group
resource "aws_identitystore_group_membership" "argocd_retail_store_lead_membership" {
  identity_store_id = local.sso_identity_store_id
  group_id          = aws_identitystore_group.retail_teamleads.group_id
  member_id         = aws_identitystore_user.retail_teamlead.user_id
}

####### Developer #######
resource "aws_identitystore_group" "retail_developers" {
  identity_store_id = local.sso_identity_store_id
  display_name      = "RetailStoreDevelopers"
  description       = "Retail-Store Developers group"

  depends_on = [terraform_data.validate_sso]
}

resource "aws_identitystore_user" "retail_developer" {
  identity_store_id = local.sso_identity_store_id
  
  display_name = "Retail Developer"
  user_name    = "retaildev"
  
  name {
    given_name  = "Dev"
    family_name = "Dev"
  }
  depends_on = [terraform_data.validate_sso]
}
# Add user to group
resource "aws_identitystore_group_membership" "argocd_retail_store_dev_membership" {
  identity_store_id = local.sso_identity_store_id
  group_id          = aws_identitystore_group.retail_developers.group_id
  member_id         = aws_identitystore_user.retail_developer.user_id
}

####### DevOps #######
resource "aws_identitystore_group" "retail_devops" {
  identity_store_id = local.sso_identity_store_id
  display_name      = "RetailStoreDevOps"
  description       = "Retail-Store DevOps group"

  depends_on = [terraform_data.validate_sso]
}

resource "aws_identitystore_user" "retail_devops" {
  identity_store_id = local.sso_identity_store_id
  
  display_name = "Retail DevOps"
  user_name    = "retaildevops"
  
  name {
    given_name  = "DevOps"
    family_name = "DevOps"
  }
  depends_on = [terraform_data.validate_sso]
}
# Add user to group
resource "aws_identitystore_group_membership" "argocd_retail_store_devops_membership" {
  identity_store_id = local.sso_identity_store_id
  group_id          = aws_identitystore_group.retail_devops.group_id
  member_id         = aws_identitystore_user.retail_devops.user_id
}


####### Prod Support #######
resource "aws_identitystore_group" "retail_prod_support" {
  identity_store_id = local.sso_identity_store_id
  display_name      = "RetailStoreProdSupport"
  description       = "Retail-Store Prod Support group"

  depends_on = [terraform_data.validate_sso]
}

resource "aws_identitystore_user" "retail_prod_support" {
  identity_store_id = local.sso_identity_store_id
  
  display_name = "Retail Prod Support"
  user_name    = "retailprodsupport"
  
  name {
    given_name  = "Retail Prod Support"
    family_name = "Retail Prod Support"
  }
  depends_on = [terraform_data.validate_sso]
}
# Add user to group
resource "aws_identitystore_group_membership" "argocd_retail_store_prod_support_membership" {
  identity_store_id = local.sso_identity_store_id
  group_id          = aws_identitystore_group.retail_prod_support.group_id
  member_id         = aws_identitystore_user.retail_prod_support.user_id
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
          id   = aws_identitystore_group.argocd_admins.group_id
          type = "SSO_GROUP"
        }
        role = "ADMIN"
      }
    }
  }

  depends_on = [
    terraform_data.validate_sso,
    aws_identitystore_group.argocd_admins,
    aws_identitystore_user.argocd_admin
  ]

  tags = local.tags
}

resource "aws_eks_access_policy_association" "AmazonEKSClusterAdminPolicy" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.eks_capability_argocd.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  
  access_scope {
    type      = "cluster"
  }
}

resource "null_resource" "disable_assignment_requirement" {
  depends_on = [aws_eks_capability.argocd]
  
  provisioner "local-exec" {
    command = <<-EOT
      APP_ARN=$(aws sso-admin list-applications --instance-arn ${data.aws_ssoadmin_instances.main.arns[0]} --query 'Applications[?contains(Name, `ArgoCD`)].ApplicationArn' --output text)
      aws sso-admin put-application-assignment-configuration --application-arn $APP_ARN --no-assignment-required
    EOT
  }
}

###################
# Codecommit repos
#################

resource "aws_codecommit_repository" "platform" {
  repository_name = "platform"
  description     = "Platform GitOps repository for Platform team"

  tags = local.tags
}

resource "aws_codecommit_repository" "retail_store_app" {
  repository_name = "retail-store-app"
  description     = "Retail store application code repository"

  tags = local.tags
}

resource "aws_codecommit_repository" "retail_store_config" {
  repository_name = "retail-store-config"
  description     = "Retail store configuration repository"

  tags = local.tags
}

################################################################################
# GitLab EC2 + NLB + CodeConnections
# Append this to terraform/hub/main.tf
#
# PREREQUISITE 1: Add public_subnets output to terraform/vpc/outputs.tf:
#
#   output "public_subnets" {
#     description = "Map of public subnet IDs"
#     value = {
#       for k, v in module.vpc : k => v.public_subnets
#     }
#   }
#
# PREREQUISITE 2: Add tls provider to terraform/hub/versions.tf:
#
#   tls = {
#     source  = "hashicorp/tls"
#     version = ">= 4.0"
#   }
################################################################################

################################################################################
# ENI with known private IP (so cert can include IP SAN before instance exists)
################################################################################
resource "aws_network_interface" "gitlab" {
  subnet_id       = local.private_subnets[0]
  security_groups = [aws_security_group.gitlab.id]
  tags = merge(local.tags, { Name = "${local.context_prefix}-gitlab" })
}

################################################################################
# Self-Signed TLS Certificate (used by GitLab and CodeConnections)
################################################################################
resource "tls_private_key" "gitlab" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "gitlab" {
  private_key_pem = tls_private_key.gitlab.private_key_pem

  subject {
    common_name = "gitlab.internal"
  }

  dns_names = [
    "gitlab.internal",
  ]

  ip_addresses = [
    aws_network_interface.gitlab.private_ip,
  ]

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

################################################################################
# GitLab Security Group
################################################################################
resource "aws_security_group" "gitlab" {
  name_prefix = "gitlab-"
  vpc_id      = local.vpc_id
  description = "Security group for GitLab EC2 instance"

  ingress {
    description = "HTTPS from anywhere (via NLB)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

################################################################################
# NLB (Internet-facing)
################################################################################
resource "aws_lb" "gitlab" {
  name               = "gitlab-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = data.terraform_remote_state.vpc.outputs.public_subnets["hub"]

  tags = local.tags
}

resource "aws_lb_target_group" "gitlab" {
  name        = "gitlab-tg"
  port        = 443
  protocol    = "TCP"
  vpc_id      = local.vpc_id
  target_type = "instance"

  health_check {
    protocol            = "TCP"
    port                = 443
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = local.tags
}

resource "aws_lb_listener" "gitlab" {
  load_balancer_arn = aws_lb.gitlab.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gitlab.arn
  }
}

resource "aws_lb_target_group_attachment" "gitlab" {
  target_group_arn = aws_lb_target_group.gitlab.arn
  target_id        = aws_instance.gitlab.id
  port             = 443
}

################################################################################
# IAM Role for GitLab EC2
################################################################################
resource "aws_iam_role" "gitlab" {
  name_prefix = "gitlab-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "gitlab_ssm" {
  role       = aws_iam_role.gitlab.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "gitlab" {
  name_prefix = "gitlab-"
  role        = aws_iam_role.gitlab.name
}

################################################################################
# GitLab EC2 Instance
################################################################################
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "gitlab" {
  ami                  = data.aws_ami.al2023.id
  instance_type        = "t2.large"
  iam_instance_profile = aws_iam_instance_profile.gitlab.name

  network_interface {
    network_interface_id = aws_network_interface.gitlab.id
    device_index         = 0
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/gitlab-userdata.sh", {
    nlb_dns_name = aws_lb.gitlab.dns_name
    tls_cert     = tls_self_signed_cert.gitlab.cert_pem
    tls_key      = tls_private_key.gitlab.private_key_pem
  }))

  tags = merge(local.tags, {
    Name = "${local.context_prefix}-gitlab"
  })
}



################################################################################
# CodeConnections - Host + Connection for GitLab
################################################################################
resource "aws_security_group" "codeconnections" {
  name_prefix = "codeconnections-"
  vpc_id      = local.vpc_id
  description = "Security group for CodeConnections Host ENIs"

  egress {
    description = "HTTPS to GitLab"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.gitlab.id]
  }

  tags = local.tags
}

# Allow GitLab to accept traffic from CodeConnections ENIs
resource "aws_security_group_rule" "gitlab_from_codeconnections" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.codeconnections.id
  security_group_id        = aws_security_group.gitlab.id
  description              = "HTTPS from CodeConnections"
}

resource "aws_codestarconnections_host" "gitlab" {
  name              = "gitlab-host"
  provider_endpoint = "https://${aws_network_interface.gitlab.private_ip}"
  provider_type     = "GitLabSelfManaged"

  vpc_configuration {
    vpc_id             = local.vpc_id
    subnet_ids         = local.private_subnets
    security_group_ids = [aws_security_group.codeconnections.id]
    tls_certificate    = tls_self_signed_cert.gitlab.cert_pem
  }
}


