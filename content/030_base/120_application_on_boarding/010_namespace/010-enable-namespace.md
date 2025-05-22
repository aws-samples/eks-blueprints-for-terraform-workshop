---
title: "Automate Webstore Namespace Creation"
weight: 10
---

We already have a helm chart to deploy namespace in platform gitrepo. 

![namespace-helm](/static/images/namespace-helm.png)

:::expand{header="Check the files in helm chart:"}
```
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
:::

To create namespace, we have to deploy namespace helm chart and pass values.

![namespace-helm-deploy](/static/images/namespace-helm-deploy.png)

### 1. Create webstore namespace configuration

 In "Namespace And Workload" automation, we have already created create-namespace application that continuously scans and process mainfests under config/*/name folder in platform repo. 

Let's create an ApplicationSet that is responsible for the namespaces associated with the webstore workload.

![namespace  webstore](/static/images/namespace-webstore-applicationset.png)



<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='16,29,30,36,37'}
mkdir -p $GITOPS_DIR/platform/config/webstore/namespace
cat > $GITOPS_DIR/platform/config/webstore/namespace/namespace-webstore-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: create-namespace-env-webstore
  namespace: argocd
spec:
  goTemplate: true
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
      name: 'namespace-{{ .metadata.labels.environment }}-webstore'
      labels:
        environment: '{{ .metadata.labels.environment }}'
        tenant: 'webstore'
        workloads: 'true'
    spec:
      project: default
      source:
        repoURL: '{{ .metadata.annotations.platform_repo_url }}'
        path: '{{ .metadata.annotations.platform_repo_basepath }}charts/namespace'
        targetRevision: '{{ .metadata.annotations.platform_repo_revision }}'
        helm:
          releaseName: 'webstore'
          ignoreMissingValueFiles: true
          valueFiles:
            - '../../config/webstore/namespace/values/default-values.yaml'
            - '../../config/webstore/namespace/values/{{ .metadata.labels.environment }}-values.yaml'
      destination:
        name: '{{ .name }}'
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
- Line 29: Deploy the helm chart present in the folder charts/namespace in platform git repo  
- Line 35: Default values for the namespace helm chart
- Line 36: (optional) Override values for the namespace helm chart. For example you could override default values for environment = dev with the file dev-values.yaml. If this file does not exist then it is ignored.

### 4. Create webstore namespace default values

![namespace-helm](/static/images/namespace-webstore-defalut-values.jpg)

```json
mkdir -p $GITOPS_DIR/platform/config/webstore/namespace/values
cp $BASE_DIR/solution/gitops/platform/config/workload/webstore/namespace/values/default-values.yaml $GITOPS_DIR/platform/config/webstore/namespace/values/default-values.yaml
```

:::expand{header="Check the file content:"}

```bash
code $GITOPS_DIR/platform/config/workload/webstore/namespace/values/default-values.yaml
```

:::

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


So it creates a new **namespace-webstore** application:

![namespace-workload](/static/images/namespace_webstore.jpg)

:::alert{header=Note type=warning}
Be patient, it can takes some times for the **namespace-webstore** to reflect in Argocd UI.
Wait few minutes and refresh the UI
:::

The namespace-webstore application then makes Argo CD installs the namespace Helm chart using the default values.


### 8. Validate namespaces

With this setup, the webstore namespace and its policies (like LimitRange and NetworkPolicies) are automatically managed using Argo CD and Helm, driven by simple Git changes.

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

To view the LimitRange set for the ui namespace in the hub-cluster.

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
