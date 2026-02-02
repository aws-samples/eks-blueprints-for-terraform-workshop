data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_session_context" "current" {
  # This data source provides information on the IAM source role of an STS assumed role
  # For non-role ARNs, this data source simply passes the ARN through issuer ARN
  # Ref https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2327#issuecomment-1355581682
  # Ref https://github.com/hashicorp/terraform-provider-aws/issues/28381
  arn = data.aws_caller_identity.current.arn
}

# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     # This requires the awscli to be installed locally where Terraform is executed
#     args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
#   }
# }

locals{
  context_prefix   = var.project_context_prefix
  name            = "argocd-spoke-${terraform.workspace}"
  region          = data.aws_region.current.id
  cluster_version = var.kubernetes_version
  enable_irsa = var.enable_irsa

  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_ids["${terraform.workspace}"]
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets["${terraform.workspace}"]

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

  name                   = local.name
  kubernetes_version     = local.cluster_version
  endpoint_public_access = true

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
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", local.region]
    }
  }
}

locals{
  argocd_namespace = "argocd"
  environment = terraform.workspace
}

# data "aws_secretsmanager_secret" "git_data_addons" {
#   name = var.secret_name_git_data_addons
# }
# data "aws_secretsmanager_secret_version" "git_data_version_addons" {
#   secret_id = data.aws_secretsmanager_secret.git_data_addons.id
# }
# data "aws_secretsmanager_secret" "git_data_platform" {
#   name = var.secret_name_git_data_platform
# }
# data "aws_secretsmanager_secret_version" "git_data_version_platform" {
#   secret_id = data.aws_secretsmanager_secret.git_data_platform.id
# }
# data "aws_secretsmanager_secret" "git_data_workload" {
#   name = var.secret_name_git_data_workloads
# }
# data "aws_secretsmanager_secret_version" "git_data_version_workload" {
#   secret_id = data.aws_secretsmanager_secret.git_data_workload.id
# }


# locals{

#   gitops_addons_url      = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).url
#   gitops_addons_basepath = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).basepath
#   gitops_addons_path     = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).path
#   gitops_addons_revision = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).revision


#   gitops_platform_url      = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).url
#   gitops_platform_basepath = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).basepath
#   gitops_platform_path     = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).path
#   gitops_platform_revision = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).revision


#   gitops_workload_url      = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_workload.secret_string).url
#   gitops_workload_basepath = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_workload.secret_string).basepath
#   gitops_workload_path     = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_workload.secret_string).path
#   gitops_workload_revision = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_workload.secret_string).revision

#   annotations = merge(
#     #enableaddonmetadata module.eks_blueprints_addons.gitops_metadata,
#     {
#       aws_cluster_name = module.eks.cluster_name
#       aws_region = local.region
#       aws_account_id = data.aws_caller_identity.current.account_id
#       aws_vpc_id = local.vpc_id
#       aws_vpc_name = data.terraform_remote_state.vpc.outputs.vpc_names["${terraform.workspace}"]
#     },
#     {
#       #enableirsarole argocd_iam_role_arn = aws_iam_role.argocd_hub.arn
#       argocd_namespace = local.argocd_namespace
#     },
#     {
#       addons_repo_url = local.gitops_addons_url
#       addons_repo_basepath = local.gitops_addons_basepath
#       addons_repo_path = local.gitops_addons_path
#       addons_repo_revision = local.gitops_addons_revision
#     },
#     {
#       platform_repo_url = local.gitops_platform_url
#       platform_repo_basepath = local.gitops_platform_basepath
#       platform_repo_path = local.gitops_platform_path
#       platform_repo_revision = local.gitops_platform_revision
#     },
#     {
#       workload_repo_url = local.gitops_workload_url
#       workload_repo_basepath = local.gitops_workload_basepath
#       workload_repo_path = local.gitops_workload_path
#       workload_repo_revision = local.gitops_workload_revision
#     },
#     #enableeso{
#     #enableeso  external_secrets_service_account = local.external_secrets.service_account
#     #enableeso  external_secrets_namespace = local.external_secrets.namespace
#     #enableeso}    
#   )
# }


# locals{
#   addons = merge(
#     { fleet_member = "spoke" },
#     { tenant = "tenant1" },
#      local.aws_addons,
#      local.oss_addons,
#      { workload_webstore = false }  
#   )

