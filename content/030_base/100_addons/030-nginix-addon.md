---
title: "Install Nginx Controller Addon"
weight: 30
---

<!-- cspell:disable-next-line -->

::video{id=AB82_H6fMh4}

GitOps Bridge makes it easy to install cluster add-ons by simply setting a label to `true`.

In this chapter, you’ll deploy the NGINX Ingress Controller by setting the `enable_ingress_nginx=true` label.

# Install Nginx Add-on

### 1. Enable the NGINX Add-on Label

Add the label to your `terraform.tfvars` file:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true language=json highlightLines='4'}
sed -i '
/addons = {/,/}/{
    /}/i\
    enable_ingress_nginx = true
}
' ~/environment/hub/terraform.tfvars
:::
<!-- prettier-ignore-end -->

### 2. Terraform Apply

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cd ~/environment/hub
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->

### 3. Validate Label in ArgoCD

Navigate to **Argo CD > Settings > hub-cluster**. You should see the label `enable_ingress_nginx=true`.

![Enable Nginx](/static/images/enable-nginx.png)

### 4. Validate Nginx Application addon

Navigate to ArgoCD dashboard>Applications>cluster-addon. You can see addon-ingress-nginx-hub-cluster ApplicationSet.

![Enable Nginx](/static/images/nginx-application.png)

### 5. Validate NGINX Add-on Deployment

<!-- :::alert{header="Sync Application"}
If the `addon-ingress-nginx-hub-cluster` application is not visible after a few minutes, click **SYNC** and then **SYNCHRONIZE** in Argo CD.

Alternatively, you can sync it via CLI:

```bash
argocd app sync argocd/cluster-addons
```
::: -->

You can check nginx pods

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
kubectl get pods -n ingress-nginx
:::
<!-- prettier-ignore-end -->

You should see output similar to the following.

```
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-patch-r59hq        0/1     Completed   0          72m
ingress-nginx-controller-d46976f8f-w48ln   1/1     Running     0          73m
```

# Remove Nginx Add-on

### 1. Disable the Nginx label

Set the label to false in terraform.tfvars:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
sed -i 's/enable_ingress_nginx *= *.*/enable_ingress_nginx = false/' ~/environment/hub/terraform.tfvars
:::
<!-- prettier-ignore-end -->

### 2. Apply Terraform

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cd ~/environment/hub
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->

### 3. Validate Nginx removed

Check the Argo CD dashboard to confirm that the application has been deleted.

Kubernetes resources created by the application are not deleted automatically due to the sync policy, which protects against accidental deletions. This behavior is configurable.
