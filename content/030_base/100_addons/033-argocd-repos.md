---
title: "Argo CD Git Repositories"
weight: 33
hidden: true
---

When we created the IDE, we set up Gitea "platform" and "workload" Git repositories. There are [different ways](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/) to provide Argo CD access to these repositories. In this chapter, we will grant Argo CD access to the Git repositories using Kubernetes secrets.

### 1. Create Argo CD secret for Git repositories

There are multiple approaches to create the secret. We could create it in Secrets Manager and use the External Secrets Operator to sync the secret into the cluster. For this workshop, we will create the secret using Terraform.

```json
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
```

### 2. Apply Terraform

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
