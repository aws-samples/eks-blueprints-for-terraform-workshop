---
title: "Automate Team Registration"
weight: 10
---

<!-- cspell:disable-next-line -->

::video{id=d2C7FR6i7G0}

Team registration involves creating namespaces, ArgoCD projects, and deploying applications to clusters. In this chapter, we will automate this process by managing team configurations through Git.

### How it works

We use a Helm chart( team) to package applicationsets that create namespace, ArgoCD project and deployment applications. To manage multiple teams, we organize our Git repository under the register-team folder.

![Register Cluster Folders](/static/images/register-team/register-team-folder.png)

- Each team has its own sub-directory (e.g., /retail-store)
- Each sub-directory contains namespace,project,environments values specific to that team.

<!-- The enviornments.yaml is passed as values for the team helm chart.  -->

<!-- prettier-ignore-start -->
<!-- :::code{showCopyAction=false showLineNumbers=true language=yaml }
repo: <<url of the repo that contains values for each microservice(retail-store-config)>>
environments:
  - env: dev
    cluster: dev
    versions:
      cart: "1.3.0"
      checkout: "1.3.0"
      catalog: "1.3.0"
      ui: "1.3.0"
      orders: "1.3.0"
::: -->
<!-- prettier-ignore-end -->

<!-- Key Components:
- Line 1: url of the repo that contains values for each microservice(retail-store-config)
- Line 2: Environment dev configuration to follow
- Line 3: dev environment is targeted to dev eks cluster
- Line 5-9: Version of microservice helm chart -->

We will use an ApplicationSet that will "scan" our Git folders and dynamically generate an Argo CD Application for every team it finds.

Let's review register-team ApplicationSet.

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=true language=yaml highlightLines='14,16,19,27,28,29,35' }
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: register-team
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
          - path: register-team/*
  template:
    metadata:
      name: 'team-{{ .path.basename }}'
      namespace: argocd
    spec:
      project: default
      sources:
      - repoURL: '{{ .metadata.annotations.oci_registry_url }}/platform'
        chart: team
        targetRevision: 1.0.0
        helm:
          parameters:
          - name: teamName
            value: '{{ .path.basename }}'
          valueFiles:
          - $values/register-team/{{ .path.basename }}/environments.yaml          
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
- Line 19: Select all folders under register-team
- Line 27: Repo pointing to ECR/platform
- Line 28: Deploy helm chart team
- Line 29: Helm Chart version
- Line 35: Pick up team specific values in environments.yaml

### 1. Automate Cluster registration

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
# Copy register Cluster
cp $WORKSHOP_DIR/gitops/templates/bootstrap/register-team.yaml $GITOPS_DIR/platform/bootstrap

cd $GITOPS_DIR/platform
git add .
git commit -m " automate team registration"
git push 
:::
<!-- prettier-ignore-end -->

### 2. Validate Cluster registration

Navigate to ArgoCD dashboard to validate register-team application

![Register Team Dashboard](/static/images/register-team/register-team-dashboard.png)
