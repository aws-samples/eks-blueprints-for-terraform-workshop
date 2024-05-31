---
title: 'Create Hub Cluster'
weight: 10
---
In this chapter you will create an EKS cluster with EKS Terraform blueprint module. 

![EKS Cluster](/static/images/argocd-bootstrap-eks.png)


### 1. Create Remote State 
Get vpc and private subnet values from the vpc module.

```bash
mkdir -p ~/environment/hub
cd ~/environment/hub
cat > ~/environment/hub/remote_state.tf << 'EOF'
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "${path.module}/../vpc/terraform.tfstate"
  }
}
EOF
```
### 2. Create variables

Define EKS version for the hub-cluster. From the console, you can manage EKS objects such as pods, deployments, namespaces, etc for the hub-cluster with EKS admin role.

```bash
cat > ~/environment/hub/variables.tf << 'EOF'
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

variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are CONFIG_MAP, API or API_AND_CONFIG_MAP"
  type        = string
  default     = "API"
}

EOF
```

### 3. Configure EKS Cluster

It uses Terraform blueprint EKS module to configure the cluster in the private subnets with 3 EC2 instances. 

```bash
cat > ~/environment/hub/main.tf << 'EOF'
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
  name            = "hub-cluster"
  cluster_version = var.kubernetes_version
  region          = data.aws_region.current.id
  
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id  
  
  authentication_mode = var.authentication_mode
  
  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/csantanapr/terraform-gitops-bridge"
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
  version = "~> 20.8"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  authentication_mode = local.authentication_mode
  
  # Combine root account, current user/role and additional roles to be able to access the cluster KMS key - required for terraform updates
  kms_key_administrators = distinct(concat([
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"],
    [data.aws_iam_session_context.current.issuer_arn]

  ))
  
  enable_cluster_creator_admin_permissions = true
  access_entries = {
    # One access entry with a policy associated
    example = {
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
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.medium"]

      min_size     = 3
      max_size     = 10
      desired_size = 3
    }
  }

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

### 4. Define outputs

```bash
cat > ~/environment/hub/outputs.tf << 'EOF'

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = <<-EOT
    aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name} --alias hub
  EOT
}

output "cluster_name" {
  description = "Cluster Hub name"
  value       = module.eks.cluster_name
}
output "cluster_endpoint" {
  description = "Cluster Hub endpoint"
  value       = module.eks.cluster_endpoint
}
output "cluster_certificate_authority_data" {
  description = "Cluster Hub certificate_authority_data"
  value       = module.eks.cluster_certificate_authority_data
}
output "cluster_region" {
  description = "Cluster Hub region"
  value       = local.region
}
output "hub_node_security_group_id" {
  description = "Cluster Hub region"
  value       = module.eks.node_security_group_id
}

EOF
```

### 5. Define variable values

The EKS admin role enables access to view and manage cluster resources through the AWS console.

```bash
cat >  ~/environment/terraform.tfvars <<EOF
eks_admin_role_name          = "WSParticipantRole"

EOF
```
::alert[If you are NOT at an AWS event workshop, you may need to update this parameter with your console Role Name.]{header="Important" type="warning"}

"WSParticipantRole" is the given role name when participating in the AWS run workshop. When working through the workshop independently, you should update it to reflect your own AWS role.

You can get your role on the console,choose your user name/role on the navigation bar in the upper right. Your role is after Account Id. Your role name is anything before "/" if it exists. In the Cloud9 IDE, open the terraform.tfvars file, modify the role as needed, then ***save your changes***.

You can use the following command to edit the file in Cloud9 IDE.

```bash
c9 open ~/environment/terraform.tfvars
```

![AWS Console Role](/static/images/aws-console-role.png)


### 6. Link the Terraform variable file to the cluster

```bash
ln -s ~/environment/terraform.tfvars ~/environment/hub/terraform.tfvars
```

### 7. Create EKS cluster

```bash
cd ~/environment/hub
terraform init
terraform apply -auto-approve
```
***It takes around 15 minutes to create the cluster***

### 8. Access Hub Cluster

To configure kubectl, execute the following:

```bash
eval `terraform output -raw configure_kubectl`
```

Run the command below to see the nodes in the hub cluster.

```bash
kubectl get nodes --context hub
```