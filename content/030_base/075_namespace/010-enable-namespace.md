---
title: "Create Namespace"
weight: 10
---

In this chapter, we will create namespaces for the **webstore workload** components: carts, catalog, checkout, orders, rabbitmq, assets, and ui. By the end of this chapter, we will have configured Argo CD so that creating namespaces for a new workload (for example "payment") is as simple as creating a new "payment" folder with the necessary manifests.

### 1. Create Bootstrap namespace applicationset

In the "Kubernetes Addons" chapter, we added a file called "**$GITOPS_DIR/platform/bootstrap/addons-applicationset.yaml**" that monitors the "bootstrap" folder and processes any changes.

![namespace-begin](/static/images/namespace-begin.jpg)

Let's add a namespace applicationset (**addons-applicationset.yaml**) into the bootstrap folder.

![namespace-add-namespace-applicationset](/static/images/namespace-namespace-applicationset.jpg)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='21,33'}
cat > $GITOPS_DIR/platform/bootstrap/namespace-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: namespace
  namespace: argocd
spec:
  syncPolicy:
    preserveResourcesOnDeletion: false
  generators:
    - matrix:
        generators:
          - clusters:
              selector:
                matchLabels:
                  environment: control-plane
          - git:
              repoURL: '{{metadata.annotations.platform_repo_url}}'
              revision: '{{metadata.annotations.platform_repo_revision}}'
              directories:
                - path: '{{metadata.annotations.platform_repo_basepath}}config/workload/*'
  template:
    metadata:
      name: 'namespace-{{path.basename}}'
      labels:
        environment: '{{metadata.labels.environment}}'
        tenant: '{{path.basename}}'
        workloads: 'true'
    spec:
      project: default
      source:
        repoURL: '{{metadata.annotations.platform_repo_url}}'
        path: '{{path}}/namespace'
        targetRevision: '{{metadata.annotations.platform_repo_revision}}'
      destination:
        name: '{{name}}'
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

This ApplicationSet initiates the creation of namespaces for all workloads.

- The Git generator (line 21) iterates through folders under "config/workload" in the gitops-workload repository.
- For each folder (line 33), the ApplicationSet processes files under the "namespace" folder.
- Since there are currently no workload folders under "config/workload/webstore/workload", there are no files to process at this point.

### 2. Git commit

```bash
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap namespace applicationset"
git push
```

On the Argo CD dashboard, click on the bootstrap Application to see the newly created namespace applicationset.

:::alert{header="Sync Application"}
If the new namespace is not visible after a few minutes, we can click on SYNC and SYNCHRONIZE in Argo CD to force synchronization.

We can also do this using the CLI:

```bash
argocd app sync argocd/bootstrap
```

:::

![namespace-helm](/static/images/bootstrap-namespace-applicationset.jpg)
