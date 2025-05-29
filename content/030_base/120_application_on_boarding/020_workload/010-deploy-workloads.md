---
title: "Automate Webstore Deployment"
weight: 10
---

To automate Webstore workload, we have to understand folder structure.

![Webstore Workload Folders](/static/images/webstore-workload-folders.png)

Webstore workload has
* 6 microservices( assets, carts, catalog, checkout, orders, ui)
* Each microservice has 
  - base: directory holds the common configuration that applies to all    environments.
  - environment specfic directories(dev,staging,prod) hold environment specific configurations, allowing for easy overide and customization
* To deploy webstore dev version, you have to deploy all microservices kstomization.yaml in dev folder

### 1. Automate dev webstore workload deployment

In "Namespace And Workload" automation, we have already created create-deployment application that continuously scans and process mainfests under config/*/deployment folder in platform repo.

Let's create an ApplicationSet that is responsible for deploying dev webstore workload.

![Webstore Workload Deployment](/static/images/deployment-webstore-applicationset.png)


<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='17,27,30'}
mkdir -p $GITOPS_DIR/platform/config/webstore/deployment
cat > $GITOPS_DIR/platform/config/webstore/deployment/deployment-dev-webstore-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: create-deployment-dev-webstore
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
                matchExpressions:
                  - key: workload_webstore
                    operator: In
                    values: ['true']
                  - key: environment
                    operator: In
                    values: ['dev']                  
              values:
                workload: webstore
          - git:
              repoURL: '{{ .metadata.annotations.workload_repo_url }}'
              revision: '{{ .metadata.annotations.workload_repo_revision }}'
              directories:
                - path: '{{ .metadata.annotations.workload_repo_basepath }}webstore/*/dev'
  template:
    metadata:
      name: 'deployment-{{ .metadata.labels.environment }}-{{ index .path.segments 1 }}-webstore'
      labels:
        environment: '{{ .metadata.labels.environment }}'
        tenant: 'webstore'
        component: '{{ index .path.segments 1 }}'
        workloads: 'true'
    spec:
      project: default
      source:
        repoURL: '{{ .metadata.annotations.workload_repo_url }}'
        path: '{{ .path.path }}'
        targetRevision: '{{ .metadata.annotations.workload_repo_revision }}'
      destination:
        namespace: '{{ index .path.segments 1 }}'
        name: '{{ .name }}'
      syncPolicy:
        automated:
          allowEmpty: true
          prune: true
        retry:
          backoff:
            duration: 1m


EOF
:::
<!-- prettier-ignore-end -->

- Line 17: The **webstore** workload is only deployed on clusters with the label **workload_webstore = true** and **environment = dev**
- Line 27: **metadata.annotations.workload_repo_url** i.e workload_repo_url annotation on the hub cluster has the value of the workload git repository
- Line 30: Maps to **webstore/*/dev** ( each microservices dev folder under webstore )

### 2. Git commit

```bash
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap workload applicationset"
git push
```
![c]
argocd app sync argocd/bootstrap

### 3. Accelerate Argo CD sync

```bash
argocd app sync argocd/bootstrap
```
:::alert{header=Note type=warning}
It can take few minutes for minutes to show create-deployment-webstore applicaion.
Refresh the browser.
:::

![Create Deployment Webstore](/static/images/create-deployment-webstore.png)

![Webstore Workload Folders](/static/images/create-deployment-dev-webstore.png)

### 4. Onboard staging and prod 

Let's also create configuration to deploy staging and production as well.

:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='17,22,25,39,42'}
sed -e 's/dev/staging/g' < ${GITOPS_DIR}/platform/config/webstore/deployment/deployment-dev-webstore-applicationset.yaml > ${GITOPS_DIR}/platform/config/webstore/deployment/deployment-staging-webstore-applicationset.yaml
sed -e 's/dev/prod/g' < ${GITOPS_DIR}/platform/config/webstore/deployment/deployment-dev-webstore-applicationset.yaml > ${GITOPS_DIR}/platform/config/webstore/deployment/deployment-prod-webstore-applicationset.yaml
:::

### 5. Git commit

```bash
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap workload applicationset"
git push
```

:::alert{header="Sync Application"}
If the new deployment and prod are not visible after a few minutes, you can click on SYNC and SYNCHRONIZE in Argo CD to force it to synchronize.

Or you can do it also with cli:

```bash
argocd app sync argocd/create-deployment-webstore
```

:::



![Webstore Workload Folders](/static/images/create-deployment-allenv-webstore.png)
