---
title: "Workload Automation"
weight: 10
---

In an earlier bootstrap chapter, you created an Argo CD Application that continuously watches the bootstrap/ folder in the platform Git repository. In this chapter, you'll add a Workload ApplicationSet to that folder. This will automate the deployment of workloads.


### 1. Create bootstrap workload applicationset

![Bootstrap Workload](/static/images/workload-applicationset-bootstrap.png)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='22,32'}
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

- Line 22: The Git generator iterates through folder for each workload under "config/*/deployment" in the platform git repository
- Line 32: `{.path.path}` maps to each deployment folder under `config/*/deployment`
  - For `worload-a`, `{path.path}` maps to `config/workload-a/deployment`
  - Since there is no folder "config/*", there are currently no files to process

![Workload Automation](/static/images/workload-automation.png)

### 2. Git commit

```bash
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap workload applicationset"
git push
```

As the **bootstrap** folder is monitored, when a new file like **workload-applicationset.yaml** is added, it gets processed.

![workload-appofapps-monitor](/static/images/workload-appofapps-monitor.png)

