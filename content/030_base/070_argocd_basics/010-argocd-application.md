---
title: "Application"
weight: 10
---

### 1. Create Application Defination

An ArgoCD **Application** is a special Kubernetes object(CRD) that tells ArgoCD what to deploy from Git and where to deploy it. It keeps checking the actual state in your cluster and automatically syncs it to match what’s in Git.

![ArgoCD Application](/static/images/argocd-application.png)

In this step, you'll deploy an ArgoCD Application. Each Application must specify:

* Source: the Git repository containing the manifests.
* Destination: the target Kubernetes cluster and namespace.

In the example below, the source is the ArgoCD example Git repository(line 12), and path is guestbook(line 13).

![ArgoCD Application](/static/images/guestbook.png)

The destination is the hub-cluster(line 16)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='13,14,16,17'}
mkdir -p ~/environment/basics
cd ~/environment/basics
cat <<'EOF' >> ~/environment/basics/guestbook.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  # Source of the application manifests
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git 
    path: guestbook
  destination:
    name: hub-cluster
    namespace: guestbook   
  syncPolicy:
    automated: 
      prune: true
EOF
:::
<!-- prettier-ignore-end -->
### 2. Apply the Application

When you apply this manifest:

* ArgoCD creates an Application object.
* ArgoCD syncs and deploys the resources (Deployment, Service, Pods) to the hub-cluster.

```bash
kubectl create ns guestbook
kubectl apply -f ~/environment/basics/guestbook.yaml
```

### 3. Verify the Application

Navigate to the ArgoCD web UI. You should see the guestbook application listed.

![ArgoCD Application Dashboard](/static/images/guestbook-ui.png)

You can check resources created by the Application(svc,deployment, replicaset, pods)

```bash
kubectl get all -n guestbook
```

### 4. Clean Up
Use ArgoCD CLI to delete the application and its managed resources.

```bash
argocd app delete guestbook --cascade -y
kubectl delete ns guestbook

```