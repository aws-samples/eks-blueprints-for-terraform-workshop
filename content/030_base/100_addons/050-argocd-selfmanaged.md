---
title: "Self-Manage Argo CD as an Addon"
weight: 50
---

Initially, Argo CD was installed using the GitOps Bridge. However, ArgoCD itself can also be managed as an addon. By enabling it as an addon, we allow  ArgoCD to fully manage its lifecycle—just like any other addon. This enables us to upgrade, modify, or uninstall ArgoCD declaratively via GitOps 

### 1. Set Argo CD label

```bash
sed -i '
/addons = {/,/}/{
    /}/i\
    enable_argocd = true
}
' ~/environment/hub/terraform.tfvars
```

This update to terraform.tfvars adds:

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='6'}
eks_admin_role_name          = "WSParticipantRole"

addons = {
    .
    .
    enable_argocd = "true"
}
:::
<!-- prettier-ignore-end -->

### 2. Apply the changes with Terraform

```bash
cd ~/environment/hub
terraform apply --auto-approve
```

### 3. Argo CD Sync

```bash
argocd app sync argocd/bootstrap
argocd app sync argocd/cluster-addons
```

You should now see the Argo CD application itself listed in the dashboard, managed like other addons.

![argocd-values](/static/images/argocd-selfmanage.png)

:::alert{header=Note type=warning}
When Argo CD redeploys itself, we will temporarily lose the port-forward connection as the target pod gets renewed. We will need to run the following command to restore access:

```bash
argocd_hub_credentials
```

:::

:::alert{header=Congratulations type=success}
We are now managing our Argo CD system with Argo CD!
:::
