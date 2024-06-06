---
title: 'Update Labels and Annotations'
weight: 30
---

As you have seen in the previous chapter Cluster generator work on Cluster labels. In this chapter you will update labels and annotations for the hub-cluster. These will be used by ApplicationSet to generate Applications.

![eks-blueprint-blue](/static/images/argocd-update-metadata.png)

In the ArgoCD user interface, go to the hub cluster. The hub-cluster currently has some existing Labels and Annotations defined. These are added by GitOps Bridge.

![Hub Cluster Metadata](/static/images/hubcluster-initial-metadata.png)

> Labels can be used to find collections of objects that satisfy generator conditions. Annotations provide addiational information.

### 1. Add variables
You can have separate git repository for addons, platform and workloads. In this workshop they all exist in the same repository.

Define Git repository variables for addons, platform , and workloads. These repository variables will be referenced in upcoming chapters when generating Applications.

```json
cat <<'EOF' >> ~/environment/hub/variables.tf
variable "gitops_addons_url" {
  type        = string
  description = "Git repository addons url"
  default     = "https://github.com/aws-samples/eks-blueprints-for-terraform-workshop.git"
}
variable "gitops_platform_url" {
  type        = string
  description = "Git repository platform url"
  default     = "https://github.com/aws-samples/eks-blueprints-for-terraform-workshop.git"
}
variable "gitops_workload_url" {
  type        = string
  description = "Git repository platform url"
  default     = "https://github.com/aws-samples/eks-blueprints-for-terraform-workshop.git"
}
variable "gitops_addons_basepath" {
  type        = string  
  description = "Git repository base path for addons"
  default     = "assets/platform/addons/"
}
variable "gitops_addons_path" {
  type        = string  
  description = "Git repository path for addons"
  default     = "applicationset/"
}
variable "gitops_addons_revision" {
  type        = string  
  description = "Git repository revision/branch/ref for addons"
  default     = "HEAD"
}
variable "gitops_platform_basepath" {
  type        = string  
  description = "Git repository base path for platform"
  default     = "assets/platform/"
}
variable "gitops_platform_path" {
  type        = string  
  description = "Git repository path for platform"
  default     = "bootstrap"
}
variable "gitops_platform_revision" {
  type        = string  
  description = "Git repository revision/branch/ref for platform"
  default     = "HEAD"
}
variable "gitops_workload_basepath" {
  type        = string  
  description = "Git repository base path for platform"
  default     = "assets/developer/"
}
variable "gitops_workload_path" {
  type        = string  
  description = "Git repository path for workload"
  default     = "gitops/apps"
}
variable "gitops_workload_revision" {
  type        = string  
  description = "Git repository revision/branch/ref for platform"
  default     = "HEAD"
}

EOF
```

### Set git Values

Copy the provided code snippet, replace the placeholder value "<<replace with your github login>>" with your actual GitHub login, used to fork the repository. We use the full HTTPS clone URL **Then you can proceed.**

```bash
export GITHUB_LOGIN="<<replace with your github repo login>>"
```

```json
cat <<EOF >> ~/environment/terraform.tfvars
gitops_addons_url            = "https://github.com/${GITHUB_LOGIN}/eks-blueprints-for-terraform-workshop.git"
gitops_platform_url          = "https://github.com/${GITHUB_LOGIN}/eks-blueprints-for-terraform-workshop.git"
gitops_workload_url          = "https://github.com/${GITHUB_LOGIN}/eks-blueprints-for-terraform-workshop.git"

addons = {
    enable_aws_load_balancer_controller = false
    enable_aws_argocd = false
}
EOF
```

::alert[Check the file is correctly filled]{header="Important" type="warning"}

```bash
c9 open ~/environment/terraform.tfvars
```

Example:
```
eks_admin_role_name          = "WSParticipantRole"

gitops_addons_url            = "https://github.com/seb-workshop/eks-blueprints-for-terraform-workshop.git"
gitops_platform_url          = "https://github.com/seb-workshop/eks-blueprints-for-terraform-workshop.git"
gitops_workload_url          = "https://github.com/seb-workshop/eks-blueprints-for-terraform-workshop.git"

addons = {
    enable_aws_load_balancer_controller = false
    enable_aws_argocd = false
}
```

::alert[For simplicity in this workshop, we use the same Git repository for add-ons, platform, and workloads. However, the project is structured to allow you to easily use separate Git repositories for each functionality, depending on your needs.]{header="Important" type="warning"}

