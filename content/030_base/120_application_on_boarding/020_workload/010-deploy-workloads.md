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
cat > $GITOPS_DIR/platform/config/webstore/deployment/deployment-webstore-applicationset.yaml << 'EOF'
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

### 4. Git commit

```bash
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap workload applicationset"
git push
```

### 5. Accelerate Argo CD sync

```bash
argocd app sync argocd/workload-webstore
```

![workload-webstore](/static/images/workload_webstore.jpg)

### 6. Validate workload

:::alert{header="Important" type="warning"}
It takes a few minutes to deploy the workload and create a loadbalancer
:::

```bash
app_url_hub
```

Access the webstore in the browser.

![webstore](/static/images/webstore-ui.png)

### 7. Create 

Let's also create configuration to deploy staging and production as well.

:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='17,22,25,39,42'}
sed -e 's/dev/staging/g' < ${GITOPS_DIR}/platform/config/webstore/deployment/webstore-dev-applicationset.yaml > ${GITOPS_DIR}/platform/config/webstore/deployment/webstore-staging-applicationset.yaml
sed -e 's/dev/prod/g' < ${GITOPS_DIR}/platform/config/webstore/deployment/webstore-dev-applicationset.yaml > ${GITOPS_DIR}/platform/config/webstore/deployment/webstore-prod-applicationset.yaml
:::

### 4. Git commit

```bash
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap workload applicationset"
git push
```