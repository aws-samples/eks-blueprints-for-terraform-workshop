---
title: "Create Amazon VPC"
weight: 10
---

::video{id=CMNLqdBYSAQ}

### 1. Create Terraform project

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
mkdir -p ~/environment/vpc
cd ~/environment/vpc
:::
<!-- prettier-ignore-end -->

Let's define the Terraform and provider versions:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cat > ~/environment/vpc/versions.tf << 'EOF'
terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    random = {
      version = ">= 3"
    }
  }
}
EOF
:::
<!-- prettier-ignore-end -->

### 2. Define variables

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cat > ~/environment/vpc/variables.tf << 'EOF'
variable "environment_name" {
  description = "The name of environment Infrastructure stack, feel free to rename it. Used for cluster and VPC names."
  type        = string
  default     = "eks-blueprints-workshop"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

EOF
:::
<!-- prettier-ignore-start -->

### 3. Configure VPC

Now we will set up our Amazon VPC with public and private subnets spanning three Availability Zones. The following Terraform code provisions our foundational VPC infrastructure, including an Internet Gateway, NAT Gateway, and required network resources. The subnets are tagged specifically to enable dynamic discovery by the Kubernetes load balancer controller. This VPC will serve as the network foundation for deploying and running our Kubernetes clusters.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cat > ~/environment/vpc/main.tf <<'EOF'

data "aws_availability_zones" "available" {
  # Do not include local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
data "aws_region" "current" {}

locals {
  name   = var.environment_name
  region = data.aws_region.current.id

  vpc_cidr       = var.vpc_cidr
  num_of_subnets = min(length(data.aws_availability_zones.available.names), 3)
  azs            = slice(data.aws_availability_zones.available.names, 0, local.num_of_subnets)

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 6, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 6, k + 10)]

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  single_nat_gateway   = true

  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${local.name}-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${local.name}-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.name}-default" }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags

}

EOF
:::
<!-- prettier-ignore-start -->

### 4. Define outputs

We'll define VPC and private subnet outputs that will be used when creating EKS Clusters:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cat > ~/environment/vpc/outputs.tf <<'EOF'
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "vpc_name" {
  description = "The ID of the VPC"
  value       = local.name
}


EOF
:::
<!-- prettier-ignore-end -->

### 5. Provision VPC

First, let's initialize Terraform to get the required modules and providers:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cd ~/environment/vpc
terraform init
:::
<!-- prettier-ignore-start -->

It's a good practice to perform a dry-run first:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cd ~/environment/vpc
terraform plan
<!-- prettier-ignore-end -->

If there are no errors, we can proceed with the deployment:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cd ~/environment/vpc
terraform apply -auto-approve
:::
<!-- prettier-ignore-end -->

::alert[The process of creating a Virtual Private Cloud (VPC) may require up to 5 minutes to complete.]{header="Wait for resources to create"}

Once completed, we can view the VPC in the [console](https://console.aws.amazon.com/vpc/home?#vpcs:tag:Name=eks-blueprints-workshop)

::alert[This workshop uses local Terraform state. To learn about a proper setup, take a look at https://www.terraform.io/language/state]{header="Terraform State Management"}

After some time, we should see output similar to:

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='2'}
...
module.vpc.aws_route.private_nat_gateway[0]: Creation complete after 0s [id=r-rtb-0a42c62f0538aede11080289494]

Apply complete! Resources: 23 added, 0 changed, 0 destroyed.

Outputs:

private_subnets = [
  "subnet-02f11317d12ebc4c0",
  "subnet-0be1b9e9832fb1e3d",
  "subnet-05da55f463254176f",
]
vpc_id = "vpc-056a18d25ca30e155"
vpc_name = "eks-blueprints-workshop"
:::
<!-- prettier-ignore-end -->
