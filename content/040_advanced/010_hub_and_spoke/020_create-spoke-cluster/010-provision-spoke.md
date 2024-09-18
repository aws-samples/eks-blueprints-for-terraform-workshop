---
title: 'Create Spoke Staging Cluster'
weight: 10
---

### 1. Remote state
The spoke-staging cluster references outputs from the vpc and hub modules.

```bash
mkdir -p ~/environment/spoke
cd ~/environment/spoke
cat > ~/environment/spoke/remote_state.tf << 'EOF'
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "${path.module}/../vpc/terraform.tfstate"
  }
}
data "terraform_remote_state" "hub" {
  backend = "local"

  config = {
    path = "${path.module}/../hub/terraform.tfstate"
  }
}

EOF
```
### 2. Configure EKS Spoke cluster

It configures the EKS cluster, sets up label and annotation values, and uses the Terraform blueprint addons module to create IAM roles.

```bash
cat > ~/environment/spoke/main.tf << 'EOF'
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
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

locals {
  name            = "spoke-${terraform.workspace}"
  environment     = terraform.workspace
  region          = data.aws_region.current.id
  cluster_version = var.kubernetes_version
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id 
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets 
  authentication_mode = var.authentication_mode
  
  

  gitops_addons_url      = data.terraform_remote_state.hub.outputs.gitops_addons_url
  gitops_addons_basepath = data.terraform_remote_state.hub.outputs.gitops_addons_basepath
  gitops_addons_path     = data.terraform_remote_state.hub.outputs.gitops_addons_path
  gitops_addons_revision = data.terraform_remote_state.hub.outputs.gitops_addons_revision

  gitops_platform_url      = data.terraform_remote_state.hub.outputs.gitops_platform_url
  gitops_platform_basepath = data.terraform_remote_state.hub.outputs.gitops_platform_basepath
  gitops_platform_path     = data.terraform_remote_state.hub.outputs.gitops_platform_path
  gitops_platform_revision = data.terraform_remote_state.hub.outputs.gitops_platform_revision

  gitops_workload_url      = data.terraform_remote_state.hub.outputs.gitops_workload_url
  gitops_workload_basepath = data.terraform_remote_state.hub.outputs.gitops_workload_basepath
  gitops_workload_path     = data.terraform_remote_state.hub.outputs.gitops_workload_path
  gitops_workload_revision = data.terraform_remote_state.hub.outputs.gitops_workload_revision

  aws_addons = {
    enable_cert_manager                          = try(var.addons.enable_cert_manager, false)
    enable_aws_efs_csi_driver                    = try(var.addons.enable_aws_efs_csi_driver, false)
    enable_aws_fsx_csi_driver                    = try(var.addons.enable_aws_fsx_csi_driver, false)
    enable_aws_cloudwatch_metrics                = try(var.addons.enable_aws_cloudwatch_metrics, false)
    enable_aws_privateca_issuer                  = try(var.addons.enable_aws_privateca_issuer, false)
    enable_cluster_autoscaler                    = try(var.addons.enable_cluster_autoscaler, false)
    enable_external_dns                          = try(var.addons.enable_external_dns, false)
    enable_external_secrets                      = try(var.addons.enable_external_secrets, false)
    enable_aws_load_balancer_controller          = try(var.addons.enable_aws_load_balancer_controller, false)
    enable_fargate_fluentbit                     = try(var.addons.enable_fargate_fluentbit, false)
    enable_aws_for_fluentbit                     = try(var.addons.enable_aws_for_fluentbit, false)
    enable_aws_node_termination_handler          = try(var.addons.enable_aws_node_termination_handler, false)
    enable_karpenter                             = try(var.addons.enable_karpenter, false)
    enable_velero                                = try(var.addons.enable_velero, false)
    enable_aws_gateway_api_controller            = try(var.addons.enable_aws_gateway_api_controller, false)
    enable_aws_ebs_csi_resources                 = try(var.addons.enable_aws_ebs_csi_resources, false)
    enable_aws_secrets_store_csi_driver_provider = try(var.addons.enable_aws_secrets_store_csi_driver_provider, false)
    enable_ack_apigatewayv2                      = try(var.addons.enable_ack_apigatewayv2, false)
    enable_ack_dynamodb                          = try(var.addons.enable_ack_dynamodb, false)
    enable_ack_s3                                = try(var.addons.enable_ack_s3, false)
    enable_ack_rds                               = try(var.addons.enable_ack_rds, false)
    enable_ack_prometheusservice                 = try(var.addons.enable_ack_prometheusservice, false)
    enable_ack_emrcontainers                     = try(var.addons.enable_ack_emrcontainers, false)
    enable_ack_sfn                               = try(var.addons.enable_ack_sfn, false)
    enable_ack_eventbridge                       = try(var.addons.enable_ack_eventbridge, false)
  }
  oss_addons = {
    enable_argocd                          = try(var.addons.enable_argocd, false)
    enable_argo_rollouts                   = try(var.addons.enable_argo_rollouts, false)
    enable_argo_events                     = try(var.addons.enable_argo_events, false)
    enable_argo_workflows                  = try(var.addons.enable_argo_workflows, false)
    enable_cluster_proportional_autoscaler = try(var.addons.enable_cluster_proportional_autoscaler, false)
    enable_gatekeeper                      = try(var.addons.enable_gatekeeper, false)
    enable_gpu_operator                    = try(var.addons.enable_gpu_operator, false)
    enable_ingress_nginx                   = try(var.addons.enable_ingress_nginx, false)
    enable_kyverno                         = try(var.addons.enable_kyverno, false)
    enable_kube_prometheus_stack           = try(var.addons.enable_kube_prometheus_stack, false)
    enable_metrics_server                  = try(var.addons.enable_metrics_server, false)
    enable_prometheus_adapter              = try(var.addons.enable_prometheus_adapter, false)
    enable_secrets_store_csi_driver        = try(var.addons.enable_secrets_store_csi_driver, false)
    enable_vpa                             = try(var.addons.enable_vpa, false)
  }
  addons = merge(
    local.aws_addons,
    local.oss_addons,
    { kubernetes_version = local.cluster_version },
    { aws_cluster_name = module.eks.cluster_name },
    { workloads = false },
    { workload_webstore = false }      
  )

  addons_metadata = merge(
    module.eks_blueprints_addons.gitops_metadata,
    {
      aws_cluster_name = module.eks.cluster_name
      aws_region       = local.region
      aws_account_id   = data.aws_caller_identity.current.account_id
      aws_vpc_id       = local.vpc_id
    },
    {
      addons_repo_url      = local.gitops_addons_url
      addons_repo_basepath = local.gitops_addons_basepath
      addons_repo_path     = local.gitops_addons_path
      addons_repo_revision = local.gitops_addons_revision
    },
    {
      platform_repo_url      = local.gitops_platform_url
      platform_repo_basepath = local.gitops_platform_basepath
      platform_repo_path     = local.gitops_platform_path
      platform_repo_revision = local.gitops_platform_revision
    },
    {
      workload_repo_url      = local.gitops_workload_url
      workload_repo_basepath = local.gitops_workload_basepath
      workload_repo_path     = local.gitops_workload_path
      workload_repo_revision = local.gitops_workload_revision
    }
  
  )


  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-samples/eks-blueprints-for-terraform-workshop"
  }
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Using GitOps Bridge
  create_kubernetes_resources = false

  # EKS Blueprints Addons
  enable_cert_manager                 = try(local.aws_addons.enable_cert_manager, false)
  enable_aws_efs_csi_driver           = try(local.aws_addons.enable_aws_efs_csi_driver, false)
  enable_aws_fsx_csi_driver           = try(local.aws_addons.enable_aws_fsx_csi_driver, false)
  enable_aws_cloudwatch_metrics       = try(local.aws_addons.enable_aws_cloudwatch_metrics, false)
  enable_aws_privateca_issuer         = try(local.aws_addons.enable_aws_privateca_issuer, false)
  enable_cluster_autoscaler           = try(local.aws_addons.enable_cluster_autoscaler, false)
  enable_external_dns                 = try(local.aws_addons.enable_external_dns, false)
  enable_external_secrets             = try(local.aws_addons.enable_external_secrets, false)
  enable_aws_load_balancer_controller = try(local.aws_addons.enable_aws_load_balancer_controller, false)
  enable_fargate_fluentbit            = try(local.aws_addons.enable_fargate_fluentbit, false)
  enable_aws_for_fluentbit            = try(local.aws_addons.enable_aws_for_fluentbit, false)
  enable_aws_node_termination_handler = try(local.aws_addons.enable_aws_node_termination_handler, false)
  enable_karpenter                    = try(local.aws_addons.enable_karpenter, false)
  enable_velero                       = try(local.aws_addons.enable_velero, false)
  enable_aws_gateway_api_controller   = try(local.aws_addons.enable_aws_gateway_api_controller, false)

  tags = local.tags
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
  version = "~> 20.8"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  authentication_mode = local.authentication_mode

  # Combine root account, current user/role and additinoal roles to be able to access the cluster KMS key - required for terraform updates
  kms_key_administrators = distinct(concat([
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"],
    [data.aws_iam_session_context.current.issuer_arn]
  ))
  
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    # One access entry with a policy associated
    workshop_attendee = {
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
    
    #enablespokearn gitops_role = {
    #enablespokearn   principal_arn     = aws_iam_role.spoke.arn
    #enablespokearn   policy_associations = {
    #enablespokearn     argocd = {
    #enablespokearn       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    #enablespokearn       access_scope = {
    #enablespokearn         type       = "cluster"
    #enablespokearn       }
    #enablespokearn     }
    #enablespokearn   }
    #enablespokearn }    
  } 

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.medium"]

      min_size     = 3
      max_size     = 10
      desired_size = 3
    }
  }
  # EKS Addons
  cluster_addons = {
    eks-pod-identity-agent = {
      most_recent = true
    }    
    vpc-cni = {
      # Specify the VPC CNI addon should be deployed before compute to ensure
      # the addon is configured before data plane compute resources are created
      # See README for further details
      before_compute = true
      most_recent    = true # To ensure access to the latest settings provided
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }
  tags = local.tags
}


EOF
```
### 3. Define variables
```bash
cat > ~/environment/spoke/variables.tf << 'EOF'
variable "kubernetes_version" {
  description = "EKS version"
  type        = string
  default     = "1.28"
}

variable "eks_admin_role_name" {
  description = "EKS admin role"
  type        = string
  default     = "WSParticipantRole"
}

variable "addons" {
  description = "EKS addons"
  type        = any
  default = {
    enable_aws_load_balancer_controller = false
  }
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are CONFIG_MAP, API or API_AND_CONFIG_MAP"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

EOF
```
### 4. Define outputs

```bash
cat > ~/environment/spoke/outputs.tf << 'EOF'

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = <<-EOT
    aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name} --alias ${module.eks.cluster_name}
  EOT
}
EOF
```

### 5. Copy variable values file to the cluster

We copy and reset the addons, so that we enable when required

```bash
cp ~/environment/terraform.tfvars ~/environment/spoke/terraform.tfvars
sed -i 's/enable_aws_load_balancer_controller = true/enable_aws_load_balancer_controller = false/; s/enable_aws_argocd = true/enable_aws_argocd = false/' ~/environment/spoke/terraform.tfvars
```

### 6. Create terraform workspace

Create new staging workspace

```bash
cd ~/environment/spoke
terraform workspace new staging
```

### 7. Apply Terraform

```bash
cd ~/environment/spoke
terraform init
terraform apply --auto-approve
```
***It takes around 15 minutes to create the cluster***

### 8. Access Spoke Staging Cluster

To configure kubectl, execute the following:

```bash
eval $(terraform output -raw configure_kubectl)
```

Run the command below to see the nodes in the hub cluster.

```bash
kubectl get nodes --context spoke-staging
```

Navigate to the AWS Console, go to EKS, then select Clusters to see the spoke-staging cluster.