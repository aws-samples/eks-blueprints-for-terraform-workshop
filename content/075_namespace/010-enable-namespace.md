---
title: 'Create Namespace'
weight: 10
---

You will use namespace helm templates to create namespace, limitrange, networkpolicy, rbac and resource quota.

![namespace-helm](/static/images/namespace-helm.png)

::alert[In this workshop helm chart is in the GitHub repository to make it easy to understand. Use a Helm chart repository to store and serve charts - This is the preferred way to share charts. ]{header="Important" type="warning"}

### 1. Create AppofApps namespace applicationset 

AppofApps Namespace application set scans workload folders under `config/workload` and creates specific application sets for each workload. When you add a new
workload it detects the change and creates workload specific namespace applicationset without requiring manual intervention. 

```bash
cat > ~/environment/wgit/platform/appofapps/namespace-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: namespace
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
              environment: hub         
      - git:
          repoURL: '{{metadata.annotations.platform_repo_url}}'
          revision: '{{metadata.annotations.platform_repo_revision}}'
          directories:
            - path: '{{metadata.annotations.platform_repo_basepath}}config/workload/*'
  template:
    metadata:
      name: 'namespace-{{path.basename}}'
      labels:
        environment: '{{metadata.labels.environment}}'
        tenant: '{{path.basename}}'
        workloads: 'true'
    spec:
      project: default
      source:
        repoURL: '{{metadata.annotations.platform_repo_url}}'
        path: '{{path}}/namespace'
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
git commit -m "add appofapps namespace applicationset"
git push
```

On the ArgoCD dashboard click on appofapps Application to see newly created namespace applicationset.

::alert[If the new namespace is not visible after a few minutes, you can click on SYNC and SYNCHRONIZE in ArgoCD to force it to synchronize.]{header="Sync Application"}

![namespace-helm](/static/images/appofapps-namespace-applicationset.png)



### 3. Create webstore namespace applicationset

The Webstore Namespace ApplicationSet automatically creates an ArgoCD Namespace Application for any clusters that have the label `workload_webstore: 'true'`

```bash
mkdir -p ~/environment/wgit/platform/config/workload/webstore/namespace
cat > ~/environment/wgit/platform/config/workload/webstore/namespace/namespace-webstore-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: namespace-webstore
  namespace: argocd
spec:
  syncPolicy:
    preserveResourcesOnDeletion: false
  generators:
  - clusters:
      selector:
        matchLabels:
          workload_webstore: 'true'   
      values:
        workload: webstore
  template:
    metadata:
      name: 'namespace-{{metadata.labels.environment}}-webstore'
      labels:
        environment: '{{metadata.labels.environment}}'
        tenant: 'webstore'
        workloads: 'true'
    spec:
      project: default
      source:
        repoURL: '{{metadata.annotations.platform_repo_url}}'
        path: '{{metadata.annotations.platform_repo_basepath}}charts/namespace'
        targetRevision: '{{metadata.annotations.platform_repo_revision}}'
        helm:
          releaseName: 'webstore'
          ignoreMissingValueFiles: true
          valueFiles:
          - '../../config/workload/webstore/namespace/values/default-values.yaml'          
          - '../../config/workload/webstore/namespace/values/{{metadata.labels.environment}}-values.yaml'          
      destination:
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

### 4. Create default namespace values 

The Webstore ApplicationSet reads the default namespace configuration values from `platform/config/workload/webstore/namespace/values/default-values.yaml` in the git repository. It then looks for environment specific overrides in the `<environment label>-values.yaml` files. 

For example, for the hub-cluster which has the environment label `"hub"`, it will check `platform/config/workload/webstore/namespace/values/hub-values.yaml` for any overrides. If the override file for a specific environment label does not exist, such as `<environment label>-values.yaml`, then the Webstore ApplicationSet will ignore it and just use the default values in `default-values.yaml`.
The `default-values.yaml` contains the namespaces to create, along with the **limitRanges** and **resourceQuotas** to apply for each namespace. 

```bash
mkdir -p ~/environment/wgit/platform/config/workload/webstore/namespace/values
cat > ~/environment/wgit/platform/config/workload/webstore/namespace/values/default-values.yaml << 'EOF'
name: webstore
labels:
  environment: hub
