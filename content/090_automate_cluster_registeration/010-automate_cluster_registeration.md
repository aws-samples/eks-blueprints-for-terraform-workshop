---
title: "Automate Cluster Registration"
weight: 10
---

Cluster registration in ArgoCD involves providing the EKS API Server ARN via Kubernetes Secrets. ArgoCD uses these secrets to manage and deploy applications to target clusters.

In the previous "ArgoCD Basics/Register Cluster" chapter, we manually registered hub cluster using a one-time kubectl command. In this chapter, we transition to a GitOps-driven approach. By defining cluster metadata in Git, Argo CD will automatically detect and register new clusters as they are added to the repository. We will start by "re-registering" our Hub cluster so that its definition is fully managed by our Git source of truth

### How it works

We use a Helm chart( argocd-register-cluster) to package the Kubernetes secret manifest required for cluster registration. To manage multiple clusters, we organize our Git repository under the register-cluster folder.

![Register Cluster Folders](/static/images/register-cluster/register-cluster-folder.png)

- Each cluster has its own sub-directory (e.g., /hub, /dev).
- Each sub-directory contains a values.yaml specific to that cluster

The helm chart values for hub-cluster will have all values required to create the Kubernetes secrets like server ARN and optional labels and annotations.

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml }
serverARN: <<hub cluster arn>>
labels:
  cluster-role: hub
annotations:
  platform_url: <<platform_url>>
  oci_registry_url: <<oci_registry_url>>
  retail_store_config_url: <<retail_store_config_url>>
:::
<!-- prettier-ignore-end -->

We will use an ApplicationSet that will "scan" our Git folders and dynamically generate an Argo CD Application for every cluster it finds.

Let's review register-cluster ApplicationSet.

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=true language=yaml highlightLines='14,16,19,27,28,29,35' }
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: register-cluster
  namespace: argocd
spec:
  goTemplate: true
  generators:
  - matrix:
      generators:
      - clusters:
          selector:
            matchLabels:
              cluster-role: hub
      - git:
          repoURL: '{{ .metadata.annotations.platform_url }}'
          revision: HEAD
          directories:
          - path: register-cluster/*
  template:
    metadata:
      name: 'register-cluster-{{ .path.basename }}'
      namespace: argocd
    spec:
      project: default
      sources:
      - repoURL: '{{ .metadata.annotations.oci_registry_url }}/platform'
        chart: argocd-cluster-secret
        targetRevision: 0.1.0
        helm:
          parameters:
          - name: clusterName
            value: '{{ .path.basename }}'
          valueFiles:        
          - $values/{{.path.path}}/values.yaml
      - repoURL: '{{ .metadata.annotations.platform_url }}'
        targetRevision: HEAD
        ref: values
      destination:
        name: '{{ .name }}'
        namespace: argocd
      syncPolicy:
        automated:
          enabled: true
:::
<!-- prettier-ignore-end -->

Key Components:
- Line 14: Uses a Cluster Generator to target clusters labeled cluster-role: hub
- Line 16: Uses the platform URL defined in the Hub cluster's annotations
- Line 19: Select all folders under register-cluster
- Line 27: Repo pointing to ECR/platform
- Line 28: Deploy helm chart argocd-cluster-secret
- Line 29: Helm Chart version
- Line 35: Pick up cluster specific values. For example, dev will be under /register-cluster/dev/values.yaml



### 1. Automate Cluster registration
<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
# Copy register Cluster
cp $WORKSHOP_DIR/gitops/templates/bootstrap/register-cluster.yaml $GITOPS_DIR/platform/bootstrap

# Copy hub cluster values
mkdir -p $GITOPS_DIR/platform/register-cluster/hub
cp $WORKSHOP_DIR/gitops/templates/register-cluster/hub-register-cluster-values.yaml $GITOPS_DIR/platform/register-cluster/hub/values.yaml
cd $GITOPS_DIR/platform
git add .
git commit -m "add hub cluster registration values"
git push 
:::
<!-- prettier-ignore-end -->

### 2. Validate Cluster registration

Navigate to ArgoCD dashboard to validate cluster registration

![Register Cluster Hub Dashboard](/static/images/register-cluster/register-cluster-hub-dashboard.png)
