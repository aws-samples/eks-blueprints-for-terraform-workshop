---
title: "Install Ngnix Controller with GitOps Bridge"
weight: 30
---

GitOps Bridge make installing an addon easy by setting a cluster addon variable to true.

In the following code, let's deploy nginx by setting enable_ingress_nginx=true. 

### 1. Enable Nginx controller 

:::code{showCopyAction=true language=json highlightLines='4'}
sed -i '
/addons = {/,/}/{
    /}/i\
    enable_ingress_nginx = true
}
' ~/environment/hub/terraform.tfvars
:::

### 2. Terraform Apply

:::code{showCopyAction=true language=json }
cd ~/environment/hub
terraform apply --auto-approve
:::

### 3. Validate label

Navigate to ArgoCD dashboard>setting>hub-cluster. You can see label enable_ingress_nginx=true.

![Enable Nginx](/static/images/enable-nginx.png)

### 4. Validate Nginx Application addon

Navigate to ArgoCD dashboard>Applications>cluster-addon. You can see  addon-ingress-nginx-hub-cluster ApplicationSet.

![Enable Nginx](/static/images/nginx-application.png)

### 5. Validate Nginx in Kubernetes

:::alert{header="Sync Application"}
If the new addon-ingress-nginx-hub-cluster is not visible after a few minutes, you can click on SYNC and SYNCHRONIZE in Argo CD to force it to synchronize.

Or you can do it also with cli:

```bash
argocd app sync argocd/cluster-addons
```

:::

You can check nginx pods

```bash
kubectl get pods -n ingress-nginx
```

You should see output similar to the following.

```
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-patch-r59hq        0/1     Completed   0          72m
ingress-nginx-controller-d46976f8f-w48ln   1/1     Running     0          73m
```

### 6. Remove Nginx controller 

You can remove an addon by setting its corresponding label to false. 

The following code set nginx addon variable to false. 

```bash
sed -i 's/enable_ingress_nginx *= *.*/enable_ingress_nginx = false/' ~/environment/hub/terraform.tfvars
```

### 7. Apply Terraform

```bash
cd ~/environment/hub
terraform apply --auto-approve
```

### 8. Validate Nginx removed

You can validate on ArgoCD dashboard that the Application is deleted. Note: The Kubernetes resources are not deleted automatically due to the sync policy, which prevents accidental deletion. This behavior can be customized.