namespaces:
  carts:
    labels:
      additionalLabels:
        app.kubernetes.io/created-by: eks-workshop
    limitRanges:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      limits:
        - default: # this section defines default limits
            cpu: 500m
          defaultRequest: # this section defines default requests
            cpu: 500m
          max: # max and min define the limit range
            cpu: "2"
          min:
            cpu: 100m
          type: Container
    resourceQuotas:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      spec:
        hard:
          cpu: "5000"
          memory: 200Gi
          pods: "20"
        scopeSelector:
          matchExpressions:
          - operator : In
            scopeName: PriorityClass
            values: ["high"]
  catalog:
    labels:
      additionalLabels:
        app.kubernetes.io/created-by: eks-workshop
    limitRanges:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      limits:
        - default: # this section defines default limits
            cpu: 500m
          defaultRequest: # this section defines default requests
            cpu: 500m
          max: # max and min define the limit range
            cpu: "2"
          min:
            cpu: 100m
          type: Container
    resourceQuotas:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      spec:
        hard:
          cpu: "5000"
          memory: 200Gi
          pods: "20"
        scopeSelector:
          matchExpressions:
          - operator : In
            scopeName: PriorityClass
            values: ["high"]
  checkout:
    labels:
      additionalLabels:
        app.kubernetes.io/created-by: eks-workshop
    limitRanges:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      limits:
        - default: # this section defines default limits
            cpu: 500m
          defaultRequest: # this section defines default requests
            cpu: 500m
          max: # max and min define the limit range
            cpu: "2"
          min:
            cpu: 100m
          type: Container
    resourceQuotas:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      spec:
        hard:
          cpu: "5000"
          memory: 200Gi
          pods: "20"
        scopeSelector:
          matchExpressions:
          - operator : In
            scopeName: PriorityClass
            values: ["high"]
  orders:
    labels:
      additionalLabels:
        app.kubernetes.io/created-by: eks-workshop
    limitRanges:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      limits:
        - default: # this section defines default limits
            cpu: 500m
          defaultRequest: # this section defines default requests
            cpu: 500m
          max: # max and min define the limit range
            cpu: "2"
          min:
            cpu: 100m
          type: Container
    resourceQuotas:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      spec:
        hard:
          cpu: "5000"
          memory: 200Gi
          pods: "20"
        scopeSelector:
          matchExpressions:
          - operator : In
            scopeName: PriorityClass
            values: ["high"]
  rabbitmq:
    labels:
      additionalLabels:
        app.kubernetes.io/created-by: eks-workshop
    limitRanges:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      limits:
        - default: # this section defines default limits
            cpu: 500m
          defaultRequest: # this section defines default requests
            cpu: 500m
          max: # max and min define the limit range
            cpu: "2"
          min:
            cpu: 100m
          type: Container
    resourceQuotas:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      spec:
        hard:
          cpu: "5000"
          memory: 200Gi
          pods: "20"
        scopeSelector:
          matchExpressions:
          - operator : In
            scopeName: PriorityClass
            values: ["high"]
  assets:
    labels:
      additionalLabels:
        app.kubernetes.io/created-by: eks-workshop
    limitRanges:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      limits:
        - default: # this section defines default limits
            cpu: 500m
          defaultRequest: # this section defines default requests
            cpu: 500m
          max: # max and min define the limit range
            cpu: "2"
          min:
            cpu: 100m
          type: Container
    resourceQuotas:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      spec:
        hard:
          cpu: "5000"
          memory: 200Gi
          pods: "20"
        scopeSelector:
          matchExpressions:
          - operator : In
            scopeName: PriorityClass
            values: ["high"]
  ui:
    labels:
      additionalLabels:
        app.kubernetes.io/created-by: eks-workshop
    limitRanges:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      limits:
        - default: # this section defines default limits
            cpu: 500m
          defaultRequest: # this section defines default requests
            cpu: 500m
          max: # max and min define the limit range
            cpu: "2"
          min:
            cpu: 100m
          type: Container
    resourceQuotas:
    - name: default
      labels:
        app.kubernetes.io/created-by: eks-workshop
      spec:
        hard:
          cpu: "5000"
          memory: 200Gi
          pods: "20"
        scopeSelector:
          matchExpressions:
          - operator : In
            scopeName: PriorityClass
            values: ["high"]            
EOF
```

### 5. Git commit

```bash
cd ~/environment/wgit
git add . 
git commit -m "add webstore namespace applicationset and namespace values"
git push
```

### 6. Set workload_webstore: 'true' label on the hub cluster

You want to deploy the webstore workload  on the hub cluster . You can do this by setting the label workload_webstore: 'true' on the hub cluster.

```bash
sed -i "s/#enablewebstore//g" ~/environment/hub/main.tf
```
Changes by the code snippet is highlighted below.

:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='7-7'}
locals{
  .  
  .
  addons = merge(
    .
    .
    { workloads = true }
}
:::

### 7. Apply Terraform

This will set the label workload_webstore: 'true' on the hub cluster.

```bash
cd ~/environment/hub
terraform apply --auto-approve
```
### 8. Validate namespaces 

```bash
kubectl get ns --context hub
```
To view the LimitRange set for the ui namespace in the spoke-staging cluster.

```bash
kubectl get limitrange  -n ui --context hub -o yaml
```

You can also see the application namespace-hub-webstore on the ArgoCD dashboard.

![namespace-hub-webstore](/static/images/namespace-hub-webstore.png)


