---
title: 'Deploy Workloads'
weight: 10
---
### 1. Create AppofApps workload applicationset

App of Apps workload application set scans workload folders under `config/workload` and creates specific application sets for each workload. When you add a new workload it detects the change and creates workload specific  applicationset without requiring manual intervention.

```bash
cat > ~/environment/wgit/assets/platform/appofapps/workload-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: workload
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
              environment: 'hub'          
      - git:
          repoURL: '{{metadata.annotations.platform_repo_url}}'
          revision: '{{metadata.annotations.platform_repo_revision}}'
          directories:
            - path: '{{metadata.annotations.platform_repo_basepath}}config/workload/*'      

  template:
    metadata:
      name: 'workload-{{path.basename}}'
      labels:
        environment: '{{metadata.labels.environment}}'
    spec:
      project: default
      source:
        repoURL: '{{metadata.annotations.platform_repo_url}}'
        path: '{{path}}/workload'
        targetRevision: '{{metadata.annotations.platform_repo_revision}}'
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
### 2. Git commit

```bash
cd ~/environment/wgit
git add . 
git commit -m "add appofapps workload applicationset"
git push
```

On the ArgoCD dashboard click on appofapps Application to see newly created workload applicationset.


![appofapps-workload-applicationset](/static/images/appofapps-workload-applicationset.png)

### 3. Create webstore workload applicationset

The Webstore Workload ApplicationSet automatically creates an ArgoCD Workload Application for any clusters that have the label `workload_webstore: 'true'`. It deploys label environment version of the workload application version. 

In this example, the Webstore ApplicationSet will deploy the `"hub"` version of the application to the hub-cluster. This is because:

- There is only one cluster labeled with `workload_webstore: 'true'` 
- That cluster also has the label `environment: 'hub'`

```bash
mkdir -p ~/environment/wgit/assets/platform/config/workload/webstore/workload
cat > ~/environment/wgit/assets/platform/config/workload/webstore/workload/webstore-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: webstore
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
                  workload_webstore: 'true'  
              values:
                workload: webstore

          - git:
              repoURL: '{{metadata.annotations.workload_repo_url}}'
              revision: '{{metadata.annotations.workload_repo_revision}}'
              directories:
                - path: '{{metadata.annotations.workload_repo_basepath}}{{values.workload}}/*'
                     
  template:
    metadata:
      name: 'webstore-{{metadata.labels.environment}}-{{path.basename}}'
      labels:
        environment: '{{metadata.labels.environment}}'
        tenant: 'webstore'
        component: '{{path.basename}}'
        workloads: 'true'
    spec:
      project: default
      source:
        repoURL: '{{metadata.annotations.workload_repo_url}}'
        path: '{{path}}/{{metadata.labels.environment}}'
        targetRevision: '{{metadata.annotations.workload_repo_revision}}'
      destination:
        namespace: '{{path.basename}}'
        name: '{{name}}'
      syncPolicy:
        automated:
          allowEmpty: true
          prune: true
        retry:
          backoff:
            duration: 1m
          limit: 100

EOF
```
### 4. Git commit

```bash
cd ~/environment/wgit
git add . 
git commit -m "add webstore workload applicationset"
git push
```

### 5. Validate workload

::alert[It takes few minutes to deploy the workload and create a loadbalancer]{header="Important" type="warning"}

```bash
echo -n "Click here to open -> http://" ; kubectl get svc ui-nlb -n ui  --context hub --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo ""
```

Access  webstore in the browser.

![webstore](/static/images/webstore-ui.png)
