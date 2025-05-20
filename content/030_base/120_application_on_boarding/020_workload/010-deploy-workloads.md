---
title: "Onboard Workload"
weight: 10
---


### 3. Deploy webstore workload

The webstore workload configuration files are in the **workload** git repository, not in the **platform** git repository. This separation demonstrates the different ownership and responsibilities between the platform team and application team.

Let's have the platform team add a webstore applicationset to allow the webstore application team to deploy from the workload git repository.

![workload-webstore](/static/images/workload-webstore.jpg)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='17,22,25,39,42'}
mkdir -p $GITOPS_DIR/platform/config/webstore/deployment
cat > $GITOPS_DIR/platform/config/webstore/deployment/webstore-dev-applicationset.yaml << 'EOF'
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

- Line 17: The **webstore** workload is only deployed on clusters with the label **workload_webstore = true**
  - The hub cluster has workload_webstore = true label
- Line 22: **metadata.annotations.workload_repo_url** i.e workload_repo_url annotation on the hub cluster has the value of the workload git repository
- Line 25: Maps to **webstore/** (microservices under webstore folder)
- Line 39: **Path** gets the value of each microservice directory
- The label environment on the hub cluster is "**control-plane**" (taken from cluster secret)
- **Kustomization** deploys each microservice in "control-plane" environment
- Line 42: **path.basename** maps to the microservice directory name, which maps to the target namespace for deployment
  - Each microservice deploys into its matching namespace - assets microservice deploys to assets namespace, carts to carts, and so on

![workload-webstore-folders](/static/images/workload-webstore-deployment.png)

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