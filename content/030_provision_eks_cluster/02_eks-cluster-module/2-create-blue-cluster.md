---
title : "Provision Amazon EKS Blue Cluster"
weight : 2
---

Now we are going to create an instance eks-blue of our module:

```bash
mkdir -p ~/environment/eks-blueprint/eks-blue
cd ~/environment/eks-blueprint/eks-blue
```

![Environment architecture diagram](/static/images/eks-blue.png)

## 1. Let's create the Terraform structure for our EKS blue cluster

```bash
cat > ~/environment/eks-blueprint/eks-blue/providers.tf << 'EOF'
terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}

EOF
```

## 2. Let's create the variables for our cluster

```bash
cat > ~/environment/eks-blueprint/eks-blue/variables.tf << 'EOF'
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "environment_name" {
  description = "The name of Environment Infrastructure stack name, feel free to rename it. Used for cluster and VPC names."
  type        = string
  default     = "eks-blueprint"
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

## 3. And link to our `terraform.tfvars` variable file

```bash
ln -s ~/environment/eks-blueprint/terraform.tfvars ~/environment/eks-blueprint/eks-blue/terraform.tfvars
```

::alert[If you are **On You Own** account, you may want to update the terraform.tfvars with a valid admin Role name, for example: **eks_admin_role_name = "Admin"**, corresponding to your IAM role you want to use."]


## 4. Create our main.tf file

- We configure our providers for **kubernetes**, **helm** and **kubectl**.
- We call our eks-blueprint module, prividing the variables.


```bash
cat > ~/environment/eks-blueprint/eks-blue/main.tf << 'EOF'
provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = module.eks_cluster.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks_cluster.eks_cluster_id]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", module.eks_cluster.eks_cluster_id]
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = module.eks_cluster.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks_cluster.eks_cluster_id]
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks_cluster.eks_cluster_id
}

module "eks_cluster" {
  source = "../modules/eks_cluster"

  aws_region      = var.aws_region
  service_name    = "blue"
  cluster_version = "1.25"

  environment_name       = var.environment_name
  eks_admin_role_name    = var.eks_admin_role_name

  argocd_secret_manager_name_suffix = var.argocd_secret_manager_name_suffix

  #addons_repo_url = var.addons_repo_url 

  #workload_repo_url      = var.workload_repo_url
  #workload_repo_revision = var.workload_repo_revision
  #workload_repo_path     = var.workload_repo_path

}

EOF
```

## 5. Define our Terraform outputs

We want our Terraform stack to output information from our eks_cluster module:

- The EKS cluster ID.
- The command to configure our kubectl for the creator of the EKS cluster.
- 
```bash
cat > ~/environment/eks-blueprint/eks-blue/outputs.tf << 'EOF'
output "eks_cluster_id" {
  description = "The name of the EKS cluster."
  value       = module.eks_cluster.eks_cluster_id
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = module.eks_cluster.configure_kubectl
}
EOF
```

Next, execute the following commands in your terminal so that we can add the EKS Blueprints Terraform Module.

```bash
# we need to do this again, since we added a new module.
cd ~/environment/eks-blueprint/eks-blue
terraform init
```


```bash
# Always a good practice to use a dry-run command
terraform plan
```

```bash
# then provision our EKS cluster
# the auto approve flag avoids you having to confirm you want to provision resources.
terraform apply -auto-approve
```

::alert[Time to grab your beverage of choice!]{header="The EKS cluster creation will take 15 minutes to deploy."}
