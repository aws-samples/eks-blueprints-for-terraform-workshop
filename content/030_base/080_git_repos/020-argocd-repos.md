---
title: "ArgoCD Git Repo"
weight: 20
---
We have Git repositories hosted in Gitea, but Argo CD does not yet have access to them. In this chapter, you will configure ArgoCD access to GitOps repositories. There are [different ways](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/) to provide Argo CD access to these repositories. We will use username and password method.

Credentials for repositories(platform,workloads,addons)  is already stored in AWS Secrets(eks-blueprints-workshop-gitops-platform,eks-blueprints-workshop-gitops-workloads,eks-blueprints-workshop-gitops-addons). The following is AWS Secret values from  eks-blueprints-workshop-gitops-platform secret . 

![Git Secrets](/static/images/git-secrets-credentials.png)

### 1. Read Git Credentials

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cat <<'EOF' >> ~/environment/hub/main.tf

locals{
  gitops_workload_repo_username = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_workload.secret_string).username
  gitops_workload_repo_password = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_workload.secret_string).password

  gitops_platform_repo_username = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).username
  gitops_platform_repo_password = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_platform.secret_string).password

  gitops_addons_repo_username = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).username
  gitops_addons_repo_password = jsondecode(data.aws_secretsmanager_secret_version.git_data_version_addons.secret_string).password

}

EOF
:::
<!-- prettier-ignore-end -->

### 2. Create Argo CD secret for Git repositories

There are multiple approaches to create the secret. We could create it in Secrets Manager and use the External Secrets Operator to sync the secret into the cluster. For this workshop, we will create the secret using Terraform.

:::code{showCopyAction=true showLineNumbers=false language=json }
cat <<'EOF' >> ~/environment/hub/main.tf

resource "kubernetes_secret" "git_secrets" {
  depends_on = [kubernetes_namespace.argocd]
  for_each = {
    git-addons = {
      type                  = "git"
      url                   = local.gitops_addons_url
      username              = local.gitops_addons_repo_username
      password              = local.gitops_addons_repo_password
    }
    git-platform = {
      type                  = "git"
      url                   = local.gitops_platform_url
      username              = local.gitops_platform_repo_username
      password              = local.gitops_platform_repo_password
    }
    git-workloads = {
      type                  = "git"
      url                   = local.gitops_workload_url
      username              = local.gitops_workload_repo_username
      password              = local.gitops_workload_repo_password
    }
  }
  metadata {
    name      = each.key
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  data = each.value
}
EOF
:::



### 3. Apply Terraform

This command applies the Terraform configuration and provisions the Argo CD secrets in your EKS cluster.

```bash
cd ~/environment/hub
terraform apply --auto-approve
```

Navigate to the Argo CD dashboard and access the **Settings** page. Select **Repositories** to view the gitops-platform and gitops-workload repositories.

![Argo CD Repositories](/static/images/argocd-repositories.jpg)

The Git repository connection data for Argo CD is stored in a Kubernetes Secret. We can verify that Terraform has created the Secret object containing the configurations to access Git repositories.

```bash
kubectl get secret -n argocd --selector=argocd.argoproj.io/secret-type=repository --context hub-cluster
```

Expected output:

```
NAME            TYPE     DATA   AGE
git-addons      Opaque   4      4m36s
git-platform    Opaque   4      4m36s
git-workloads   Opaque   4      4m36s
```
At this point, Argo CD can securely authenticate with your Git repositories using credentials stored in Kubernetes Secrets. 