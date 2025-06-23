---
title: "Self-Manage ArgoCD as an Addon"
weight: 50
---

::video{id=v-WLsiTiiP8}

Initially, ArgoCD was installed using the GitOps Bridge Terraform module. However, ArgoCD can also be managed as a GitOps-managed add-on—just like any other add-on. 

By enabling ArgoCD as an add-on, we allow it to manage its own lifecycle. This enables declarative upgrades, configuration changes, and even clean removal, all via GitOps.



### 1. Set ArgoCD label

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
sed -i '
/addons = {/,/}/{
    /}/i\
    enable_argocd = true
}
' ~/environment/hub/terraform.tfvars
:::
<!-- prettier-ignore-end -->
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

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
cd ~/environment/hub
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->




### 3. Validate ArgoCD add-on

<!-- :::alert{header="Sync Application"}
If the new addon-argocd-hub-cluster is not visible after a few minutes, you can click on SYNC and SYNCHRONIZE in ArgoCD to force it to synchronize.

Alternatively you can do it with CLI:

```bash
argocd app sync argocd/cluster-addons
```

::: -->

You should now see the ArgoCD application itself listed in the dashboard, managed like other addons.

![argocd-values](/static/images/argocd-selfmanage.png)

:::alert{header=Note type=warning}
When ArgoCD redeploys itself, the connection will be temporarily lost as the target pod is renewed. It may take a **few minutes** for the ArgoCD Dashboard to re-establish the connection. 
:::




:::alert{header=Congratulations type=success}
We are now managing our ArgoCD system with ArgoCD!
:::
