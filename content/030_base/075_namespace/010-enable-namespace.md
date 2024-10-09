---
title: "Create Namespace"
weight: 10
---

In this chapter you will create **webstore workload** namespaces carts, catalog, checkout, orders, rabbitmq, assets, and ui. At the end of this chapter, we will setup Argo CD so that creating namespaces for a new workload for example "payment" is as simple as creating a new "payment" folder with manifests.

### 1. Create Bootstrap namespace applicationset

In the "Kubernetes Addons" chapter, we added a file called "**$GITOPS_DIR/platform/bootstrap/addons-applicationset.yaml**" that watches the "bootstrap" folder and processes any changes.

![namespace-begin](/static/images/namespace-begin.jpg)

Lets Add namespace applicationset (**addons-applicationset.yaml**) into the bootstrap folder.

![namespace-add-namespace-applicationset](/static/images/namespace-namespace-applicationset.jpg)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='21,33'}
cat > $GITOPS_DIR/platform/bootstrap/namespace-applicationset.yaml << 'EOF'
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
                  environment: control-plane
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
            #limit: 100
        syncOptions:
          - CreateNamespace=true
EOF
:::
<!-- prettier-ignore-end -->

This ApplicationSet initiates the creation of namespaces for all the workloads.

- Git generator (line 21) iterates through folders under "config/workload" in gitops-workload repository.
- For each folder (line 33), ApplicationSet process files under "namespace" folder.
- Since there are currently no workload folders under "config/workload/webstore/workload", there are no files to process at this point.

### 2. Git commit

```bash
cd $GITOPS_DIR/platform
git add .
git commit -m "add bootstrap namespace applicationset"
git push
```

On the Argo CD dashboard click on bootstrap Application to see newly created namespace applicationset.

:::alert{header="Sync Application"}
If the new namespace is not visible after a few minutes, you can click on SYNC and SYNCHRONIZE in Argo CD to force it to synchronize.

Or you can do it also with cli:

```bash
argocd app sync argocd/bootstrap
```

:::

TODO: maybe change this image with the out-of-sync one

![namespace-helm](/static/images/bootstrap-namespace-applicationset.jpg)

### 3. Create webstore namespace configuration

Let's create an ApplicationSet that is responsible for the namespaces associated with the webstore workload.

![namespace-helm](/static/images/namespace-webstore-applicationset.jpg)

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='15,29,35,36'}
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
            #limit: 100
EOF
:::
<!-- prettier-ignore-end -->

- Line 15: Only clusters that have label workload_webstore: 'true' are selected
- Line 29: Deploy the helm chart present in the folder charts/namespace  
  ![namespace-helm](/static/images/namespace-helm.jpg)
- Line 35: Default values for the namespace helm chart
- Line 36: (optional) Override values for the namespace helm chart. For example you could override default values for environment = prod with the file prod-values.yaml

### 4. Create webstore namespace default values

![namespace-helm](/static/images/namespace-webstore-defalut-values.jpg)

```json
mkdir -p $GITOPS_DIR/platform/config/workload/webstore/namespace/values
cp $BASE_DIR/solution/gitops/platform/config/workload/webstore/namespace/values/default-values.yaml $GITOPS_DIR/platform/config/workload/webstore/namespace/values/default-values.yaml
```

:::expand{header="Check the file content:"}

```bash
code $GITOPS_DIR/platform/config/workload/webstore/namespace/values/default-values.yaml
```

:::

```bash
tree $GITOPS_DIR/platform/charts/namespace
```

Output:

```
/home/ec2-user/environment/gitops-repo/platform/charts/namespace
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

### 5. Enable hub cluster for webstore workload

The webstore Namespace applicationset only creates webstore namespaces on clusters labeled with workload_webstore: 'true'. Let's add this label to the hub cluster.

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

### 6. Apply Terraform

This will set the label workload_webstore: 'true' on the hub cluster.

```bash
cd ~/environment/hub
terraform apply --auto-approve
```

### 7. Git commit

```bash
cd $GITOPS_DIR/platform
git add .
git commit -m "add webstore namespace applicationset and namespace values"
git push
```

The namespace-applicationset.yaml file makes Argo CD iterates through the folders under config/workload/\<\<workload>>/namespace.
With the recent commit, it now processes the files located under config/workload/webstore/namespace.

![namespace-helm](/static/images/namespace-process-webstore-applicationset.png)

So it creates a new **namespace-webstore** application:

![namespace-workload](/static/images/namespace_webstore.jpg)

The namespace-webstore application then makes Argo CD installs the namespace Helm chart using the default values.

![namespace-helm](/static/images/namespace-create-webstore-namespace.jpg)

### 8. Validate namespaces

```bash
kubectl get ns --context hub-cluster
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
kubectl get limitrange  -n ui --context hub-cluster -o yaml
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
      environment: control-plane
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
