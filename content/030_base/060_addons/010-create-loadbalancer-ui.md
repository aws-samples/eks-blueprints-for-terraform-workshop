---
title: 'Manually install AWS Load Balancer controller addon'
weight: 10
---

In this chapter, you will install the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) addon on the hub cluster using the ArgoCD UI. It will be automated in the upcoming chapters. The Load Balancer addon provides Kubernetes resources access to AWS Elastic Load Balancers.


### 1. Create Application
1. Log into the ArgoCD dashboard as the admin user. 

2. Click "+ NEW APP" to start creating a new Application.

3. On the "Create Application" page:

You have **two options** for creating the Application - either provide the manifest file directly, or enter the values manually.

#### Create with Manifest

Click the "EDIT AS YAML" button and replace the existing YAML content with the provided YAML below.

```bash
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: loadbalancer
spec:
  destination:
    name: ''
    namespace: kube-system
    server: 'https://kubernetes.default.svc'
  source:
    path: ''
    repoURL: 'https://aws.github.io/eks-charts'
    targetRevision: 1.7.1
    chart: aws-load-balancer-controller
    helm:
      parameters:
        - name: clusterName
          value: hub-cluster
        - name: ingressClass
          value: elbv2.k8s.aws
  project: default
```

After replacing the YAML content, click the "Save" button followed by the "Create" button to finalize the changes.


::::expand{header="... Or Create Manually"}

#### Create Manually

If you prefer, you can create manually by providing the following specified values.

```
General
Name:  loadbalancer
Project: default

Source
Repository URL: https://aws.github.io/eks-charts
Click on GIT dropdown to select HELM. 
chart: aws-load-balancer-controller
Version: Choose 1.7.1

Destination:
Cuslter URL: https://kubernetes.default.svc
Namespace: kube-system

Select Helm in the dropdown
Helm>PARAMETERS:
clusterName: hub-cluster
IngressClass: elbv2.k8s.aws
```

![argocd-loadBalancer-application](/static/images/lb-application-ui.png)

::::

### 2. Sync Application 

Click "SYNC" and click "SYNCHRONIZE". This will deploy the Load Balancer controller and related objects to the hub cluster. 

![loadBalancer-sync](/static/images/lb-sync.png)

### 3. Validate loadBalancer controller

You can validate the ArgoCD loadbalancer addon created deployment object.

```bash
kubectl get deployment -n kube-system loadbalancer-aws-load-balancer-controller --context hub
```

### 4. Delete loadBalancer controller

For testing, let's delete the loadBalancer controller.

```bash
kubectl delete deployment -n kube-system loadbalancer-aws-load-balancer-controller --context hub
```
ArgoCD flags loadBalancer as "OutOfSync"

![delete-loadBalancer](/static/images/delete-lb.png)

(Optional) If you "Sync" then ArgoCD recreates loadBalancer deployment object, we can see the value of having ArgoCD monitoring our deployed objects and fixing them if needed.

### 5. Delete loadBalancer Application

We prefer not to install things manually and instead want to rely on syncing with a Git repository to properly bootstrap our cluster add-ons. Therefore, let's remove the current add-on for now and reinstall it from Git.

From ArgoCD UI, select loadbalancer application and select Delete. 

### ArgoCD

In this load balancer example, the Git repository we deployed from is https://aws.github.io/eks-charts. This contains the manifests in Helm format, defining the desired state of the load balancer addon.

ArgoCD will continuously monitor the hub cluster to detect any configuration drift from this desired state in Git. If the live state of the hub cluster diverges from the manifests in the Git repo, ArgoCD will automatically alert  notifying of drift.

![argocd-sync](/static/images/argocd-sync.png)

