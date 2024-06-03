---
title: 'Configure our environment'
weight: 1
---

In this section, we will be setting up our Terraform project. Create a new folder in your file system, then add the following specific files:

### 1. Create our Terraform project

```bash
mkdir -p ~/environment/eks-blueprint/environment
cd ~/environment/eks-blueprint/environment
```

First, we create a file called `versions.tf` that indicates which versions of Terraform and providers our project will use:

```bash
cat > ~/environment/eks-blueprint/environment/versions.tf << 'EOF'
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

### 2. Define our project's variables

Our environment's Terraform stack will have some variables so we can configure it:

- Environment name.
- The AWS region to use.
- The VPC cidr we want to create.
- A suffix that will be used to create a secret for ArgoCD later.

```bash
cat > ~/environment/eks-blueprint/environment/variables.tf << 'EOF'
variable "environment_name" {
  description = "The name of environment Infrastructure stack, feel free to rename it. Used for cluster and VPC names."
  type        = string
  default     = "eks-blueprint"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "argocd_secret_manager_name_suffix" {
  type        = string
  description = "Name of secret manager secret for ArgoCD Admin UI Password"
  default     = "argocd-admin-secret"
}
EOF
```

### 3. Define our project's main file

We are going to create our `main.tf` file in several steps, so we can explain what each part does.

#### Configure the environment

First, we define:

- An aws provider to interact with aws APIs that we configure for our region.
- We trigger+ data to retrieve our active availability zones in our AWS region.
- And creates some locals that will be used to configure our environment.
  - Some locals are created using the variables we previously defined.
  - The tags will be applied to AWS objects that our Terraform will create.

```bash
cat > ~/environment/eks-blueprint/environment/main.tf <<'EOF'
provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name   = var.environment_name
  region = var.aws_region

  vpc_cidr       = var.vpc_cidr
  num_of_subnets = min(length(data.aws_availability_zones.available.names), 3)
  azs            = slice(data.aws_availability_zones.available.names, 0, local.num_of_subnets)

  argocd_secret_manager_name = var.argocd_secret_manager_name_suffix

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

EOF
```

#### Create our VPC

Here we use the Terraform AWS VPC Module to provision an [Amazon Virtual Private Cloud](https://docs.aws.amazon.com/vpc/index.html) VPC and subnets.  We also make sure we enable NAT Gateway, Internet Gateway (IGW), DNS Hostnames to connect to the cluster after provisioning.

You can also see that we tag the subnets as required by EKS so that Amazon Elastic Load Balancer (ELB) knows they are used for our cluster.

Use this command to add the declaration to our `main.tf` file.

```bash
cat >> ~/environment/eks-blueprint/environment/main.tf <<'EOF'
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


#### Create additional resources

Finally, we will create some resources that will be shared by our clusters:

- We will generate a password that will be used by our deployment of ArgoCD.
- We will create an AWS Secret Manager secret with a prefix name we configure in our variables.

This command completes the `main.tf` we started to create

```bash
cat >> ~/environment/eks-blueprint/environment/main.tf <<'EOF'
#---------------------------------------------------------------
# ArgoCD Admin Password credentials with Secrets Manager
# Login to AWS Secrets manager with the same role as Terraform to extract the ArgoCD admin password with the secret name as "argocd"
#---------------------------------------------------------------
resource "random_password" "argocd" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "argocd" {
  name                    = "${local.argocd_secret_manager_name}.${local.name}"
  recovery_window_in_days = 0 # Set to zero for this example to force delete during Terraform destroy
}

resource "aws_secretsmanager_secret_version" "argocd" {
  secret_id     = aws_secretsmanager_secret.argocd.id
  secret_string = random_password.argocd.result
}

EOF
```



### 3. Create an outputs.tf file

We will initially output the VPC and related subnets, and later we will add a command to add the newly created cluster to our kubernetes `~/.kube/config` configuration file, which will enable access to our cluster. Please add the following contents to the `output.tf`:

```bash
cat > ~/environment/eks-blueprint/environment/outputs.tf <<'EOF'
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

EOF
```

### 4. Provide variables

Finally, we will use a variable file to provide specific deployment data to our Terraform modules:

```bash
cat >  ~/environment/eks-blueprint/terraform.tfvars <<EOF
aws_region          = "$AWS_REGION"
environment_name     = "eks-blueprint"

eks_admin_role_name = "WSParticipantRole"


eks_admin_role_name = "WSParticipantRole"

EOF
```

> **eks_admin_role_name** is the AWS Role you are using in the AWS console at an AWS event. Change it to your current AWS Role if you are in your own account.

Link this file into our environment directory:

```bash
ln -s ~/environment/eks-blueprint/terraform.tfvars ~/environment/eks-blueprint/environment/terraform.tfvars
```

::alert[This workshop uses local Terraform state. To learn about a proper setup, take a look at https://www.terraform.io/language/state]{header="Terraform State Management"}