# }


# locals{
#   aws_addons = {
#     enable_cert_manager                          = try(var.addons.enable_cert_manager, false)
#     enable_aws_efs_csi_driver                    = try(var.addons.enable_aws_efs_csi_driver, false)
#     enable_aws_fsx_csi_driver                    = try(var.addons.enable_aws_fsx_csi_driver, false)
#     enable_aws_cloudwatch_metrics                = try(var.addons.enable_aws_cloudwatch_metrics, false)
#     enable_aws_privateca_issuer                  = try(var.addons.enable_aws_privateca_issuer, false)
#     enable_cluster_autoscaler                    = try(var.addons.enable_cluster_autoscaler, false)
#     enable_external_dns                          = try(var.addons.enable_external_dns, false)
#     enable_external_secrets                      = try(var.addons.enable_external_secrets, false)
#     enable_aws_load_balancer_controller          = try(var.addons.enable_aws_load_balancer_controller, false)
#     enable_fargate_fluentbit                     = try(var.addons.enable_fargate_fluentbit, false)
#     enable_aws_for_fluentbit                     = try(var.addons.enable_aws_for_fluentbit, false)
#     enable_aws_node_termination_handler          = try(var.addons.enable_aws_node_termination_handler, false)
#     enable_karpenter                             = try(var.addons.enable_karpenter, false)
#     enable_velero                                = try(var.addons.enable_velero, false)
#     enable_aws_gateway_api_controller            = try(var.addons.enable_aws_gateway_api_controller, false)
#     enable_aws_ebs_csi_resources                 = try(var.addons.enable_aws_ebs_csi_resources, false)
#     enable_aws_secrets_store_csi_driver_provider = try(var.addons.enable_aws_secrets_store_csi_driver_provider, false)
#     enable_ack_apigatewayv2                      = try(var.addons.enable_ack_apigatewayv2, false)
#     enable_ack_dynamodb                          = try(var.addons.enable_ack_dynamodb, false)
#     enable_ack_s3                                = try(var.addons.enable_ack_s3, false)
#     enable_ack_rds                               = try(var.addons.enable_ack_rds, false)
#     enable_ack_prometheusservice                 = try(var.addons.enable_ack_prometheusservice, false)
#     enable_ack_emrcontainers                     = try(var.addons.enable_ack_emrcontainers, false)
#     enable_ack_sfn                               = try(var.addons.enable_ack_sfn, false)
#     enable_ack_eventbridge                       = try(var.addons.enable_ack_eventbridge, false)
#     enable_aws_argocd                            = try(var.addons.enable_aws_argocd , false)
#     enable_cw_prometheus                         = try(var.addons.enable_cw_prometheus, false)
#     enable_cni_metrics_helper                    = try(var.addons.enable_cni_metrics_helper, false)
#   }
#   oss_addons = {
#     enable_argocd                          = try(var.addons.enable_argocd, false)
#     enable_argo_rollouts                   = try(var.addons.enable_argo_rollouts, false)
#     enable_argo_events                     = try(var.addons.enable_argo_events, false)
#     enable_argo_workflows                  = try(var.addons.enable_argo_workflows, false)
#     enable_cluster_proportional_autoscaler = try(var.addons.enable_cluster_proportional_autoscaler, false)
#     enable_gatekeeper                      = try(var.addons.enable_gatekeeper, false)
#     enable_gpu_operator                    = try(var.addons.enable_gpu_operator, false)
#     enable_ingress_nginx                   = try(var.addons.enable_ingress_nginx, false)
#     enable_keda                            = try(var.addons.enable_keda, false)
#     enable_kyverno                         = try(var.addons.enable_kyverno, false)
#     enable_kyverno_policy_reporter         = try(var.addons.enable_kyverno_policy_reporter, false)
#     enable_kyverno_policies                = try(var.addons.enable_kyverno_policies, false)
#     enable_kube_prometheus_stack           = try(var.addons.enable_kube_prometheus_stack, false)
#     enable_metrics_server                  = try(var.addons.enable_metrics_server, false)
#     enable_prometheus_adapter              = try(var.addons.enable_prometheus_adapter, false)
#     enable_secrets_store_csi_driver        = try(var.addons.enable_secrets_store_csi_driver, false)
#     enable_vpa                             = try(var.addons.enable_vpa, false)
#   }

# }

