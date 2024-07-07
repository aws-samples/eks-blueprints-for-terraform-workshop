---
title: 'Deploy Workloads'
weight: 10
---
In this chapter you will deploy webstore workload. Similiar to namespace in the previous chater , we will setup ArgoCD so that deploying a new workload  is as simple as creating a new  a folder with manifests.

### 1. Create AppofApps workload applicationset

This ApplicationSet initiates the deployment of all the workloads.

![workload-appofapps](/static/images/workload-appofapps.png)


:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='22,33'}

cat > $GITOPS_DIR/platform/appofapps/workload-applicationset.yaml << 'EOF'
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

:::

Line 22: Git generator iterates through folders under "config/workload" in gitops-platform repository  
Line 33: {path} maps to each workload folder under config/workload. For webstore {path} maps to config/workload/webstore. Since there is no folder "config/workload/webstore/workload", there are no files to process at this point.

### 2. Git commit

```bash
cd $GITOPS_DIR/platform
git add . 
git commit -m "add appofapps workload applicationset"
git push
```

As the appofapps folder is monitored, when a new file like workload-applicationset.yaml is added, it gets processed. 

![workload-appofapps-monitor](/static/images/workload-appofapps-monitor.png)

The newly added workload-applicationset.yaml file iterates through the config/workload folders and processes any workload config files found under config/workload/\<<workload-name\>>/workload. Since the folder config/workload/webstore/workload does not exist it has nothing to process.

![workload-appofapps-monitor](/static/images/workload-appofapps-iteration.png)


On the Argo CD dashboard click on appofapps Application to see newly created workload applicationset.


![appofapps-workload-applicationset](/static/images/appofapps-workload-applicationset.png)

### 3. Deploy webstore workload 

The webstore workload configuration files are in the **gitops-workload** repository, not in the **gitops-platform** repository.

The webstore workload supports multiple environments like hub, staging and prod. Environment-specific configurations are applied using kustomization.

![workload-webstore-folders](/static/images/workload-webstore-folders.png)

Lets add webstore applicationset to deploy the webstore workload in the gitops-workload repository.

![workload-webstore](/static/images/workload-webstore.png)

:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='17,22,25,39,42'}
mkdir -p $GITOPS_DIR/platform/config/workload/webstore/workload
cat > $GITOPS_DIR/platform/config/workload/webstore/workload/webstore-applicationset.yaml << 'EOF'
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

:::

Line 17: The webstore workload is only deployed on clusters that have the label workload_webstore = true. The hub cluster has workload_webstore = true label.  
Line 22: metadata.annotations.workload_repo_url i.e workload_repo_url annotation on the hub cluster has the value of the gitops-worload repository.  
Line 25: It maps to webstore/* ( microservices under webstore folder). 
Line 39: Path gets the value each microservice directory. The label environment on the hub cluster is "hub". Kustomization deploys "hub" environment of each microservice.  
Line 42: path.basename maps to the microservice directory name, which maps to the target namespace for deployment. So each microservice deploys into its own matching namespace. This makes asset microservice deploy to asset namespace, carts to carts and so on.  


![workload-webstore-folders](/static/images/workload-webstore-deployment.png)


### 4. Git commit

```bash
cd $GITOPS_DIR/platform
git add . 
git commit -m "add appofapps workload applicationset"
git push
```

### 5. Validate workload

::alert[It takes few minutes to deploy the workload and create a loadbalancer]{header="Important" type="warning"}

```bash
echo -n "Click here to open -> http://" ; kubectl get svc ui-nlb -n ui  --context hub --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'; echo ""
```

Access  webstore in the browser.

![webstore](/static/images/webstore-ui.png)