### 2. Define local variables.

Define some local variables, that include:
- *'addons'* local, which represents the Labels that will be sent to the Cluster Secret
- *'addons_metadata'* local, which represents the annotations that will be sent to the Cluster Secfret

Some values are commented and will be used later in the workshop.

:::code{showCopyAction=true showLineNumbers=false language=json highlightLines='48,73'}
cat <<'EOF' >> ~/environment/hub/main.tf

locals{
  aws_addons = {
    enable_aws_argocd                            = try(var.addons.enable_aws_argocd, false)    
    enable_cert_manager                          = try(var.addons.enable_cert_manager, false)
    enable_aws_efs_csi_driver                    = try(var.addons.enable_aws_efs_csi_driver, false)
    enable_aws_fsx_csi_driver                    = try(var.addons.enable_aws_fsx_csi_driver, false)
    enable_aws_cloudwatch_metrics                = try(var.addons.enable_aws_cloudwatch_metrics, false)
    enable_aws_privateca_issuer                  = try(var.addons.enable_aws_privateca_issuer, false)
    enable_cluster_autoscaler                    = try(var.addons.enable_cluster_autoscaler, false)
    enable_external_dns                          = try(var.addons.enable_external_dns, false)
    enable_external_secrets                      = try(var.addons.enable_external_secrets, false)
    enable_aws_load_balancer_controller          = try(var.addons.enable_aws_load_balancer_controller, false)
    enable_fargate_fluentbit                     = try(var.addons.enable_fargate_fluentbit, false)
    enable_aws_for_fluentbit                     = try(var.addons.enable_aws_for_fluentbit, false)
    enable_aws_node_termination_handler          = try(var.addons.enable_aws_node_termination_handler, false)
    enable_karpenter                             = try(var.addons.enable_karpenter, false)
    enable_velero                                = try(var.addons.enable_velero, false)
    enable_aws_gateway_api_controller            = try(var.addons.enable_aws_gateway_api_controller, false)
    enable_aws_ebs_csi_resources                 = try(var.addons.enable_aws_ebs_csi_resources, false)
    enable_aws_secrets_store_csi_driver_provider = try(var.addons.enable_aws_secrets_store_csi_driver_provider, false)
    enable_ack_apigatewayv2                      = try(var.addons.enable_ack_apigatewayv2, false)
    enable_ack_dynamodb                          = try(var.addons.enable_ack_dynamodb, false)
    enable_ack_s3                                = try(var.addons.enable_ack_s3, false)
    enable_ack_rds                               = try(var.addons.enable_ack_rds, false)
    enable_ack_prometheusservice                 = try(var.addons.enable_ack_prometheusservice, false)
    enable_ack_emrcontainers                     = try(var.addons.enable_ack_emrcontainers, false)
    enable_ack_sfn                               = try(var.addons.enable_ack_sfn, false)
    enable_ack_eventbridge                       = try(var.addons.enable_ack_eventbridge, false)
  }
  oss_addons = {
    enable_argocd                          = try(var.addons.enable_argocd, false)
    enable_argo_rollouts                   = try(var.addons.enable_argo_rollouts, false)
    enable_argo_events                     = try(var.addons.enable_argo_events, false)
    enable_argo_workflows                  = try(var.addons.enable_argo_workflows, false)
    enable_cluster_proportional_autoscaler = try(var.addons.enable_cluster_proportional_autoscaler, false)
    enable_gatekeeper                      = try(var.addons.enable_gatekeeper, false)
    enable_gpu_operator                    = try(var.addons.enable_gpu_operator, false)
    enable_ingress_nginx                   = try(var.addons.enable_ingress_nginx, false)
    enable_kyverno                         = try(var.addons.enable_kyverno, false)
    enable_kube_prometheus_stack           = try(var.addons.enable_kube_prometheus_stack, false)
    enable_metrics_server                  = try(var.addons.enable_metrics_server, false)
    enable_prometheus_adapter              = try(var.addons.enable_prometheus_adapter, false)
    enable_secrets_store_csi_driver        = try(var.addons.enable_secrets_store_csi_driver, false)
    enable_vpa                             = try(var.addons.enable_vpa, false)
  }
  addons = merge(
    local.aws_addons,
    local.oss_addons,
    { kubernetes_version = local.cluster_version },
    { aws_cluster_name = module.eks.cluster_name },
    { workloads = true }
    #enablewebstore,{ workload_webstore = true }      
  )


  gitops_addons_url      = var.gitops_addons_url
  gitops_addons_basepath = var.gitops_addons_basepath
  gitops_addons_path     = var.gitops_addons_path
  gitops_addons_revision = var.gitops_addons_revision

  gitops_platform_url      = var.gitops_platform_url
  gitops_platform_basepath = var.gitops_platform_basepath
  gitops_platform_path     = var.gitops_platform_path
  gitops_platform_revision = var.gitops_platform_revision

  gitops_workload_url      = var.gitops_workload_url
  gitops_workload_basepath = var.gitops_workload_basepath
  gitops_workload_path     = var.gitops_workload_path
  gitops_workload_revision = var.gitops_workload_revision

  addons_metadata = merge(
    #enableaddonmetadata module.eks_blueprints_addons.gitops_metadata,
    {
      aws_cluster_name = module.eks.cluster_name
      aws_region       = local.region
      aws_account_id   = data.aws_caller_identity.current.account_id
      aws_vpc_id       = local.vpc_id
    },
    {
      #enableirsarole argocd_iam_role_arn = aws_iam_role.argocd_hub.arn
      argocd_namespace    = local.argocd_namespace
    },
    {
       addons_repo_url      = local.gitops_addons_url
       addons_repo_basepath = local.gitops_addons_basepath
       addons_repo_path     = local.gitops_addons_path
       addons_repo_revision = local.gitops_addons_revision
    },
    {
       platform_repo_url      = local.gitops_platform_url
       platform_repo_basepath = local.gitops_platform_basepath
       platform_repo_path     = local.gitops_platform_path
       platform_repo_revision = local.gitops_platform_revision
    },
    {
       workload_repo_url      = local.gitops_workload_url
       workload_repo_basepath = local.gitops_workload_basepath
       workload_repo_path     = local.gitops_workload_path
       workload_repo_revision = local.gitops_workload_revision
    }

  )
}

