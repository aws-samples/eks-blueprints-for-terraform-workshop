---
title: 'Create ArgoCD Repository'
weight: 33
---


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

```bash
cd ~/environment/hub
terraform apply --auto-approve
```