---
title: "App of Apps Pattern"
weight: 30
---

::video{id=UGRG-jW7Pfk}

**There is no lab in this chapter, but the App of Apps pattern is extensively used throughout the workshop.**

### Background

In real-world organizations, deploying an application involves multiple teams. Let's categorize them broadly:

- ![Developers](/static/images/developer-task.png) **Developers**: Responsible for application code and Kubernetes manifests for their workload.
- ![Platform](/static/images/platform-task.png) **Platform Team**: Responsible for infrastructure (VPC, clusters, addons), namespace creation (quotas, limits, policies), and automating workload deployments.

To enable clear separation of responsibilities and automation, ArgoCD users often adopt the App of Apps pattern.

### What is the App of Apps Pattern?

Normally, an ArgoCD Application is used to deploy Kubernetes manifests.
For example, in earlier chapters, you saw how a guestbook Application deployed Deployment and Service resources directly to the hub-cluster.

![App of Apps Guestbook](/static/images/appofapps-guestbook.png)

The **App of Apps** pattern in ArgoCD is a strategy where a single *parent* `Application` deploys multiple *child* `Applications/ApplicationSets`. For example, the webstore parent Application deploys Applications for the ui, assets, carts microservices.

![App of Apps Webstore](/static/images/appofapps-webstore-concept.png)


Let’s walk through how the **webstore** workload can be deployed using this pattern.

![Webstore](/static/images/webstore.png)

The *webstore* consists of multiple microservices like `ui`, `orders`, `checkout`, `carts`, `catalog`, and `assets`.


### Developer Repository Layout

Developers organize their code and manifests using a modular structure. Each microservice is a folder under `webstore/`:

![Webstore Repo](/static/images/appofapps-webstore-repo.png)


### Platform Onboarding Webstore Workload

![Platform](/static/images/platform-task.png) The platform team onboards the *webstore* workload by creating a `deploy-webstore.yaml` file in the `workload/` folder of the platform repository. This file defines an `ApplicationSet` that deploys all webstore microservices.

![Webstore AppSet](/static/images/appofapps-webstore-appset.png)

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=true language=yaml highlightLines='10-11,13-14d,21,23,25,26'}
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: webstore-applications
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
    - git:
        repoURL: https://<developer-repo-url>
        revision: HEAD
        directories:
          - path: webstore/*
  template:
    metadata:
      name: '{{.path.basename}}'
    spec:
      project: default
      source:
        repoURL: https://<developer-repo-url>
        targetRevision: HEAD
        path: '{{.path.path}}'
      destination:
        name: hub-cluster
        namespace: '{{.path.basename}}'
      syncPolicy:
        automated: {}
:::
<!-- prettier-ignore-end -->

#### Generator
- **Line 10**: Uses the [Git generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Git/) to dynamically detect directories.
- **Lines 13–14**: Traverses all subdirectories under `webstore/`.

The Git generator scans the webstore/ directory in the developer repo and finds six subfolders—one for each microservice (ui, orders, checkout, carts, catalog, assets).
This results in six generator values, and for each value, ArgoCD creates a child Application using the template section.

#### Template
- **Line 21**: Points to the developer Git repo.
- **Line 22**: `{{.path.path}}` resolves to paths like `webstore/ui`, `webstore/orders`.
- **Line 25**: Deploys to `hub-cluster`.
- **Line 26**: `{{.path.basename}}` gives the namespace microservice name like ui, carts etc.

This `ApplicationSet` creates one Argo CD Application for each microservice.

![Deploy Webstore](/static/images/appofapps-deploy-webstore-appset.png)



### Root Application 

To enable the App of Apps pattern, the platform team creates a *root* Argo CD Application that deploys the above `ApplicationSet`.

![Webstore AppSet](/static/images/appofapps-root.png)


<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=true language=yaml highlightLines='9-10'}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: webstore-root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://<platform-repo-url>
    path: workload
    targetRevision: HEAD
  destination:
    name: hub-cluster
    namespace: argocd
  syncPolicy:
    automated: {}
:::
<!-- prettier-ignore-end -->

- **Line 9**: Repo URL points to the platform repo.
- **Line 10**: Syncs all manifests under the `workload/` folder ( `deploy-webstore.yaml`).

### Diagram: How It Works

![App of Apps Flow](/static/images/webstore-appofapps-argocd.png)

- Root Application (`webstore-root`) syncs the `workload` folder.
- This triggers the `ApplicationSet` (`deploy-webstore`) to generate one Argo CD `Application` per microservice.


### Benefits of the App of Apps Pattern

- 🔄 **Automation**: Root app deploys `ApplicationSet`, which deploys all microservices.  
To onboard a new workload, the platform team simply adds a new ApplicationSet in the workload folder of the platform Git repository.
- 👥 **Separation of Responsibilities**:
  - Platform team defines structure and environment policies.
  - Developers own their service manifests.

