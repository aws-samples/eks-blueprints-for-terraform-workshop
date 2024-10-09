---
title: "Create Amazon VPC"
weight: 10
---

### 1. Create Terraform project

```bash
mkdir -p ~/environment/vpc
cd ~/environment/vpc
```

Define Terraform and providers versions:

```bash
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
```

### 2. Define variables

```bash
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
```

### 3. Configure VPC

The provided Terraform code sets up the foundational infrastructure for an Amazon Virtual Private Cloud (VPC) with public and private subnets spanning three Availability Zones, along with necessary networking components like an Internet Gateway, NAT Gateway, and default network resources. The public and private subnets are tagged specifically for later use with the Kubernetes load balancer controller to dynamically discover them. This VPC infrastructure serves as the foundation for deploying and running Kubernetes clusters and other resources within the VPC.

```bash
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
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = local.name
  }

  tags = local.tags

}

EOF
```

### 3. Create outputs

VPC and private subnets are used when creating EKS Clusters.

```bash
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
```

### 5. Provision VPC:

Initialize Terraform to get required modules and providers

```bash
cd ~/environment/vpc
terraform init
```

It is always a good practice to use a dry-run command

```bash
cd ~/environment/vpc
terraform plan
```

If there are no errors, you can proceed with deployment:

> The auto-approve flag avoids you having to confirm that you want to provision resources.

```bash
cd ~/environment/vpc
terraform apply -auto-approve
```

::alert[The process of creating a Virtual Private Cloud (VPC) may require up to 5 minutes to complete.]{header="Wait for resources to create"}

Once completed, you can see the VPC in the [console](https://console.aws.amazon.com/vpc/home?#vpcs:tag:Name=eks-blueprints-workshop)

::alert[This workshop uses local Terraform state. To learn about a proper setup, take a look at https://www.terraform.io/language/state]{header="Terraform State Management"}

After some times you should see output similar to:

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
