---
title: 'ArgoCD Project'
weight: 10
---

### 1. Create AppofApps Project  applicationset

App of Apps Project ApplicationSet scans workload folders under `config/workload` and creates specific Project ApplicationSets for each workload. When you add a new workload it detects the change and creates specific workload ApplicationSet without requiring manual intervention.

```bash
cat > ~/environment/wgit/platform/appofapps/argoproject-applicationset.yaml << 'EOF'
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
```

### 2. Create Project Values

The following helm values file contains source repositories, destinations, and allowed resources for the webstore workload. Few values are commented for the upcoming chapters.

```bash
mkdir -p ~/environment/wgit/platform/config/workload/webstore/project
cat > ~/environment/wgit/platform/config/workload/webstore/project/project-values.yaml << 'EOF'
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

### 3. Git commit

```bash
cd ~/environment/wgit
git add . 
git commit -m "add appofapps project applicationset and webstore project values"
git push
```

### 4. Validate Project

On the ArgoCD dashboard, go to **Settings** and **Projects** to validate that the webstore project has been created.

![Webstore-Project](/static/images/webstore-project.png)
