---
title: "Application"
weight: 30
---

<!-- cspell:disable-next-line -->

::video{id=a-RCoZL5XTo}

In ArgoCD an application is a custom Kubernetes resource (CRD) that declaratively defines how a set of manifests from a Git repository should be deployed to a target Kubernetes cluster

### 1. Create guestbook Application

In this section you will create a guestbook ArgoCD Application. This Application will deploy kubernetes manifest from argoproj/argocd-example-apps repo on github to the hub cluster.

![ArgoCD Application Guestbook Architecture](/static/images/argobasics/guestbook-ui-architecture.png)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='13,14,16'}
cat <<'EOF' >> ~/environment/basics/guestbook.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook-hub
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  # Source of the application manifests
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    path: guestbook
  destination:
    name: hub
    namespace: default
  syncPolicy:
    automated: 
      prune: true
EOF
kubectl apply -f ~/environment/basics/guestbook.yaml
:::
<!-- prettier-ignore-end -->

Key Components:

- Line 16: Destination is hub. This cluster was registered in "Register Cluster" chapter
- Line 13: argoproj/argocd-example-apps repo on github
- Line 14: "guestbook" folder in the repo.

![ArgoCD Application Guestbook GitHub](/static/images/argobasics//github-guestbook.png)

### 2. Verify the Application

Navigate to the ArgoCD Dashboard. You should see the guestbook application listed.

![ArgoCD Application Guestbook](/static/images/argobasics//guestbook-ui.png)

You can click on the guestbook to see all the resources created by the guestbook Application.

You can check resources created by the Application(svc,deployment, replicaset, pods)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
kubectl get all -n default
:::
<!-- prettier-ignore-end -->

### 3. Clean Up

Delete the application and its managed resources.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
kubectl delete -f ~/environment/basics/guestbook.yaml
:::
<!-- prettier-ignore-end -->
