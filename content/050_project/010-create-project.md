---
title: "Argo CD Project"
weight: 10
---

Projects in Argo CD define guardrails that set constraints for associated applications. When we associate an application with a project, it must operate within the guardrails established by that project.

In this chapter, we will create a project for the webstore workload. In upcoming chapters, we will associate the webstore workload deployment with this project.

### 1. Create App of Apps Project ApplicationSet

Let's create an ApplicationSet that generates an Argo CD project for each workload.

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
                  fleet_member: hub
              values:
                addonChart: argocd-apps
                addonChartVersion: '1.4.1'
                addonChartRepository: https://argoproj.github.io/argo-helm
          - git:
              repoURL: '{{metadata.annotations.platform_repo_url}}'
              revision: '{{metadata.annotations.platform_repo_revision}}'
              directories:
                - path: '{{metadata.annotations.platform_repo_basepath}}config/*'
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
        - repoURL: '{{values.addonChartRepository}}'
          chart: '{{values.addonChart}}'
          targetRevision: '{{values.addonChartVersion}}'
          helm:
            releaseName: 'argoprojects-{{path.basename}}'
            valueFiles:
              - '$values/{{metadata.annotations.platform_repo_basepath}}config/{{path.basename}}/project/project-values.yaml'
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
            #limit: 100
        syncOptions:
          - CreateNamespace=true

EOF
:::
<!-- prettier-ignore-end -->

- Line 16: Projects are installed on the hub cluster, not on the spoke clusters
- Line 20: Argo CD projects are created using a helm chart that installs the project from `argoproject`
- Line 25: Iterates through all workload folders under the config/workload folder
- Line 44: Contains project values for each workload
- Lines 46-47: Replaces sourceRepos value with the git workload url (See Line 7 below in the project-values.yaml)

### 2. Create Project Values

Now, let's create the webstore project values.

![project-values](/static/images/project-values.jpg)

The following helm values file contains source repositories, destinations, and allowed resources for the webstore workload. Some values are commented out for use in upcoming chapters.

```bash
mkdir -p $GITOPS_DIR/platform/config/webstore/project
cat > $GITOPS_DIR/platform/config/webstore/project/project-values.yaml << 'EOF'
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
  #enablespokeprod   name: spoke-prod
  #enablespokeprod - namespace: catalog
  #enablespokeprod   name: spoke-prod
  #enablespokeprod - namespace: checkout
  #enablespokeprod   name: spoke-prod
  #enablespokeprod - namespace: orders
  #enablespokeprod   name: spoke-prod
  #enablespokeprod - namespace: rabbitmq
  #enablespokeprod   name: spoke-prod

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
```

- Line 7: (Restrict what may be deployed): Lists permitted git repositories that can deploy. The value is replaced with gitops-workload url (Lines 46-47 of `argoproject-applicationset.yaml`)
- Line 12: (Restrict where apps may be deployed): Defines permitted destination clusters and namespaces. For example, the carts namespace is restricted to the spoke-staging cluster
- Line 39: Lists restricted resources that cannot be created
- Line 47: Lists allowed resources that can be created

### 3. Git commit

Let's commit our changes to Git:

```bash
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap project applicationset and webstore project values"
git push
```

:::alert{header=Note type=warning}
It may take some time for the Argo project webstore to synchronize on the cluster.
Wait a few moments and try refreshing the UI.
:::

### 4. Validate Project

In the Argo CD dashboard, navigate to **Settings** and then **Projects** to confirm that the webstore project has been created.

![Webstore-Project](/static/images/webstore-project.png)
