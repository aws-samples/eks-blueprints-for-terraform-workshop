---
title: "Workload Automation"
weight: 20
---

<!-- cspell:disable-next-line -->

::video{id=WQTL4_zfFBo}

Similar to namespace automation in the previous chapter, the goal of this chapter is to create an Argo CD Application for each workload to manage workload deployment. This is a bootstrap-level application that deploys the manifests found in the `deployment` folder of each workload.

For example, the `create-deployment-workload-a` Argo CD Application will be responsible for deploying the manifests located in the `workload-a/deployment` folder.

![Workload Automation](/static/images/workload-automation.png)

To create an Argo CD Deployment Application for each workload, we will use an ApplicationSet. In an earlier bootstrap chapter, you created an Argo CD Application that continuously watches the `bootstrap/` folder in the platform Git repository. In this chapter, you'll add a Deployment ApplicationSet to that folder.

### 1. Create bootstrap workload applicationset

Create a file called `workload-applicationset.yaml` under the `bootstrap/` folder in the platform Git repository:

![Bootstrap Workload](/static/images/workload-applicationset-bootstrap.png)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='12,22,32'}
cat > $GITOPS_DIR/platform/bootstrap/workload-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: create-deployment
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
                  fleet_member: 'hub'
          - git:
              repoURL: '{{ .metadata.annotations.platform_repo_url }}'
              revision: '{{ .metadata.annotations.platform_repo_revision }}'
              directories:
                - path: '{{ .metadata.annotations.platform_repo_basepath }}config/*/deployment'
  template:
    metadata:
      name: 'create-deployment-{{ index .path.segments 1 }}'
      labels:
        environment: '{{ .metadata.labels.environment }}'
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

This ApplicationSet initiates the creation of deployment-specific Argo CD Applications for all workloads.

- **Line 12**: The matrix generator creates permutations by combining the outputs of its inner generators (git and cluster).
- **Line 22**: The Git generator iterates through each folder under `config/*/deployment` in the platform Git repository.
- **Line 35**: `{{ .path.path }}` maps to each namespace folder path under `config/*/deployment`.
  - For example, for `workload-a`, the path will be `config/workload-a/deployment`.
  - If no folders are present under `config/*`, there will be no applications created yet.

### 2. Git commit

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap workload applicationset"
git push
:::
<!-- prettier-ignore-end -->

:::alert{header=Note type=warning}
The 'create-deployment' applicationset will become visible after a few minutes.
:::

As the **bootstrap** folder is monitored, when a new file like **workload-applicationset.yaml** is added, it gets processed.

![workload-appofapps-monitor](/static/images/workload-appofapps-monitor.png)
