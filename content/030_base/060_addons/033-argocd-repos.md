---
title: 'Create ArgoCD Repositories'
weight: 33
---

In the previous chapter, we created "gitops-platform" and "gitops-workload" CodeCommit repositories. There are [different ways](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/) to provide ArgoCD access to these repositories. In this chapter, we will use SSH private keys to grant ArgoCD access to the CodeCommit repositories.

### 1. Create ArgoCD git repositories

```json
cat <<'EOF' >> ~/environment/hub/main.tf
locals{
  git_private_ssh_key = data.terraform_remote_state.git.outputs.git_private_ssh_key
}

resource "kubernetes_secret" "git_secrets" {
  for_each = {
    git-platform = {
      type                  = "git"
      url                   = local.gitops_platform_url
      sshPrivateKey         = file(pathexpand(local.git_private_ssh_key))
      insecureIgnoreHostKey = "true"
    }
    git-workloads = {
      type                  = "git"
      url                   = local.gitops_workload_url
      sshPrivateKey         = file(pathexpand(local.git_private_ssh_key))
      insecureIgnoreHostKey = "true"
    }

  }
  metadata {
    name      = each.key
    namespace = local.argocd_namespace
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

Navigate to the ArgoCD dashboard, then go to the Settings page, and select Repositories to view gitops-platform and gitops-workload repositories

![ArgoCD Repositories](/static/images/argocd-repositories.png)

The Git repository connection data for ArgoCD is stored in a Kubernetes Secret. You can verify that ArgoCD has created the Secret object that contains the configuration, including the SSH private keys, to access  Git repositories. 

```json
kubectl get secret -n argocd --selector=argocd.argoproj.io/secret-type=repository --context hub
```

![ArgoCD Repository Secret](/static/images/argocd_k8s_repos.png)

