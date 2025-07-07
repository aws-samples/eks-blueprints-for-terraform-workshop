---
title: "Inject Cluster Annotations"
weight: 10
---

<!-- cspell:disable-next-line -->

::video{id=m2Yr-cjrGE0}

Earlier in the "Application" chapter, you updated manually repoURL in the ArgoCD Application manifest. To make this more dynamic and reusable, you can use an ApplicationSet that pulls environment values like repoURL from metadata, from annotations on cluster objects.

Annotations are key-value pairs attached to ArgoCD cluster object.
The hub-cluster already includes annotations injected by GitOps Bridge. You can view these by navigating to ArgoCD Dashboard > Settings > Clusters > hub-cluster.

![Hub Cluster Metadata](/static/images/hubcluster-initial-metadata.png)

> Labels can be used to find collections of objects that satisfy generator conditions. Annotations provide additional information like repo URL.

In upcoming chapters, you'll create an ApplicationSet that references Git repositories. ArgoCD lets you reference these repositories dynamically using annotations. For example to reference workload_repo_url annotation:

<!-- prettier-ignore-start -->
:::code{language=yml showCopyAction=false showLineNumbers=false highlightLines='7'}
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
...
template:
   spec:
      source:
        repoURL:'{{.metadata.annotations.workload_repo_url}}'
:::
<!-- prettier-ignore-end -->

Information about repositories (platform,workloads,addons) is already populated in AWS Secrets(eks-blueprints-workshop-gitops-platform,eks-blueprints-workshop-gitops-workloads,eks-blueprints-workshop-gitops-addons). The following is AWS Secret values from eks-blueprints-workshop-gitops-platform . This secret stores metadata for the platform Git repository.

![Git Secrets](/static/images/git-secrets.png)

In this chapter you will copy these values into annotations so that they can be referenced in ArgoCD ApplicationSet.

### 1. Reference Secrets Manager

:::code{showCopyAction=true showLineNumbers=false language=json }
cat <<'EOF' >> ~/environment/hub/git_data.tf

# Retrieve Git repository metadata from AWS Secrets Manager for platform, workload, and addon repositories

data "aws_secretsmanager_secret" "git_data_addons" {
  name = var.secret_name_git_data_addons
}
data "aws_secretsmanager_secret_version" "git_data_version_addons" {
  secret_id = data.aws_secretsmanager_secret.git_data_addons.id
}
data "aws_secretsmanager_secret" "git_data_platform" {
  name = var.secret_name_git_data_platform
}
data "aws_secretsmanager_secret_version" "git_data_version_platform" {
  secret_id = data.aws_secretsmanager_secret.git_data_platform.id
}
data "aws_secretsmanager_secret" "git_data_workload" {
  name = var.secret_name_git_data_workloads
}
data "aws_secretsmanager_secret_version" "git_data_version_workload" {
  secret_id = data.aws_secretsmanager_secret.git_data_workload.id
}

EOF
:::

### 2. Retrieve Git Metadata from AWS Secrets

Each secret contains keys such as url, basepath, path, and revision.

Add the following block to your main.tf file to parse secrets and assign values to local variables:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cat <<'EOF' >> ~/environment/hub/main.tf

locals{

  gitops_addons_url      = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).url
  gitops_addons_basepath = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).basepath
  gitops_addons_path     = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).path
  gitops_addons_revision = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).revision


  gitops_platform_url      = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).url
  gitops_platform_basepath = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).basepath
  gitops_platform_path     = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).path
  gitops_platform_revision = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).revision


  gitops_workload_url      = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_workload.secret_string).url
  gitops_workload_basepath = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_workload.secret_string).basepath
  gitops_workload_path     = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_workload.secret_string).path
  gitops_workload_revision = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_workload.secret_string).revision

  annotations = merge(
    #enableaddonmetadata module.eks_blueprints_addons.gitops_metadata,
    {
      aws_cluster_name = module.eks.cluster_name
      aws_region = local.region
      aws_account_id = data.aws_caller_identity.current.account_id
      aws_vpc_id = local.vpc_id
      aws_vpc_name = data.terraform_remote_state.vpc.outputs.vpc_name
    },
    {
      #enableirsarole argocd_iam_role_arn = aws_iam_role.argocd_hub.arn
      argocd_namespace = local.argocd_namespace
    },
    {
      addons_repo_url = local.gitops_addons_url
      addons_repo_basepath = local.gitops_addons_basepath
      addons_repo_path = local.gitops_addons_path
      addons_repo_revision = local.gitops_addons_revision
    },
    {
      platform_repo_url = local.gitops_platform_url
      platform_repo_basepath = local.gitops_platform_basepath
      platform_repo_path = local.gitops_platform_path
      platform_repo_revision = local.gitops_platform_revision
    },
    {
      workload_repo_url = local.gitops_workload_url
      workload_repo_basepath = local.gitops_workload_basepath
      workload_repo_path = local.gitops_workload_path
      workload_repo_revision = local.gitops_workload_revision
    },
    #enableeso{
    #enableeso  external_secrets_service_account = local.external_secrets.service_account
    #enableeso  external_secrets_namespace = local.external_secrets.namespace
    #enableeso}    
  )
}

EOF
:::
<!-- prettier-ignore-end -->

### 3. Inject Annotations

The annotations are applied to the hub-cluster object using the GitOps Bridge module. Use the following command to uncomment the metadata line( line 7) and enable annotation injection:

<!-- prettier-ignore-start -->
:::code{language=yml showCopyAction=true showLineNumbers=false}
sed -i "s/#enableannotation//g" ~/environment/hub/main.tf
:::
<!-- prettier-ignore-end -->

The command above uncomments the metadata line( line 7) in main.tf, enabling annotation injection.

<!-- prettier-ignore-start -->
:::code{language=yml showCopyAction=false showLineNumbers=true highlightLines='7'}
module "gitops_bridge_bootstrap" {
  source = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.0.1"
  cluster = {
    cluster_name = module.eks.cluster_name
    environment = local.environment
    metadata = local.annotations
    #enableaddons addons = local.labels
}
:::
<!-- prettier-ignore-end -->

### 4. Terraform apply

<!-- prettier-ignore-start -->
:::code{language=yml showCopyAction=true showLineNumbers=false}
cd ~/environment/hub
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->

### 5. Validate update to labels and addons

Go to **Settings > Clusters > hub-cluster** in the Argo CD dashboard and examine the hub-cluster object. This will confirm that GitOps Bridge has successfully updated the Annotations.

![Hub Cluster Updated Metadata](/static/images/hubcluster-update-metadata.png)
