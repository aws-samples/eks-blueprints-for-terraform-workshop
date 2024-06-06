---
title: 'ArgoCD self manage'
weight: 10
---

### 1. Set ArgoCD label

```bash
sed -i "s/enable_aws_argocd = false/enable_aws_argocd = true/g" ~/environment/terraform.tfvars
```
The code snippet sets `enable_aws_argocd = true`. It causes the GitOps bootstrap module to add the label on the hub cluster, which enables ArgoCD deployment.

Changes by the code snippet is highlighted below.

:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='4'}
...
addons = {
    ...
    enable_aws_argocd = true
}

:::

The ApplicationSet addons-aws-oss-argocd-hub-appset.yaml file references configuration values for ArgoCD from the `assets/platform/addons/environments/default/addons/argo-cd/values.yaml` file. You can update the `values.yaml` as per your need. The default Refresh interval for the ArgoCD is 3 minutes (180 seconds). For this workshop, the Refresh interval has been updated to 5 seconds by setting the `timeout.reconciliation` value in `values.yaml` to 5. This shorter interval allows changes to happen faster during the workshop demonstrations.

![argocd-values](/static/images/argocd-values.png)

You can open the file in cloud9. Don't forget to commit if you make any changes.

```bash
c9 open ~/environment/wgit/assets/platform/addons/environments/default/addons/argo-cd/values.yaml
```

### 2. Apply Terraform

```bash
cd ~/environment/hub
terraform apply --auto-approve
```

ArgoCD dashboard should have ArgoCD Application.

![argocd-values](/static/images/argocd-selfmanage.png)

<!--
> If you can't access the dashboard then reopen the browser, try another browser, try http, clear browser history 
-->
