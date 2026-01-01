---
title: "Automate Cluster Registration"
weight: 10
---

<!-- cspell:disable-next-line -->

::video{id=Oclo78ladi8}

ArgoCD manages and deploys applications on clusters. To do this, it needs cluster connection information. This information is provided through Kubernetes secrets. When these secrets with the proper labels, they automatically appear as available clusters under Settings > Clusters in the ArgoCD dashboard. In this chapter, we will automate cluster registration by managing this metadata through Git.

In the "ArgoCD Basics/Register Cluster" chapter, we manually registered hub cluster using a one-time kubectl command. In this chapter, we transition to a GitOps-driven approach. We will test this automation by automatically registering the hub cluster through automation.

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

We'll deploy the register-cluster ApplicationSet to the bootstrap folder. The bootstrap ApplicationSet (created in the previous chapter) monitors this folder and will immediately deploy the new ApplicationSet, creating our cluster registration automation engine.

This ApplicationSet will then scan the register-cluster/ folder for cluster configuration files and automatically register any clusters it finds.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
# Copy register Cluster
cp $WORKSHOP_DIR/gitops/templates/bootstrap/register-cluster.yaml $GITOPS_DIR/platform/bootstrap
cd $GITOPS_DIR/platform
git add .
git commit -m "add cluster registration automation"
git push 
:::
<!-- prettier-ignore-end -->

### 2. Validate ApplicationSet Creation

Navigate to the ArgoCD dashboard to verify that our cluster registration automation has been deployed successfully.

1. Go to Applications view in ArgoCD dashboard
2. Click on the bootstrap Application
3. You will see newly created register-cluster ApplicationSet

::alert[You may need to refresh the ArgoCD dashboard to see newly created applications and resources]{header=Tip}

![Register Cluster Folders](/static/images/register-cluster/register-cluster-appset-dashboard.png)

In the next step, we'll add a cluster configuration to trigger the automation.

### 3. Add hub cluster values

Now we'll add hub cluster configuration to trigger our automation and demonstrate how it works.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }

# Copy hub cluster values
mkdir -p $GITOPS_DIR/platform/register-cluster/hub
cp $WORKSHOP_DIR/gitops/templates/register-cluster/hub-register-cluster-values.yaml $GITOPS_DIR/platform/register-cluster/hub/values.yaml
cd $GITOPS_DIR/platform
git add .
git commit -m "add hub cluster registration values"
git push 
:::
<!-- prettier-ignore-end -->

The register-cluster ApplicationSet will detect the new `/hub` folder and automatically create a `register-cluster-hub` Application to deploy the cluster secret.

### 4. Validate Cluster registration

Navigate to ArgoCD dashboard to see the automation in action.

1. Go to Applications view in ArgoCD dashboard
2. Click on the bootstrap Application. You should see register-cluster ApplicationSet now has newly created register-cluster-hub application.
3. Hub cluster appears in Settings > Clusters (re-registered via GitOps)

![Register Cluster Hub Dashboard](/static/images/register-cluster/register-cluster-hub-dashboard.png)
