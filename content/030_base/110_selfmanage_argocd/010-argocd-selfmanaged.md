---
title: "Argo CD self manage"
weight: 10
---

### 1. Set Argo CD label

```bash
sed -i '
/addons = {/,/}/{
    /}/i\
    enable_argocd = "true"
}
' ~/environment/hub/terraform.tfvars
```

This update to terraform.tfvars adds:

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='4'}
eks_admin_role_name          = "WSParticipantRole"

addons = {
    enable_argocd = "true"
}
:::
<!-- prettier-ignore-end -->

The ApplicationSet file addons-aws-oss-argocd-hub-appset.yaml references Argo CD configuration values from the `addons/environments/default/addons/argo-cd/values.yaml` file in gitops-platform. We can update the `values.yaml` as needed. For this workshop, we have set the Refresh interval to 5 seconds by configuring `timeout.reconciliation` to 5 in `values.yaml`. This shorter interval allows changes to propagate more quickly during workshop demonstrations, compared to the default 3-minute (180 second) interval.

![argocd-values](/static/images/argocd-values.jpg)

We can open the file in the IDE. Let's remember to commit if we make any changes.

```bash
code $GITOPS_DIR/addons/environments/control-plane/addons/argocd/values.yaml
```

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='5'}
configs:
  cm:
    ui.bannercontent: "Management Environment ArgoCD"
  params:
    server.basehref: /proxy/8081/
:::
<!-- prettier-ignore-end -->

We are updating the server `basehref` to work with our proxy setup.

### 2. Apply the changes with Terraform

```bash
cd ~/environment/hub
terraform init
terraform apply --auto-approve
```

### 3. Argo CD Sync

```bash
argocd app sync argocd/bootstrap
argocd app sync argocd/cluster-addons
```

The Argo CD dashboard should now display the Argo CD Application.

![argocd-values](/static/images/argocd-selfmanage.jpg)

:::alert{header=Note type=warning}
When Argo CD redeploys itself, we will temporarily lose the port-forward connection as the target pod gets renewed. We will need to run the following command to restore access:

```bash
argocd_hub_credentials
```

:::

:::alert{header=Congratulations type=success}
We are now managing our Argo CD system with Argo CD!
:::
