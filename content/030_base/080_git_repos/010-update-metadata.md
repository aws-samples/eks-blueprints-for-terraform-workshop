---
title: "Update Annotations"
weight: 10
---
Annotations are key-value pairs attached to ArgoCD Cluster object. In the Argo CD user interface, navigate to the hub-cluster. You’ll notice that the cluster already has some annotations defined. These are added automatically by the GitOps Bridge module.

![Hub Cluster Metadata](/static/images/hubcluster-initial-metadata.png)

> Labels can be used to find collections of objects that satisfy generator conditions. Annotations provide additional information like repo URL.

In upcoming chapters, you will create an ApplicationSet that references Git repositories. Argo CD supports referencing annotations. For example to reference workload_repo_url annotation:


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

Information about repositories(platform,workloads,addons) is already populated in AWS Secrets(eks-blueprints-workshop-gitops-platform,eks-blueprints-workshop-gitops-workloads,eks-blueprints-workshop-gitops-addons). The following is AWS Secret values from  eks-blueprints-workshop-gitops-platform . This secret holds information about platform git repository.

![Git Secrets](/static/images/git-secrets.png)

In this chapter you will copy these values into annotations so that they can be referenced in ArgoCD ApplicationSet.

### 1. Retrieve AWS Secrets


:::code{showCopyAction=true showLineNumbers=false language=json }
cat <<'EOF' >> ~/environment/hub/git_data.tf
# retrive from secret manager the git data for the platform and workload repositories


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

### 2. Define annotation variables

Each secret contains keys such as url, basepath, path, and revision. This modular structure allows you to use a single Git repository for multiple purposes by defining different base paths. Since this workshop uses separate repositories for each concern (addons, platform, and workload), basepath is unused, but included for completeness.

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

You can reference a folder in workload gitea repository in the following format.

![Git Folders](/static/images/gitea-folder.png)

### 4. Update Annotations

The annotations are applied to the hub-cluster object using the GitOps Bridge module. Use the following command to uncomment the metadata line( line 7) and enable annotation injection:

```bash
sed -i "s/#enableannotation//g" ~/environment/hub/main.tf
```

The code provided above uncomments metadata  as highlighted below in `main.tf`.  metadata values are assigned to Annotations on the cluster object.

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

### 5. Terraform apply

```bash
cd ~/environment/hub
terraform apply --auto-approve
```

### 6. Validate update to labels and addons

Go to to the **Settings > Clusters > hub-cluster** in the Argo CD dashboard. Examine the Hub-Cluster Cluster object. This will confirm that GitOps Bridge has successfully updated the Annotations.

![Hub Cluster Updated Metadata](/static/images/hubcluster-update-metadata.png)


Argo CD pulls labels and annotations for the cluster object from a kubernetes secret. We used gitops bridge to update annotations for the secret.

You can check the Labels and annotations on the cluster secret:

```bash
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o yaml
```

:::expand{header="Example of output"}

```
apiVersion: v1
data:
  config: ewogICJ0bHNDbGllbnRDb25maWciOiB7CiAgICAiaW5zZWN1cmUiOiBmYWxzZQogIH0KfQo=
  name: aHViLWNsdXN0ZXI=
  server: aHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3Zj
kind: Secret
metadata:
  annotations:
    addons_repo_basepath: ""
    addons_repo_path: bootstrap
    addons_repo_revision: HEAD
    addons_repo_url: https://dcv3flp70gaiw.cloudfront.net/gitea/workshop-user/eks-blueprints-workshop-gitops-addons
    argocd_namespace: argocd
    aws_account_id: "012345678910"
    aws_cluster_name: hub-cluster
    aws_load_balancer_controller_namespace: kube-system
    aws_load_balancer_controller_service_account: aws-load-balancer-controller-sa
    aws_region: us-west-2
    aws_vpc_id: vpc-0281c90d8fb4ce6a2
    cluster_name: hub-cluster
    environment: control-plane
    external_secrets_namespace: external-secrets
    external_secrets_service_account: external-secrets-sa
    platform_repo_basepath: ""
    platform_repo_path: bootstrap
    platform_repo_revision: HEAD
    platform_repo_url: https://dcv3flp70gaiw.cloudfront.net/gitea/workshop-user/eks-blueprints-workshop-gitops-platform
    workload_repo_basepath: ""
    workload_repo_path: ""
    workload_repo_revision: HEAD
    workload_repo_url: https://dcv3flp70gaiw.cloudfront.net/gitea/workshop-user/eks-blueprints-workshop-gitops-apps
  creationTimestamp: "2024-10-07T21:40:44Z"
  labels:
    argocd.argoproj.io/secret-type: cluster
    aws_cluster_name: hub-cluster
    cluster_name: hub-cluster
    enable_argocd: "true"
    environment: control-plane
    fleet_member: control-plane
    kubernetes_version: "1.30"
    tenant: tenant1
    workloads: "true"
  name: hub-cluster
  namespace: argocd
  resourceVersion: "6865"
  uid: af0dfcb9-a034-4f2d-be9b-167eb78c830a
type: Opaque
```

:::

You can see now in the secret all the metadatas that has been configured by the **gitops_bridge_bootstrap** terraform module.
