---
title: 'Configure our eks-blueprint local module'
weight: 1
---

::alert[We heavily rely on Terraform modules in the workshop; you can read more about them [here](https://www.terraform.io/language/modules)]{header="Important"}

Similarly to what we did in the environment setup, let's create our needed Terraform files.


### 1. Create our Terraform project

```bash
cat > ~/environment/eks-blueprint/modules/eks_cluster/versions.tf << 'EOF'
terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}
EOF
```

### 2. Define our module's variables

Here we define a lot of variables that will be used by the solution.
Let's define some of them:
- environment _name refer to the environment we previously created.
- service_name will refer to instances of our module (our EKS cluster names).
- eks_admin_role_name is an additional IAM role that will be admin in the cluster.
<!--- **workload_*** are variables that will configure our GitOps cluster configuration, we will talk about it later.-->

```bash
cat > ~/environment/eks-blueprint/modules/eks_cluster/variables.tf << 'EOF'
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}
variable "environment_name" {
  description = "The name of Environment Infrastructure stack, feel free to rename it. Used for cluster and VPC names."
  type        = string
  default     = "eks-blueprint"
}

variable "service_name" {
  description = "The name of the Suffix for the stack name"
  type        = string
  default     = "blue"
}

variable "cluster_version" {
  description = "The Version of Kubernetes to deploy"
  type        = string
  default     = "1.25"
}

variable "eks_admin_role_name" {
  type        = string
  description = "Additional IAM role to be admin in the cluster"
  default     = ""
}

variable "argocd_secret_manager_name_suffix" {
  type        = string
  description = "Name of secret manager secret for ArgoCD Admin UI Password"
  default     = "argocd-admin-secret"
}


EOF
```

### 3. Create a locals.tf file

We start by defining some locals:

```bash
cat <<'EOF' > ~/environment/eks-blueprint/modules/eks_cluster/locals.tf
locals {
  environment = var.environment_name
  service     = var.service_name

  env  = local.environment
  name = "${local.environment}-${local.service}"

  # Mapping
  cluster_version            = var.cluster_version
  argocd_secret_manager_name = var.argocd_secret_manager_name_suffix
  eks_admin_role_name        = var.eks_admin_role_name

  tag_val_vpc            = local.environment
  tag_val_public_subnet  = "${local.environment}-public-"
  tag_val_private_subnet = "${local.environment}-private-"

  node_group_name = "managed-ondemand"

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }

}

EOF
```


### 3. Create our main.tf module file

```bash
cat <<'EOF' > ~/environment/eks-blueprint/modules/eks_cluster/main.tf
# Required for public ECR where Karpenter artifacts are hosted
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

EOF
```

Now we continue by importing some data:

- Our existing partition.
- Our AWS identity.
- The VPC we created in our environment.
- The private subnets of our VPC.

```bash
cat <<'EOF' >> ~/environment/eks-blueprint/modules/eks_cluster/main.tf
data "aws_partition" "current" {}

# Find the user currently in use by AWS
data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [local.tag_val_vpc]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["${local.tag_val_private_subnet}*"]
  }
}


EOF
```

Now we tag the subnets with the name of our EKS cluster, which is the concatenation of the two locals: `local.environment` and `local.service`, This will be used by our Load Balancer or Karpenter to know in which subnet our cluster is.

```bash
cat <<'EOF' >> ~/environment/eks-blueprint/modules/eks_cluster/main.tf
#Add Tags for the new cluster in the VPC Subnets
resource "aws_ec2_tag" "private_subnets" {
  for_each    = toset(data.aws_subnets.private.ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.environment}-${local.service}"
  value       = "shared"
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Name"
    values = ["${local.tag_val_public_subnet}*"]
  }
}

#Add Tags for the new cluster in the VPC Subnets
resource "aws_ec2_tag" "public_subnets" {
  for_each    = toset(data.aws_subnets.public.ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.environment}-${local.service}"
  value       = "shared"
}
EOF
```

Finally, we import our secrets for ArgoCD from AWS Secret Manager:

```bash
cat <<'EOF' >> ~/environment/eks-blueprint/modules/eks_cluster/main.tf
data "aws_secretsmanager_secret" "argocd" {
  name = "${local.argocd_secret_manager_name}.${local.environment}"
}

data "aws_secretsmanager_secret_version" "admin_password_version" {
  secret_id = data.aws_secretsmanager_secret.argocd.id
}
EOF
```

### 4. Create the EKS cluster


In this step, we are going to add the EKS  core module and configure it, including the EKS managed node group. From the code below, you can see that we are pinning the main **terraform-aws-modules/eks** to version [19.15.1](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) which corresponds to the GitHub repository release tag. It is a good practice to lock-in all your modules to a given, tried-and-tested version.

<!--Please **add the following** (copy/paste) at the top of your `main.tf` right above the "vpc" module definition.

-->

```bash
cat <<'EOF' >> ~/environment/eks-blueprint/modules/eks_cluster/main.tf
#tfsec:ignore:aws-eks-enable-control-plane-logging
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15.2"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = data.aws_vpc.vpc.id
  subnet_ids = data.aws_subnets.private.ids

  #we uses only 1 security group to allow connection with Fargate, MNG, and Karpenter nodes
  create_node_security_group = false
  eks_managed_node_groups = {
    initial = {
      node_group_name = local.node_group_name
      instance_types  = ["m5.large"]

      min_size     = 1
      max_size     = 5
      desired_size = 3
      subnet_ids   = data.aws_subnets.private.ids
    }
  }

  manage_aws_auth_configmap = true
  aws_auth_roles = flatten([
    #module.eks_blueprints_platform_teams.aws_auth_configmap_role,
    #[for team in module.eks_blueprints_dev_teams : team.aws_auth_configmap_role],
    #{
    #  rolearn  = module.karpenter.role_arn
    #  username = "system:node:{{EC2PrivateDNSName}}"
    #  groups = [
    #    "system:bootstrappers",
    #    "system:nodes",
    #  ]
    #},
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.eks_admin_role_name}" # The ARN of the IAM role
      username = "ops-role"                                                                                      # The user name within Kubernetes to map to the IAM role
      groups   = ["system:masters"]                                                                              # A list of groups within Kubernetes to which the role is mapped; Checkout K8s Role and Rolebindings
    }
  ])

  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = "${local.environment}-${local.service}"
  })
}

EOF
```

> Keep the commented parts for now
> 
<!--

Our EKS cluster will rely on [Karpenter](karpenter.sh) for cluster autoscaling. for this we also rely on the [terraform-aws-modules/eks/aws/latest/submodules/karpenter](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest/submodules/karpenter) submodule

```bash
cat <<'EOF' >> ~/environment/eks-blueprint/modules/eks_cluster/main.tf

################################################################################
# Karpenter
################################################################################

# Creates Karpenter native node termination handler resources and IAM instance profile
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 19.15.1"

  cluster_name           = module.eks.cluster_name
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn
  create_irsa            = false # IRSA will be created by the kubernetes-addons module

  tags = local.tags
}

EOF
```
-->

<!--
Now we will add our first Admin team using the [eks-blueprints-teams](https://github.com/aws-ia/terraform-aws-eks-blueprints-teams) module

```bash
cat <<'EOF' >> ~/environment/eks-blueprint/modules/eks_cluster/main.tf
module "eks_blueprints_admin_team" {
  source  = "aws-ia/eks-blueprints-teams/aws"
  version = "~> 0.2.0"

  name = "admin-team"

  enable_admin = true
  users = [
    data.aws_caller_identity.current.arn,
    "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${local.eks_admin_role_name}"
  ]
  cluster_arn = module.eks.cluster_arn

  tags = local.tags
}

EOF
```
-->

## 3. Get module outputs

We want our module to output some variables we could reuse later:
- The EKS cluster ID
- The command to configure our kubectl for the creator of the EKS cluster
  
```bash
cat <<'EOF' > ~/environment/eks-blueprint/modules/eks_cluster/outputs.tf
output "eks_cluster_id" {
  description = "The name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "eks_cluster_endpoint" {
  description = "The endpoint of the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "cluster_certificate_authority_data"
  value       = module.eks.cluster_certificate_authority_data
}

EOF
```

Ok, we have finished our local eks-blueprint module; now let's create an instance of it.