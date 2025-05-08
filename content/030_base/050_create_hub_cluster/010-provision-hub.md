---
title: "Create EKS cluster"
weight: 10
---

In this section, we will create an EKS cluster (hub) within the previously provisioned VPC, utilizing the EKS Terraform module to streamline the deployment process.

![EKS Cluster](/static/images/argocd-bootstrap-eks.png)

### 1. Create remote state

We need to reference outputs from the VPC module for our hub cluster.

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

In this section, we define the EKS version for the hub-cluster. From the console, we can manage EKS objects such as pods, deployments, and namespaces for the hub-cluster using the EKS admin role. Most of these variables will be configured later using the terraform.tfvars file.

:::expand{header="Detailed explanation of variables, click to check the description"}
Here, we define several variables used to create the EKS cluster:

- **kubernetes_version**: Specifies the version of Kubernetes to install or update in the EKS cluster.
- **eks_admin_role_name**: Represents the name of the IAM role granted administrative privileges within the EKS cluster.
- **addons**: Lists EKS add-ons to enable in the cluster. Add-ons provide additional functionality and integrations.
- **authentication_mode**: Determines the authentication mode used within the EKS cluster. The value "API_AND_CONFIG_MAP" allows authentication using either the EKS Access API or the Kubernetes aws-auth ConfigMap.
  :::

By providing these variables, we can customize the EKS cluster deployment according to specific requirements. The terraform.tfvars file will be used later to configure values for these variables, allowing easy modification of settings without changing the Terraform code directly.

```bash
cat > ~/environment/hub/variables.tf << 'EOF'
variable "kubernetes_version" {
  description = "EKS version"
  type        = string
  default     = "1.32"
}

variable "eks_admin_role_name" {
  description = "EKS admin role"
  type        = string
  default     = "WSParticipantRole"
}

variable "addons" {
  description = "EKS addons"
  type        = any
}

variable "project_context_prefix" {
  description = "Prefix for project"
  type        = string
  default     = "eks-blueprints-workshop"
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are CONFIG_MAP, API or API_AND_CONFIG_MAP"
  type        = string
  default     = "API"
}

variable "enable_irsa" {
  description = "IRSA is not required as cluster uses Pod Identity"
  type        = bool
  default     = false
}

variable "secret_name_git_data_addons" {
  description = "Secret name for Git data addons"
  type        = string
  default     = "eks-blueprints-workshop-gitops-addons"
}

variable "secret_name_git_data_platform" {
  description = "Secret name for Git data platform"
  type        = string
  default     = "eks-blueprints-workshop-gitops-platform"
}

variable "secret_name_git_data_workloads" {
  description = "Secret name for Git data workloads"
  type        = string
  default     = "eks-blueprints-workshop-gitops-workloads"
}



EOF
```

### 3. Configure EKS cluster

We configure the EKS cluster (hub) in the private subnets using the Terraform EKS module. It provisions a Managed Node Group with three EC2 instances, one in each Availability Zone, ensuring high availability. Additionally, it installs the following EKS managed add-ons: VPC-CNI for providing IP addresses to pods from the VPC private subnets, kube-proxy for internal traffic routing from services to pods, CoreDNS for internal service name resolution, and EKS Pod Identity for assigning IAM roles to pods in the cluster. Furthermore, an EKS access entry is created for the EKS admin IAM role, which was set up during the workshop and grants administrative access to the Kubernetes cluster. The IAM role is retrieved using a variable, and if we are completing this workshop independently, we will be prompted later to update the role using the terraform.tfvars configuration file that will be created.

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
  context_prefix   = var.project_context_prefix
  name            = "hub-cluster"
  region          = data.aws_region.current.id
  cluster_version = var.kubernetes_version
  enable_irsa = var.enable_irsa

  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets

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
  version = "~> 20.34.0"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

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

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose","system"]
  }

  tags = local.tags
}

EOF
```

### 4. Define outputs

The Terraform outputs will provide information about the resources we just created, including the command to access the EKS cluster and additional details that will be used later in the workshop.

```bash
cat > ~/environment/hub/outputs.tf << 'EOF'

output "configure_kubectl" {
  description = "Configure kubectl: make sure we're logged in with the correct AWS profile and run the following command to update our kubeconfig"
  value       = <<-EOT
    aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name} --alias ${module.eks.cluster_name}
  EOT
}

output "cluster_name" {
  description = "Cluster name"
  value       = module.eks.cluster_name
}
output "cluster_endpoint" {
  description = "Cluster endpoint"
  value       = module.eks.cluster_endpoint
}
output "cluster_certificate_authority_data" {
  description = "Cluster certificate_authority_data"
  value       = module.eks.cluster_certificate_authority_data
}
output "cluster_region" {
  description = "Cluster region"
  value       = local.region
}
output "cluster_node_security_group_id" {
  description = "Cluster node security group"
  value       = module.eks.node_security_group_id
}

EOF
```

### 5. Define variable values

We create the `terraform.tfvars` file to configure our Terraform parameters. The EKS admin role will be granted administrator rights inside Kubernetes, and enables access to view cluster resources through the AWS console.

```bash
cat >  ~/environment/hub/terraform.tfvars <<EOF
eks_admin_role_name          = "WSParticipantRole"
addons = {
}

EOF
```

:::alert{header="Important" type="warning"}
"**WSParticipantRole**" is the given role name when participating in an AWS event workshop. When working through the workshop **independently**, we should update it to reflect our own AWS role we are using in the AWS console

![AWS Console Role](/static/images/aws-console-role.png)

```bash
code ~/environment/hub/terraform.tfvars
```

Example:

```
eks_admin_role_name          = "Admin"
```

:::

### 6. Create EKS cluster

```bash
cd ~/environment/hub
terraform init
terraform apply -auto-approve
```

::alert[The process of creating Amazon EKS cluster typically requires approximately 15 minutes to complete.]{header="Wait for resources to create"}

### 7. Access hub cluster

To configure kubectl, execute the following command, which retrieves the connection details from the Terraform output to access the cluster:

```bash
eval $(terraform output -raw configure_kubectl)
```

To verify that kubectl is correctly configured, run the command below to see if the API endpoint is reachable. 

```bash
kubectl get svc --context hub-cluster
```


Example output:

```
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   172.20.0.1   <none>        443/TCP   19h
```
