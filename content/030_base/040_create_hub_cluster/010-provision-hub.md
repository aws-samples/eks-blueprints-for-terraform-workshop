---
title: "Create EKS Cluster"
weight: 10
---

Here, we create an EKS cluster (hub) within the previously provisioned VPC, utilizing the EKS Terraform module to streamline the deployment process.

![EKS Cluster](/static/images/argocd-bootstrap-eks.jpg)

### 1. Create Remote State

::::expand{header="Get vpc and private subnet values from the vpc module. Click to know more about Terraform remote state"}
The use of remote state in Terraform allows you to share and reuse infrastructure resources across multiple configurations or teams. In the context of this code, the remote state is being read to retrieve the VPC and private subnet values from the previously created VPC module. This approach offers several benefits:

1. **Separation of Concerns**: By separating the VPC creation and EKS cluster deployment into different Terraform configurations, you can assign responsibilities to different teams or individuals. For example, a central team could be responsible for creating accounts and VPCs, while another team handles the deployment of EKS clusters within those VPCs.
2. **Reusability**: Instead of recreating the VPC infrastructure for each EKS cluster deployment, you can reuse the existing VPC by fetching its state from the remote state. This promotes efficient resource utilization and avoids duplication of effort.
3. **Consistency**: By referencing the remote state, you ensure that the EKS cluster is deployed within the correct VPC and private subnets, maintaining consistency across your infrastructure.
4. **Collaboration**: Remote state enables collaboration between teams or individuals working on different parts of the infrastructure. Changes made to the VPC by one team are automatically reflected in the EKS cluster deployment, facilitating seamless integration and reducing the risk of configuration drift.
5. **Modular Architecture**: Leveraging remote state promotes a modular architecture, where different components of your infrastructure can be managed independently while still maintaining dependencies and relationships between them.

By embracing the use of remote state, you can effectively decouple the management of different infrastructure components, enabling better collaboration, reusability, and consistency across your AWS environment.
::::

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

In this section, we define the EKS version for the hub-cluster. From the console, you can manage EKS objects such as pods, deployments, namespaces, etc., for the hub-cluster using the EKS admin role. Most of these variables will be configured later using the terraform.tfvars file.

:::expand{header="Detailed Explanation of Variables, Click to check the description"}
Here, we define several variables that will be used to create the EKS cluster:
- **kubernetes_version**: This variable specifies the version of Kubernetes to be installed or updated in the EKS cluster.
- **eks_admin_role_name**: This variable represents the name of the IAM role that will be granted administrative privileges within the EKS cluster.
- **addons**: This is a list of EKS add-ons that you want to enable in the cluster. Add-ons provide additional functionality and integrations for your EKS cluster.
- **authentication_mode**: This variable determines the authentication mode used within the EKS cluster. The value "API_AND_CONFIG_MAP" allows authentication using either the EKS Access API or the Kubernetes aws-auth ConfigMap.
  :::
  By providing these variables, you can customize the EKS cluster deployment according to your specific requirements. The terraform.tfvars file will be used later to configure the values for these variables, allowing you to easily modify the settings without changing the Terraform code directly.

```bash
cat > ~/environment/hub/variables.tf << 'EOF'
variable "kubernetes_version" {
  description = "EKS version"
  type        = string
  default     = "1.30"
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
    enable_aws_argocd = false
  }
}

variable "project_context_prefix" {
  description = "Prefix for project"
  type        = string
  default     = "eks-blueprints-workshop"
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are CONFIG_MAP, API or API_AND_CONFIG_MAP"
  type        = string
  default     = "API_AND_CONFIG_MAP"
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

### 3. Configure EKS Cluster

The EKS cluster (hub) is configured in the private subnets using the Terraform EKS module. It provisions a Managed Node Group with three EC2 instances, one in each Availability Zone, ensuring high availability. Additionally, it installs the following EKS managed add-ons: VPC-CNI for providing IP addresses to pods from the VPC private subnets, kube-proxy for internal traffic routing from services to pods, CoreDNS for internal service name resolution, and EKS Pod Identity for assigning IAM roles to pods in the cluster. Furthermore, an EKS access entry is created for the EKS admin IAM role, which was set up during the workshop and grants administrative access to the Kubernetes cluster. The IAM role is retrieved using a variable, and if you are completing this workshop independently, you will be prompted later to update the role using the terraform.tfvars configuration file that will be created.

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
  tenant          = "tenant1"
  fleet_member     = "control-plane"

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

The Terraform outputs will provide information about the resources we just created, including the command to access the EKS cluster and additional details that will be used later in the workshop.

```bash
cat > ~/environment/hub/outputs.tf << 'EOF'

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
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
cat >  ~/environment/terraform.tfvars <<EOF
eks_admin_role_name          = "WSParticipantRole"

EOF
```

:::alert{header="Important" type="warning"}
"**WSParticipantRole**" is the given role name when participating in an AWS event workshop. When working through the workshop **independently**, you should update it to reflect your own AWS role you are using in the AWS console

![AWS Console Role](/static/images/aws-console-role.png)

```bash
code ~/environment/terraform.tfvars
```

Example:

```
eks_admin_role_name          = "Admin"
```

:::

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

::alert[The process of creating Amazon EKS cluster typically requires approximately 15 minutes to complete.]{header="Wait for resources to create"}

### 8. Access Hub Cluster

To configure kubectl, execute the following command, which retrieves the connection details from the Terraform output to access the cluster:

```bash
eval $(terraform output -raw configure_kubectl)
```

To verify that kubectl is correctly configured, run the command below to see the nodes in the EKS cluster.

```bash
kubectl get nodes --context hub-cluster
```

Expected output:

```
NAME                                        STATUS   ROLES    AGE   VERSION
ip-10-0-43-5.eu-west-1.compute.internal     Ready    <none>   21m   v1.28.13-eks-a737599
ip-10-0-45-193.eu-west-1.compute.internal   Ready    <none>   21m   v1.28.13-eks-a737599
ip-10-0-51-9.eu-west-1.compute.internal     Ready    <none>   21m   v1.28.13-eks-a737599
```
