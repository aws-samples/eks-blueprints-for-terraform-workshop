---
title: "Namespace automation"
weight: 10
---

In an earlier bootstrap chapter, you created an Argo CD Application that continuously watches the `bootstrap/` folder in the platform Git repository. In this chapter, you'll add a Namespace ApplicationSet to that folder. This will automate the creation of namespaces for each workload using a Helm chart.


### 1. Create Bootstrap namespace applicationset

![Bootstrap Namespace](/static/images/namespace-applicationset-bootstrap.png)

Add  `namespace-applicationset.yaml` to the `bootstrap/` folder in the platform Git repository:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='22,35'}
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

This ApplicationSet initiates the creation of namespaces for all the workloads.


- Line 22: The Git generator iterates through folder for each workload under "config/*/namespace" in the platform git repository
- Line 32: `{.path.path}` maps to each deployment folder under `config/*/namespace`
  - For `worload-a`, `{path.path}` maps to `config/workload-a/namespace`
  - Since there is no folder "config/*", there are currently no files to process


![Namespace Automation](/static/images/namespace-automation.png)

### 2. Git commit

```bash
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap namespace applicationset"
git push
```

On the Argo CD dashboard click on bootstrap Application to see newly created namespace applicationset.

:::alert{header="Sync Application"}
If the new namespace is not visible after a few minutes, you can click on SYNC and SYNCHRONIZE in Argo CD to force it to synchronize.

Or you can do it also with cli:

```bash
argocd app sync argocd/bootstrap
```

:::

![namespace-helm](/static/images/bootstrap-namespace-applicationset.png)

