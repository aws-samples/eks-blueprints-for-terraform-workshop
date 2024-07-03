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

```json
cat > $GITOPS_DIR/platform/appofapps/namespace-applicationset.yaml << 'EOF'
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

Again, we can note, that it uses the annotations from the secret like {{metadata.annotations.platform_repo_url}}, which means that it will retrieve the value 
from the secret, like we can do manually with:

```bash
kubectl --context hub get secrets -n argocd hub-cluster -o json | jq ".metadata.annotations.platform_repo_url"
```

Additionaly, we are using a git generator, that will watch the defined directory : `{{metadata.annotations.platform_repo_basepath}}config/workload/*` which points 
to your git repository, which is normally checkout locally, so you can check the content here: 

```bash
ls -la $GITOPS_DIR/platform/config/workload/
```

The git generator will iterate for each item present in this directory and then generate an ApplicationSet that will add the `/namespace` to the item find, 
this is done with the syntax: `path: '{{path}}/namespace'`, so the target will be `assets/platform/config/workload/xxxx/namespace/`where xxxx is every directory 
find by the git generator.

> Later we will use the same git generator to deploy also our workloads.

### 2. Git commit

```bash
cd $GITOPS_DIR/platform
git add . 
git commit -m "add appofapps namespace applicationset"
git push
```

On the Argo CD dashboard click on appofapps Application to see newly created namespace applicationset.

::alert[If the new namespace is not visible after a few minutes, you can click on SYNC and SYNCHRONIZE in Argo CD to force it to synchronize.]{header="Sync Application"}

![namespace-helm](/static/images/appofapps-namespace-applicationset.png)



### 3. Create webstore namespace applicationset

Now, we create an ApplicationSet stored in the directory that is watched by the `namespace` ApplicationSet we juste created.

The Webstore Namespace ApplicationSet automatically creates an Argo CD Namespace Application for any clusters that have the label `workload_webstore: 'true'`, and use the `environment` label (line 20) from the cluster secret to customize the name of the Application, in our case the name will be `namespace-staging-webstore`.

```json
mkdir -p $GITOPS_DIR/platform/config/workload/webstore/namespace
cat > $GITOPS_DIR/platform/config/workload/webstore/namespace/namespace-webstore-applicationset.yaml << 'EOF'
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

The Webstore ApplicationSet reads the default namespace configuration values (line 35) from `assets/platform/config/workload/webstore/namespace/values/default-values.yaml` in the git repository. It then looks for environment specific overrides in the `<environment label>-values.yaml` files if it exists. 

For example, for the hub-cluster which has the environment label `"hub"`, it will check `assets/platform/config/workload/webstore/namespace/values/hub-values.yaml` for any overrides. If the override file for a specific environment label does not exist, such as `<environment label>-values.yaml`, then the Webstore ApplicationSet will ignore it and just use the default values in `default-values.yaml`.
The `default-values.yaml` contains the namespaces to create, along with the **limitRanges** and **resourceQuotas** to apply for each namespace. 

```json
mkdir -p $GITOPS_DIR/platform/config/workload/webstore/namespace/values
cat > $GITOPS_DIR/platform/config/workload/webstore/namespace/values/default-values.yaml << 'EOF'
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

Thoses values will be used with the namespace helm Chart that you can find in the Application target which is `assets/platform/charts/namespace`.

```bash
tree $GITOPS_DIR/platform/charts/namespace
```

Output:
```
/home/ec2-user/environment/wgit/assets/platform/charts/namespace
├── Chart.yaml
├── README.md
├── templates
│   ├── _helpers.tpl
│   ├── limitrange
│   │   └── limitrange.yaml
│   ├── namespace
│   │   └── namespace.yaml
│   ├── networkpolicy
│   │   ├── egress
│   │   │   ├── allow-dns.yaml
│   │   │   └── deny-all.yaml
│   │   ├── ingress
│   │   │   └── deny-all.yaml
│   │   └── networkpolicy.yaml
│   ├── rbac
│   │   ├── rolebinding.yaml
│   │   └── role.yaml
│   └── resourcequota
│       └── resourcequota.yaml
├── values.schema.json
├── values-test.yaml
└── values.yaml
```

### 5. Git commit

```bash
cd $GITOPS_DIR/platform
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
    { workload_webstore = true }
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

:::expand{header="Output"}
```
NAME              STATUS   AGE
assets            Active   6h
carts             Active   6h
catalog           Active   6h
checkout          Active   6h
default           Active   8h
kube-node-lease   Active   8h
kube-public       Active   8h
kube-system       Active   8h
orders            Active   6h
rabbitmq          Active   6h
ui                Active   6h
```
:::

To view the LimitRange set for the ui namespace in the spoke-staging cluster.

```bash
kubectl get limitrange  -n ui --context hub -o yaml
```

:::expand{header="Output"}
```
apiVersion: v1
items:
- apiVersion: v1
  kind: LimitRange
  metadata:
    annotations:
      argocd.argoproj.io/tracking-id: namespace-staging-webstore:/LimitRange:ui/default
      helm.sh/chart: team-1.0.0
      kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"v1","kind":"LimitRange","metadata":{"annotations":{"argocd.argoproj.io/tracking-id":"namespace-staging-webstore:/LimitRange:ui/default","helm.sh/chart":"team-1.0.0"},"labels":{"app.kubernetes.io/created-by":"eks-workshop","app.kubernetes.io/instance":"webstore","app.kubernetes.io/managed-by":"Helm","app.kubernetes.io/name":"webstore","environment":"hub","helm.sh/chart":"team-1.0.0"},"name":"default","namespace":"ui"},"spec":{"limits":[{"default":{"cpu":"500m"},"defaultRequest":{"cpu":"500m"},"max":{"cpu":"2"},"min":{"cpu":"100m"},"type":"Container"}]}}
    creationTimestamp: "2024-06-06T09:41:07Z"
    labels:
      app.kubernetes.io/created-by: eks-workshop
      app.kubernetes.io/instance: webstore
      app.kubernetes.io/managed-by: Helm
      app.kubernetes.io/name: webstore
      environment: hub
      helm.sh/chart: team-1.0.0
    name: default
    namespace: ui
    resourceVersion: "656271"
    uid: a5674ebd-cd53-4ab5-9a5a-0de02c238789
  spec:
    limits:
    - default:
        cpu: 500m
      defaultRequest:
        cpu: 500m
      max:
        cpu: "2"
      min:
        cpu: 100m
      type: Container
kind: List
metadata:
  resourceVersion: ""
```
:::

You can also see the application namespace-hub-webstore on the Argo CD dashboard.

![namespace-hub-webstore](/static/images/namespace-hub-webstore.png)


