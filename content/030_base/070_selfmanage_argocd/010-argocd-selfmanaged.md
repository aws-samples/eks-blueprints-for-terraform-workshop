---
title: "Argo CD self manage"
weight: 10
---

### 1. Set Argo CD label

<!--
```bash
sed -i '/argocd:/,/enabled:/ s/enabled: false/enabled: true/' $GITOPS_DIR/addons/clusters/hub-cluster/addons/gitops-bridge/values.yaml
```

The code snippet activate the argocd addon in our gitops-bridge value file, causing the gitops-bridge helm chart to generate an additional ApplicationSet for ArgoCD.

The changes by the code snippet is highlighted below.

:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='3'}
...
argocd:
enabled: true # ArgoCD is enabled to replace the argocd installed at bootstrap time via terraform helm provider
prometheus_node_exporter:
enabled: false
kube_state_metrics:
enabled: false
...
:::
-->

```bash
sed -i '
/addons = {/,/}/{
    /}/i\
    enable_argocd = "true"
}
' ~/environment/hub/terraform.tfvars
```

This update the terraform.tfvars with:

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='6'}
eks_admin_role_name          = "WSParticipantRole"

addons = {
    enable_aws_load_balancer_controller = "true"
    enable_karpenter = "true"
    enable_argocd = "true"
}
:::
<!-- prettier-ignore-end -->

The ApplicationSet addons-aws-oss-argocd-hub-appset.yaml file references configuration values for Argo CD from the `addons/environments/default/addons/argo-cd/values.yaml` file in gitops-platform . You can update the `values.yaml` as per your need. The default Refresh interval for the Argo CD is 3 minutes (180 seconds). For this workshop, the Refresh interval has been updated to 5 seconds by setting the `timeout.reconciliation` value in `values.yaml` to 5. This shorter interval allows changes to happen faster during the workshop demonstrations.

![argocd-values](/static/images/argocd-values.jpg)

You can open the file in the IDE. Don't forget to commit if you make any changes.

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

We are updating the server `basehref` so that it works with our proxy setup.

<!--
### 2. Push Changes to Git:

```bash
git -C ${GITOPS_DIR}/addons add . || true
git -C ${GITOPS_DIR}/addons commit -m "Activate Managed Argo CD" || true
git -C ${GITOPS_DIR}/addons push || true
```
-->

### 2. Apply the changes with Terraform

```bash
cd ~/environment/hub
terraform init
terraform apply --auto-approve
```

### 3. Argocd Sync

```bash
argocd app sync argocd/bootstrap
argocd app sync argocd/cluster-addons
```

Argo CD dashboard should have Argo CD Application.

![argocd-values](/static/images/argocd-selfmanage.jpg)

:::alert{header=Note type=warning}
At some point, ArgoCD, will redeploy ArgoCD, in that case, you will lost the port-forward as the target pod will be renewed, you'll need to re-execute the following command to retrieve back the access

```bash
argocd_hub_credentials
```

:::

:::alert{header=Congratulations type=success}
Now you are managing your Argo CD system with Argo CD!
:::