EOF
:::

### 3. Define outputs

The purpose of these outputs is to provide data for upcoming spoke modules (in advanced sections).

```bash
cat <<'EOF' >> ~/environment/hub/outputs.tf

output "gitops_addons_url" {
  value = local.gitops_addons_url
}

output "gitops_addons_path" {
  value = local.gitops_addons_path
}

output "gitops_addons_revision" {
  value = local.gitops_addons_revision
}
    
output "gitops_addons_basepath" {
  value = local.gitops_addons_basepath
} 

output "gitops_platform_url" {
  value = local.gitops_platform_url
}

output "gitops_platform_path" {
  value = local.gitops_platform_path
}

output "gitops_platform_revision" {
  value = local.gitops_platform_revision
}
    
output "gitops_platform_basepath" {
  value = local.gitops_platform_basepath
} 

output "gitops_workload_url" {
  value = local.gitops_workload_url
}

output "gitops_workload_path" {
  value = local.gitops_workload_path
}

output "gitops_workload_revision" {
  value = local.gitops_workload_revision
}
    
output "gitops_workload_basepath" {
  value = local.gitops_workload_basepath
} 

EOF
```
### 4. Update Labels and Annotations

We need to update the labels and annotations on the hub-cluster Cluster object. To do this, we will use the GitOps Bridge. The GitOps Bridge is configured to update labels and annotations on the specified cluster object.

```bash
sed -i "s/#enablemetadata//g" ~/environment/hub/main.tf
```

The code provided above uncomments metdata and addons variables as highlighted below in `main.tf`. The values defined in the addons variable are assigned to Labels , while the metadata values are assigned to Annotations on the cluster object.

:::code{language=yml showCopyAction=false showLineNumbers=false highlightLines='7-8'}
module "gitops_bridge_bootstrap" {
  source  = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.0.1"
  cluster = {
    cluster_name = module.eks.cluster_name
    environment  = local.environment
     metadata     = local.addons_metadata
     addons       = local.addons
  }
:::


### 5. Terraform apply

```bash
cd ~/environment/hub
terraform apply --auto-approve
```
### 6. Validate update to labels and addons


Goto to the **Settings > Clusters > hub-cluster**  in the ArgoCD dashboard. Examine the Hub-Cluster Cluster object. This will confirm that GitOps Bridge has successfully updated the Labels and Annotations.

![Hub Cluster Updated Metadata](/static/images/hubcluster-update-metadata.png)


