---
title: "Namespace Automation"
weight: 10
---

<!-- cspell:disable-next-line -->

::video{id=\_TdKzq1jXhM}

The goal of this chapter is to create an Argo CD Application for each workload to manage namespace creation. This is a bootstrap-level application that deploys the manifests found in the `namespace` folder of each workload.

For example, the `create-namespace-workload-a` Argo CD Application will be responsible for deploying the manifests located in the `workload-a/namespace` folder.

![Namespace Automation](/static/images/namespace-automation.png)

To create an Argo CD namespace Application for each workload, we will use an ApplicationSet. In an earlier bootstrap chapter, you created an Argo CD Application that continuously watches the `bootstrap/` folder in the platform Git repository. In this chapter, you'll add a namespace ApplicationSet to that folder.

![Bootstrap Namespace](/static/images/namespace-applicationset-bootstrap.png)

### 1. Create Bootstrap namespace applicationset

Create a file called `namespace-applicationset.yaml` under the `bootstrap/` folder in the platform Git repository:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='12,22,35'}
cat > $GITOPS_DIR/platform/bootstrap/namespace-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: create-namespace
  namespace: argocd
spec:
  goTemplate: true
  syncPolicy:
    preserveResourcesOnDeletion: false
  generators:
    - matrix:
        generators:
          - clusters:
              selector:
                matchLabels:
                  fleet_member: hub
          - git:
              repoURL: '{{ .metadata.annotations.platform_repo_url }}'
              revision: '{{ .metadata.annotations.platform_repo_revision }}'
              directories:
                - path: 'config/*/namespace'
  template:
    metadata:
      name: 'create-namespace-{{ index .path.segments 1 }}'
      labels:
        environment: '{{ .metadata.labels.environment }}'
        tenant: '{{ index .path.segments 1 }}'
        workloads: 'true'
        
    spec:
      project: default
      source:
        repoURL: '{{ .metadata.annotations.platform_repo_url }}'
        path: '{{ .path.path }}'
        targetRevision: '{{ .metadata.annotations.platform_repo_revision }}'
      destination:
        name: '{{ .name }}'
      syncPolicy:
        automated:
          allowEmpty: true
        retry:
          backoff:
            duration: 1m
            #limit: 100
        syncOptions:
          - CreateNamespace=true
EOF
:::
<!-- prettier-ignore-end -->

This ApplicationSet initiates the creation of namespace-specific Argo CD Applications for all workloads.

- **Line 12**: The matrix generator creates permutations by combining the outputs of its inner generators (git and cluster).
- **Line 22**: The Git generator iterates through each folder under `config/*/namespace` in the platform Git repository.
- **Line 35**: `{{ .path.path }}` maps to each namespace folder path under `config/*/namespace`.
  - For example, for `workload-a`, the path will be `config/workload-a/namespace`.
  - If no folders are present under `config/*`, there will be no applications created yet.

### 2. Git commit

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap namespace applicationset"
git push
:::
<!-- prettier-ignore-end -->

After pushing, navigate to the Argo CD dashboard and open the bootstrap application. You should see the newly created create-namespace ApplicationSet.

:::alert{header=Note type=warning}
The 'create-namespace' applicationset will become visible after a few minutes.
:::

![namespace-helm](/static/images/bootstrap-namespace-applicationset.png)
