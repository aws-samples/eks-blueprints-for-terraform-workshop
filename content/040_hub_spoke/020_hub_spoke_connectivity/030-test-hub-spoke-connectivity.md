---
title: "Test Hub-to-Spoke Connectivity with NGINX Add-on"
weight: 30
---

<!-- cspell:disable-next-line -->

::video{id=S2Zi516AV6E}

In this chapter, you'll enable the NGINX ingress controller on the spoke-staging cluster using GitOps. This helps validate that the hub cluster can manage spoke cluster add-ons.

### 1. Enable the NGINX Add-on Label

Add the label to your `terraform.tfvars` file:

```bash
sed -i 's/enable_ingress_nginx *= *.*/enable_ingress_nginx = true/' ~/environment/spoke/terraform.tfvars
```

### 2. Terraform Apply

<!-- prettier-ignore-start -->
:::code{showCopyAction=true language=json }
cd ~/environment/spoke
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->

### 3. Validate Nginx in Kubernetes

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
