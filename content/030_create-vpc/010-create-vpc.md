---
title: 'Create VPC'
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
  default     = "eks-blueprint"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

EOF
```

### 3. Configure VPC 

Configure 3 public and 3 private subnets.

```bash
cat > ~/environment/vpc/main.tf <<'EOF'

data "aws_availability_zones" "available" {}
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


EOF
```

### 5. Provision VPC:

```bash
# Initialize Terraform to get required modules and providers
cd ~/environment/vpc
terraform init
```

<!--::::expand{header="View Terraform Output:"}-->
<!--:::code{showCopyAction=false language=hcl}-->
<!--Initializing modules...-->
<!--Downloading registry.terraform.io/terraform-aws-modules/vpc/aws 3.14.0 for vpc...-->
<!--- vpc in .terraform/modules/vpc-->

<!--Initializing the backend...-->

<!--Initializing provider plugins...-->
<!--- Finding gavinbunney/kubectl versions matching ">= 1.14.0"...-->
<!--- Finding hashicorp/aws versions matching ">= 3.63.0, >= 3.72.0"...-->
<!--- Finding hashicorp/kubernetes versions matching ">= 2.10.0"...-->
<!--- Finding hashicorp/helm versions matching ">= 2.4.1"...-->
<!--- Installing gavinbunney/kubectl v1.14.0...-->
<!--- Installed gavinbunney/kubectl v1.14.0 (self-signed, key ID AD64217B5ADD572F)-->
<!--- Installing hashicorp/aws v4.16.0...-->
<!--- Installed hashicorp/aws v4.16.0 (signed by HashiCorp)-->
<!--- Installing hashicorp/kubernetes v2.11.0...-->
<!--- Installed hashicorp/kubernetes v2.11.0 (signed by HashiCorp)-->
<!--- Installing hashicorp/helm v2.5.1...-->
<!--- Installed hashicorp/helm v2.5.1 (signed by HashiCorp)-->

<!--Partner and community providers are signed by their developers.-->
<!--If you'd like to know more about provider signing, you can read about it here:-->
<!--https://www.terraform.io/docs/cli/plugins/signing.html-->

<!--Terraform has created a lock file .terraform.lock.hcl to record the provider-->
<!--selections it made above. Include this file in your version control repository-->
<!--so that Terraform can guarantee to make the same selections by default when-->
<!--you run "terraform init" in the future.-->

<!--Terraform has been successfully initialized!-->

<!--You may now begin working with Terraform. Try running "terraform plan" to see-->
<!--any changes that are required for your infrastructure. All Terraform commands-->
<!--should now work.-->

<!--If you ever set or change modules or backend configuration for Terraform,-->
<!--rerun this command to reinitialize your working directory. If you forget, other-->
<!--commands will detect it and remind you to do so if necessary.-->
<!--:::-->
<!--::::-->

```bash
# It is always a good practice to use a dry-run command
cd ~/environment/vpc
terraform plan
```

If there are no errors, you can proceed with deployment:
```bash
# The auto-approve flag avoids you having to confirm that you want to provision resources.
cd ~/environment/vpc
terraform apply -auto-approve
```

You can see the VPC in the [console](https://console.aws.amazon.com/vpc/home?#vpcs:tag:Name=eks-blueprint)

Next, you will create a EKS cluster.

::alert[This workshop uses local Terraform state. To learn about a proper setup, take a look at https://www.terraform.io/language/state]{header="Terraform State Management"}
