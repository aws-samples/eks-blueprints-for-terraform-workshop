---
title: 'Bootstrap ArgoCD'
weight: 1
---

In this section, we are going to bootstrap [ArgoCD](https://github.com/argoproj/argo-cd/) as our GitOps engine. We will indicate in our configurations that we want to use our forked workloads repository. What this means is that any apps the Developer Teams want to deploy will need to be defined in this repository so that ArgoCD is aware.

ℹ️ You can learn more about ArgoCD and how it implements GitOps [here](https://argo-cd.readthedocs.io/en/stable/).

We will also configure the `eks-blueprints-add-ons` repository to manage the EKS Kubernetes add-ons for our cluster using ArgoCD. Deploying the Kubernetes add-ons with GitOps has several advantages, like the fact that their state will always be synchronized with the git repository thanks to the ArgoCD controller.

We will also reuse our demo git repositories containing sample workloads to deploy with ArgoCDD `eks-blueprints-workloads`, and another one for our EKS add-ons:


1. The https://github.com/aws-samples/eks-blueprints-add-ons.git will be used to install add-ons with ArgoCD. You **don't** need to fork it out for this workshop.
2. The https://github.com/aws-samples/eks-blueprints-workloads.git will be used for deploying applications with ArgoCD, and you need to **fork it** for this workshop.

![Environment architecture diagram](/static/images/argocd-eks-blue.png)

### 1. Add Argo application configuration

The first thing we need to do is augment our `locals.tf` definition in the `~/environment/eks-blueprint/modules/eks_cluster/locals.tf` file with the two new variables `addon_application` and `workload_application` as shown below.

Replace the entire `locals` section with the command below:

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
  #addons_repo_url            = var.addons_repo_url  
  #workload_repo_path         = var.workload_repo_path
  #workload_repo_url          = var.workload_repo_url
  #workload_repo_revision     = var.workload_repo_revision

  tag_val_vpc            = local.environment
  tag_val_public_subnet  = "${local.environment}-public-"
  tag_val_private_subnet = "${local.environment}-private-"

  node_group_name = "managed-ondemand"

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
  
  #---------------------------------------------------------------
  # ARGOCD ADD-ON APPLICATION
  #---------------------------------------------------------------

  #At this time (with new v5 addon repository), the Addons need to be managed by Terrform and not ArgoCD
  addons_application = {
    path                = "chart"
    repo_url            = local.addons_repo_url
    add_on_application  = true
  }

  #---------------------------------------------------------------
  # ARGOCD WORKLOAD APPLICATION
  #---------------------------------------------------------------

  workload_application = {
    path                = local.workload_repo_path # <-- we could also to blue/green on the workload repo path like: envs/dev-blue / envs/dev-green
    repo_url            = local.workload_repo_url
    target_revision     = local.workload_repo_revision

    add_on_application  = false
    
    values = {
      labels = {
        env   = local.env
      }
      spec = {
        source = {
          repoURL        = local.workload_repo_url
          targetRevision = local.workload_repo_revision
        }
        blueprint                = "terraform"
        clusterName              = local.name
        #karpenterInstanceProfile = module.karpenter.instance_profile_name # Activate to enable Karpenter manifests (only when Karpenter add-on will be enabled in the Karpenter workshop)
        env                      = local.env
      }
    }
  }  

}

EOF
```

## 2. Configure additional parameters

Append this to our module variables:

```bash
cat <<'EOF' >> ~/environment/eks-blueprint/modules/eks_cluster/variables.tf
variable "workload_repo_url" {
  type        = string
  description = "Git repo URL for the ArgoCD workload deployment"
  default     = "https://github.com/aws-samples/eks-blueprints-workloads.git"
}

variable "workload_repo_revision" {
  type        = string
  description = "Git repo revision in workload_repo_url for the ArgoCD workload deployment"
  default     = "main"
}

variable "workload_repo_path" {
  type        = string
  description = "Git repo path in workload_repo_url for the ArgoCD workload deployment"
  default     = "envs/dev"
}

variable "addons_repo_url" {
  type        = string
  description = "Git repo URL for the ArgoCD addons deployment"
  default     = "https://github.com/aws-samples/eks-blueprints-add-ons.git"
}

EOF
```

And those to the eks-blue parameters:

```bash
cat <<'EOF' >> ~/environment/eks-blueprint/eks-blue/variables.tf
variable "workload_repo_url" {
  type        = string
  description = "Git repo URL for the ArgoCD workload deployment"
  default     = "https://github.com/aws-samples/eks-blueprints-workloads.git"
}

variable "workload_repo_secret" {
  type        = string
  description = "Secret Manager secret name for hosting Github SSH-Key to Access private repository"
  default     = "github-blueprint-ssh-key"
}

variable "workload_repo_revision" {
  type        = string
  description = "Git repo revision in workload_repo_url for the ArgoCD workload deployment"
  default     = "main"
}

variable "workload_repo_path" {
  type        = string
  description = "Git repo path in workload_repo_url for the ArgoCD workload deployment"
  default     = "envs/dev"
}

variable "addons_repo_url" {
  type        = string
  description = "Git repo URL for the ArgoCD addons deployment"
  default     = "https://github.com/aws-samples/eks-blueprints-add-ons.git"
}

EOF
```

## 3. Configure the new parameters

Add those parameters to our `terraform.tfvars` configuration file: 

First, export an environment variable with your Github UserName, which will be used in the next command:
```
export GITHUB_USER=<YOUR_GITHUB_USER>
```

And then execute this command to configure the variables:
```bash
cat >>  ~/environment/eks-blueprint/terraform.tfvars <<EOF
addons_repo_url = "https://github.com/aws-samples/eks-blueprints-add-ons.git"

workload_repo_url = "https://github.com/${GITHUB_USER}/eks-blueprints-workloads.git"
workload_repo_revision = "main"
workload_repo_path     = "envs/dev"
EOF
```

::alert[Since we forked the workload repository, be sure to use your forked git url and that the url `https://github.com/${GITHUB_USER}/eks-blueprints-workloads.git` points to your fork.]{header="Important" type="warning"}

::alert[If you are not at an AWS event, update the **eks_admin_role_name** with the AWS IAM Role you are using in the AWS console.]{header="Important" type="warning"}

### 4. Pass the var from eks-blue to our module

We need the variables we just defined in eks-blue to be passed to our eks_cluster terraform module. For that, uncomment the lines in our `eks-blue/main.tf` file.

You can do it manually or with the following command:

```bash
for x in addons_repo_url workload_repo_path workload_repo_url workload_repo_revision; do
  sed -i "s/^\(\s*\)#\($x\s*=\s*var.$x\)/\1\2/" ~/environment/eks-blueprint/eks-blue/main.tf
done
```

```bash
cat ~/environment/eks-blueprint/eks-blue/main.tf
```

```
module "eks_cluster" {
  source = "../modules/eks_cluster"

  aws_region      = var.aws_region
  service_name    = "blue"
  cluster_version = "1.25"

  environment_name       = var.environment_name
  eks_admin_role_name    = var.eks_admin_role_name


  argocd_secret_manager_name_suffix = var.argocd_secret_manager_name_suffix
  
  addons_repo_url = var.addons_repo_url 

  workload_repo_url      = var.workload_repo_url
  workload_repo_revision = var.workload_repo_revision
  workload_repo_path     = var.workload_repo_path
}
```

### 5. Update the mapping from variables to local

```bash
for x in addons_repo_url workload_repo_path workload_repo_url workload_repo_revision; do
  sed -i "s/^\(\s*\)#\($x\s*=\s*var.$x\)/\1\2/" ~/environment/eks-blueprint/modules/eks_cluster/locals.tf
done
```

The `locals.tf` file then should be similar to:

```bash
cat ~/environment/eks-blueprint/modules/eks_cluster/locals.tf
```

```
locals {
  environment = var.environment_name
  service     = var.service_name

  env  = local.environment
  name = "${local.environment}-${local.service}"

  # Mapping
  cluster_version            = var.cluster_version
  argocd_secret_manager_name = var.argocd_secret_manager_name_suffix
  eks_admin_role_name        = var.eks_admin_role_name
  addons_repo_url            = var.addons_repo_url  
  workload_repo_path         = var.workload_repo_path
  workload_repo_url          = var.workload_repo_url
  workload_repo_revision     = var.workload_repo_revision  

  tag_val_vpc            = local.environment
  tag_val_public_subnet  = "${local.environment}-public-"
  tag_val_private_subnet = "${local.environment}-private-"

  node_group_name = "managed-ondemand"

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
  ...
```  

### 6. Add the EKS Blueprint Addons Terraform module to the main.tf file

Add the `kubernetes_addons` module at the end of our `main.tf`.
To have ArgoCD manage cluster add-ons, we set the `argocd_manage_add_ons` property to true. This allows the Terraform framework to provision necessary AWS resources, such as IAM Roles and Policies, 
but it will not apply Helm charts directly via the Terraform Helm provider, allowing Argo to handle it instead.

We also specify a custom `set` to configure Argo to expose the ArgoCD UI on an AWS load balancer. (Ideallly, we should do it using a secure ingress, but this will be easier for this lab.)

This will configure the ArgoCD add-on and allow it to deploy additional Kubernetes add-ons using GitOps.

Copy this at the end of the `main.tf`

```bash
cat <<'EOF' >> ~/environment/eks-blueprint/modules/eks_cluster/main.tf
module "kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=blueprints-workshops/modules/kubernetes-addons"

  eks_cluster_id     = module.eks.cluster_name

  #---------------------------------------------------------------
  # ARGO CD ADD-ON
  #---------------------------------------------------------------

  enable_argocd         = true
  argocd_manage_add_ons = true # Indicates that ArgoCD is responsible for managing/deploying Add-ons.

  argocd_applications = {
    addons    = local.addons_application
    #workloads = local.workload_application #We comment it for now
  }

  argocd_helm_config = {
    set_sensitive = [
      {
        name  = "configs.secret.argocdServerAdminPassword"
        value = bcrypt(data.aws_secretsmanager_secret_version.admin_password_version.secret_string)
      }
    ]    
    set = [
      {
        name  = "server.service.type"
        value = "LoadBalancer"
      }
    ]
  }

  #---------------------------------------------------------------
  # EKS Managed AddOns
  # https://aws-ia.github.io/terraform-aws-eks-blueprints/add-ons/
  #---------------------------------------------------------------

  enable_amazon_eks_coredns = true
  enable_amazon_eks_kube_proxy = true
  enable_amazon_eks_vpc_cni = true      
  enable_amazon_eks_aws_ebs_csi_driver = true

  #---------------------------------------------------------------
  # ADD-ONS - You can add additional addons here
  # https://aws-ia.github.io/terraform-aws-eks-blueprints/add-ons/
  #---------------------------------------------------------------


  enable_aws_load_balancer_controller  = true
  enable_aws_for_fluentbit             = true
  enable_metrics_server                = true

}
EOF
```

Now that we’ve added the `kubernetes_addons` module and configured ArgoCD, we will apply our changes.

<!--
::alert[Don't forget to save the cloud9 file as auto-save is not enabled by default.]{header="Important"}
-->

```bash
cd ~/environment/eks-blueprint/eks-blue
# We added a new module, so we must init
terraform init
```

```bash
# It is always a good practice to use a dry-run command
terraform plan
```

```bash
# Apply changes to provision the Platform Team
terraform apply -auto-approve
```

<!--
::::expand{header="View Terraform Output"}
:::code{showCopyAction=false language=hcl}

:::
::::
-->

