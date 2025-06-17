---
title: "Automate Webstore Deployment"
weight: 10
---

In this chapter, you will automate Webstore workload deployment.

Building on the automation in the 'Namespace and Workload Automation'>'workload Automation' chapter, we'll now apply it to the webstore workload. Specifically, we’ll add a new folder at config/webstore/deployment in the platform Git repository. When this folder and its manifest are pushed to Git, the existing create-deployment ApplicationSet will:

![Webstore Workload Deployment](/static/images/deployment-webstore-applicationset.png)

1. The create-deployment ApplicationSet detects the config/webstore/deployment folder.
2. It creates a new Argo CD Application named create-deployment-webstore.
3. This Application deploys manifests in config/webstore/deployment

# Automate Dev Webstore Deployment

### 1. Create Dev Deployment ApplicationSet

Let's create an ApplicationSet that is responsible for deploying dev webstore workload.


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
              requeueAfterSeconds: 30
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

Webstore folder structure.

![Webstore Workload Folders](/static/images/webstore-workload-folders.png)

Webstore workload has
* 6 microservices( assets, carts, catalog, checkout, orders, ui)
* Each microservice has 
  - base: directory holds the common configuration that applies to all    environments.
  - environment specfic directories(dev,staging,prod) hold environment specific configurations, allowing for easy overide and customization
* To deploy webstore dev version, you have to deploy all microservices kstomization.yaml in dev folder

### 2. Git commit

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap workload applicationset"
git push
:::
<!-- prettier-ignore-end -->

### 3. Validate deployment

<!-- :::alert{header="Sync Application"}
If the new create-deployment-webstore is not visible after a few minutes, you can click on SYNC and SYNCHRONIZE in Argo CD to force it to synchronize.

Or you can do it also with cli:

:::code{showCopyAction=true showLineNumbers=false language=yaml }
argocd app sync argocd/bootstrap
::: -->

:::alert{header=Note type=warning}
The 'create-deployment-webstore' application will become visible after a few minutes. 
:::

You can navigate to the ArgoCD dashboard> Applications> bootstrap to see Workload specific ArgoCD application i.e. create-deployment-webstore.

![Create Deployment Webstore](/static/images/create-deployment-webstore.png)

If you click on create-deployment-webstore then you will see dev specific ArgoCD Application i.e create-deployment-dev-webstore. This is the application you added in this chapter. This applictionset is ready to create ArgoCD Application for workload/webstore/*/dev folders. It has not deployed any application as there is no code in the application repository yet.

![Webstore Workload Folders](/static/images/create-deployment-dev-webstore.png)

# Automate Prod and Staging Webstore Deployment

### 1. Onboard staging and prod 

Let's also create configuration to deploy staging and production as well.

:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='17,22,25,39,42'}
sed -e 's/dev/staging/g' < ${GITOPS_DIR}/platform/config/webstore/deployment/deployment-dev-webstore-applicationset.yaml > ${GITOPS_DIR}/platform/config/webstore/deployment/deployment-staging-webstore-applicationset.yaml
sed -e 's/dev/prod/g' < ${GITOPS_DIR}/platform/config/webstore/deployment/deployment-dev-webstore-applicationset.yaml > ${GITOPS_DIR}/platform/config/webstore/deployment/deployment-prod-webstore-applicationset.yaml
:::

### 2. Git commit

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap workload applicationset"
git push
:::
<!-- prettier-ignore-end -->


<!-- :::alert{header="Sync Application"}
If the new deployment and prod are not visible after a few minutes, you can click on SYNC and SYNCHRONIZE in Argo CD to force it to synchronize.

Or you can do it also with cli:


:::code{showCopyAction=true showLineNumbers=false language=yaml }
argocd app sync argocd/create-deployment-webstore
::: -->

:::alert{header=Note type=warning}
The 'staging' and 'production' applications will become visible after a few minutes. 
:::


![Webstore Workload Folders](/static/images/create-deployment-allenv-webstore.png)
