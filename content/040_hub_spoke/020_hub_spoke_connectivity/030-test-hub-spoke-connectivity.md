---
title: "Test Hub-to-Spoke Connectivity with NGINX Add-on"
weight: 30
---

::video{id=S2Zi516AV6E}

In this chapter, you'll enable the NGINX ingress controller on the spoke-staging cluster using GitOps. This helps validate that the hub cluster can manage spoke cluster add-ons.

### 1. Enable the NGINX Add-on Label

Add the label to your `terraform.tfvars` file:

```bash
sed -i 's/enable_ingress_nginx *= *.*/enable_ingress_nginx = true/' ~/environment/spoke/terraform.tfvars
```

### 2. Terraform Apply

:::code{showCopyAction=true language=json }
cd ~/environment/spoke
terraform apply --auto-approve
:::


### 3. Validate Nginx in Kubernetes

<!-- :::alert{header="Sync Application"}
If the new addon-ingress-nginx-hub-cluster is not visible after a few minutes, you can click on SYNC and SYNCHRONIZE in Argo CD to force it to synchronize.

Or you can do it also with cli:

```bash
argocd app sync argocd/cluster-addons
```

::: -->

You can check nginx pods

```bash
kubectl get pods -n ingress-nginx --context spoke-staging
```

You should see output similar to the following.

```
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-patch-r59hq        0/1     Completed   0          72m
ingress-nginx-controller-d46976f8f-w48ln   1/1     Running     0          73m
```



