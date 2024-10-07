---
title: "Argo CD Project"
weight: 10
---

Projects define guardrails that set constraints for associated applications. When an application is associated with a project, it must operate within the guardrails established by that project.

In this chapter we will create a project for the webstore workload. In upcoming chapters, we will associate the webstore workload deployment with this project.

### 1. Create App of Apps Project ApplicationSet

Create an applicationset that creates Argo CD project for each workload.

![Project AppofApps](/static/images/project-applicationset.jpg)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='16,20,25,44,46,47'}
cat > $GITOPS_DIR/platform/bootstrap/argoproject-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: argoprojects
  namespace: argocd
spec:
  syncPolicy:
    preserveResourcesOnDeletion: true
  generators:
    - matrix:
        generators:
          - clusters:
              selector:
                matchLabels:
                  environment: hub
              values:
                addonChart: argocd-apps
                addonChartVersion: '1.4.1'
                addonChartRepository: https://argoproj.github.io/argo-helm
          - git:
              repoURL: '{{metadata.annotations.platform_repo_url}}'
              revision: '{{metadata.annotations.platform_repo_revision}}'
              directories:
                - path: '{{metadata.annotations.platform_repo_basepath}}config/workload/*'
  template:
    metadata:
      name: 'argoprojects-{{path.basename}}'
      labels:
        environment: '{{metadata.labels.environment}}'
        team: '{{path.basename}}'
    spec:
      project: default
      sources:
        - repoURL: '{{metadata.annotations.platform_repo_url}}'
          targetRevision: '{{metadata.annotations.platform_repo_revision}}'
          ref: values
        - chart: '{{values.addonChart}}'
          repoURL: '{{values.addonChartRepository}}'
          targetRevision: '{{values.addonChartVersion}}'
      helm:
        releaseName: 'argoprojects-{{path.basename}}'
        valueFiles:
          - '$values/{{metadata.annotations.platform_repo_basepath}}config/workload/{{path.basename}}/project/project-values.yaml'
        parameters:
          - name: "projects[0].sourceRepos[0]"
            value: '{{metadata.annotations.workload_repo_url}}'
      destination:
        name: '{{name}}'
      syncPolicy:
        automated:
          allowEmpty: true
        retry:
          backoff:
            duration: 1m
            limit: 100
        syncOptions:
          - CreateNamespace=true
EOF
:::
<!-- prettier-ignore-end -->

- Line 16: Projects are installed on the hub cluster and not on the spoke clusters.
- Line 20: Argo CD projects are created with a helm chart. Installs the project helm chart from `argoproject`.
- Line 25: Iterates through all the workload folders under config/workload folder
- Line 44: project values for each workload.
- Line 46,47: Replace sourceRepos value with the git workload url (See Line 7 below in the project-values.yaml)

### 2. Create Project Values

Lets create webstore project values.

![project-values](/static/images/project-values.jpg)

The following helm values file contains source repositories, destinations, and allowed resources for the webstore workload. Few values are commented for the upcoming chapters.

:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='7,12,39,47'}
mkdir -p $GITOPS_DIR/platform/config/workload/webstore/project
cat > $GITOPS_DIR/platform/config/workload/webstore/project/project-values.yaml << 'EOF'

# using upstream argo chart https://github.com/argoproj/argo-helm/tree/main/charts/argocd-apps

projects:

- name: webstore
  sourceRepos:

  - 'ApplicationSet will replace this with the workload url'
    namespace: argocd
    additionalLabels: {}
    additionalAnnotations: {}
    description: Team Project
    destinations:
  - namespace: carts
    name: spoke-staging
  - namespace: catalog
    name: spoke-staging
  - namespace: checkout
    name: spoke-staging
  - namespace: orders
    name: spoke-staging
  - namespace: rabbitmq
    name: spoke-staging
  - namespace: ui
    name: spoke-staging
  - namespace: assets
    name: spoke-staging  
    #enablespokeprod - namespace: carts
    #enablespokeprod name: spoke-prod
    #enablespokeprod - namespace: catalog
    #enablespokeprod name: spoke-prod
    #enablespokeprod - namespace: checkout
    #enablespokeprod name: spoke-prod
    #enablespokeprod - namespace: orders
    #enablespokeprod name: spoke-prod
    #enablespokeprod - namespace: rabbitmq
    #enablespokeprod name: spoke-prod

  # Allow all namespaced-scoped resources to be created, except for ResourceQuota, LimitRange, NetworkPolicy

  namespaceResourceBlacklist:

  - group: ''
    kind: ResourceQuota
  - group: ''
    kind: LimitRange
  - group: ''
    kind: NetworkPolicy

  # Deny all namespaced-scoped resources from being created, except for these

  namespaceResourceWhitelist:

  - group: ''
    kind: Pod
  - group: 'apps'
    kind: Deployment
  - group: 'apps'
    kind: StatefulSet
  - group: 'apps'
    kind: ReplicaSet
  - group: ''
    kind: Service
  - group: ''
    kind: ServiceAccount
  - group: ''
    kind: ConfigMap
  - group: ''
    kind: Secret
  - group: 'rbac.authorization.k8s.io'
    kind: RoleBinding
  - group: 'rbac.authorization.k8s.io'
    kind: Role
  - group: 'dynamodb.services.k8s.aws'
    kind: Table
  - group: 'autoscaling'
    kind: HorizontalPodAutoscaler  
    EOF
    :::

- Line 7: (Restrict what may be deployed): List of permitted git repositories that are allowed to deploy. The value gets replaced with gitops-workload url( Line 46,47 of `argoproject-applicationset.yaml`).
- Line 12: (Restrict where apps may be deployed to): Permitted destination of clusters and namespaces. For example carts namespace is restricted to spoke-staging cluster.
- Line 39: Restricted resource creation list.
- Line 47: Allowed resource creation list.

### 3. Git commit

```bash
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap project applicationset and webstore project values"
git push
```

### 4. Validate Project

On the Argo CD dashboard, go to **Settings** and **Projects** to validate that the webstore project has been created.

![Webstore-Project](/static/images/webstore-project.png)
