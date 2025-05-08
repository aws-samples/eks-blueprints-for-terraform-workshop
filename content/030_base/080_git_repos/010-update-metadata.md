---
title: "Update Annotations"
weight: 10
---


In this chapter, we’ll add annotations to the cluster. 

In the Argo CD user interface, go to the hub cluster. The hub-cluster currently has some existing Labels and Annotations defined. These are added by GitOps Bridge.

![Hub Cluster Metadata](/static/images/hubcluster-initial-metadata.png)

> Labels can be used to find collections of objects that satisfy generator conditions. Annotations provide additional information.

### 1. Git repository 
We have configured three Git repositories to store add-ons and workloads. The repository URLs are already stored in AWS Secrets Manager. We will retrieve these into terraform variables.


```json
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
```

### 2. Define annotation variables

Define **enable_XXX_addons** boolean variables. These provide a simple way to control whether addons are installed or removed, that will be stored as labels.

Define addons_metadata variable as a list of key/value pairs that will be mapped to the secret annotations, and contain any important data that Argo CD can uses to configure the Applications.

Some values are commented and will be used later in the workshop.

For example, in the highlighted section below, We’ve defined the enable_cert_manager variable in the Terraform variables file. When it is set enable_cert_manager = true, Cert Manager is deployed; setting it to false removes it.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='6'}
cat <<'EOF' >> ~/environment/hub/main.tf

locals{

  gitops_addons_url      = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).url
  gitops_addons_basepath = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).basepath
  gitops_addons_path     = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).path
  gitops_addons_revision = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).revision

  gitops_addons_repo_secret_key = var.secret_name_git_data_addons
  gitops_addons_repo_username = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).username
  gitops_addons_repo_password = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).password

  gitops_platform_url      = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).url
  gitops_platform_basepath = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).basepath
  gitops_platform_path     = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).path
  gitops_platform_revision = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).revision

  gitops_platform_repo_secret_key = var.secret_name_git_data_platform
  gitops_platform_repo_username = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).username
  gitops_platform_repo_password = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).password

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
    }
  )
}

EOF
:::
<!-- prettier-ignore-end -->

### 4. Update Labels and Annotations

We need to update the labels and annotations on the hub-cluster Cluster object. To do this, we will use the GitOps Bridge. The GitOps Bridge is configured to update labels and annotations on the specified cluster object.

```bash
sed -i "s/#enableannotation//g" ~/environment/hub/main.tf
```

The code provided above uncomments metadata and addons variables as highlighted below in `main.tf`. The values defined in the addons variable are assigned to Labels, while the metadata values are assigned to Annotations on the cluster object.

<!-- prettier-ignore-start -->
:::code{language=yml showCopyAction=false showLineNumbers=false highlightLines='7'}
module "gitops_bridge_bootstrap" {
  source = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.0.1"
  cluster = {
    cluster_name = module.eks.cluster_name
    environment = local.environment
    metadata = local.annotations
    #enablelable addons = local.labels
}
:::
<!-- prettier-ignore-end -->

### 5. Terraform apply

```bash
cd ~/environment/hub
terraform apply --auto-approve
```

### 6. Validate update to labels and addons

Goto to the **Settings > Clusters > hub-cluster** in the Argo CD dashboard. Examine the Hub-Cluster Cluster object. This will confirm that GitOps Bridge has successfully updated the Labels and Annotations.

![Hub Cluster Updated Metadata](/static/images/hubcluster-update-metadata.png)

Argo CD pulls labels and annotations for the cluster object from a kubernetes secret. We used gitops bridge to update labels and annotations for the secret.

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
