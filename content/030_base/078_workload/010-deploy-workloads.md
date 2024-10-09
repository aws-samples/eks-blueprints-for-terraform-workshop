---
title: "Deploy Workloads"
weight: 10
---

In this chapter you will deploy webstore workload. Similar to namespace in the previous chapter, we will setup Argo CD so that deploying a new workload is as simple as creating a new folder with manifests.

### 1. Create bootstrap workload applicationset

This ApplicationSet initiates the deployment of all the workloads.

![workload-appofapps](/static/images/workload-appofapps.jpg)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='22,32'}

cat > $GITOPS_DIR/platform/bootstrap/workload-applicationset.yaml << 'EOF'
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
                  environment: 'control-plane'
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
            #limit: 100
        syncOptions:
          - CreateNamespace=true

EOF

:::
<!-- prettier-ignore-end -->

- Line 22: Git generator iterates through folders under "**config/workload**" in platform git repository
- Line 32: `{path}` maps to each workload folder under **config/workload**.
  - For **webstore**, `{path}` maps to **config/workload/webstore**.
  - Since there is no folder "**config/workload/webstore/workload**", there are no files to process at this point.

### 2. Git commit

```bash
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap workload applicationset"
git push
```

As the **bootstrap** folder is monitored, when a new file like **workload-applicationset.yaml** is added, it gets processed.

![workload-appofapps-monitor](/static/images/workload-appofapps-monitor.jpg)

The newly added **workload-applicationset.yaml** file iterates through the **config/workload** folders and processes any workload config files found under **config/workload/<<workload-name>>/workload**

![workload-appofapps-monitor](/static/images/workload-appofapps-iteration.jpg)

:::alert{header="Important" type="warning"}
Since the folder `config/workload/webstore/workload` does not exist yet it has nothing to process.
:::

### 3. Deploy webstore workload

The webstore workload configuration files are in the **workload** git repository, not in the **platform** git repository. This is to show the difference of ownership and responsibilities between platform team and application team.

Let's have platform team add webstore applicationset to allow the webstore application team to deploy from the workload git repository.

![workload-webstore](/static/images/workload-webstore.jpg)

<!-- prettier-ignore-start -->
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
            #limit: 100

EOF
:::
<!-- prettier-ignore-end -->

- Line 17: The **webstore** workload is only deployed on clusters that have the label **workload_webstore = true**.
  - The hub cluster has workload_webstore = true label.
- Line 22: **metadata.annotations.workload_repo_url** i.e workload_repo_url annotation on the hub cluster has the value of the workload git repository.
- Line 25: It maps to **webstore/** ( microservices under webstore folder).
- Line 39: **Path** gets the value each microservice directory.
- The label environment on the hub cluster is "**control-plane**", (taken from cluster secret)
- **Kustomization** deploys each microservice in "control-plane" environment.
- Line 42: **path.basename** maps to the microservice directory name, which maps to the target namespace for deployment.
  - So each microservice deploys into its own matching namespace. This makes asset microservice deploy to asset namespace, carts to carts and so on.

![workload-webstore-folders](/static/images/workload-webstore-deployment.png)

### 4. Git commit

```bash
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap workload applicationset"
git push
```

### 5. Accelerate ArgoCD sync

```bash
argocd app sync argocd/workload-webstore
```

![workload-webstore](/static/images/workload_webstore.jpg)

### 5. Validate workload

::alert[It takes few minutes to deploy the workload and create a loadbalancer]{header="Important" type="warning"}

```bash
app_url_hub
```

Access webstore in the browser.

![webstore](/static/images/webstore-ui.png)
