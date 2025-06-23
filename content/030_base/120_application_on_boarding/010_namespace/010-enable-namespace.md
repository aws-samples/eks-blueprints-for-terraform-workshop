---
title: "Create Webstore Namespace"
weight: 10
---

::video{id=HPQvdbKVGmo}

In this chapter, you will onboard Webstore application to create environment(dev) specific namespaces (ui,orders,checkout,carts,catalog,assets).

Building on the automation in the 'Namespace and Workload Automation>Namespace automation' chapter, we’ll add a new folder at `config/webstore/namespace` in the platform Git repository. When this folder and its manifest are pushed to Git, the existing create-namespace ApplicationSet will:

![namespace  webstore](/static/images/namespace-webstore-applicationset.png)

1. The create-namespace ApplicationSet detects the config/webstore/namespace folder.
2. It creates a new Argo CD Application named create-namespace-webstore.
3. This Application deploys manifests in config/webstore/namespace

### 1. Create webstore namespace configuration

We’ll now define an ApplicationSet named create-namespace-env-webstore to generate environment-specific namespace applications for the webstore workload.

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
- Line 29: Points to the namespace Helm chart located in charts/namespace  

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

- Line 36-37: Specifies default and optional environment-specific Helm value files


### 2. Create webstore namespace default values

Copy the default values file for the webstore namespace Helm chart.


<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
mkdir -p $GITOPS_DIR/platform/config/webstore/namespace/values
cp $BASE_DIR/solution/gitops/platform/config/workload/webstore/namespace/values/default-values.yaml $GITOPS_DIR/platform/config/webstore/namespace/values/default-values.yaml
:::
<!-- prettier-ignore-end -->

![namespace-helm](/static/images/namespace-webstore-defalut-values.jpg)


:::expand{header="Check the file content:"}

```bash
code $GITOPS_DIR/platform/config/webstore/namespace/values/default-values.yaml
```

:::

### 3. Enable hub cluster for webstore workload

The namespace ApplicationSet only targets clusters labeled with workload_webstore: 'true'. Let’s enable this label for the hub cluster.


<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
sed -i "s/#enablewebstore//g" ~/environment/hub/main.tf
:::
<!-- prettier-ignore-end -->

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

### 4. Apply Terraform

This will set the label workload_webstore: 'true' on the hub cluster.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
cd ~/environment/hub
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->

### 5. Git commit

Push the newly added ApplicationSet and value files to Git:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
cd $GITOPS_DIR/platform
git add .
git commit -m "add webstore namespace applicationset and namespace values"
git push
:::
<!-- prettier-ignore-end -->

<!-- :::alert{header="Sync Application"}
If the new create-namespace-webstore is not visible after a few minutes, you can click on SYNC and SYNCHRONIZE in Argo CD to force it to synchronize.

Or you can do it also with cli:

:::code{showCopyAction=true showLineNumbers=false language=yaml }
argocd app sync argocd/bootstrap
::: -->

:::alert{header=Note type=warning}
The 'create-namespace-webstore' application will become visible after a few minutes. 
:::


So it creates a new **create-namespace-webstore** application:

![namespace-workload](/static/images/namespace_webstore.png)

<!-- :::alert{header=Note type=warning}
Be patient, it can takes some times for the **namespace-webstore** to reflect in Argocd UI.
Wait few minutes and refresh the UI
::: -->

The namespace-webstore application then makes Argo CD installs the namespace Helm chart using the default values.


### 6. Validate namespaces

:::alert{header=Note type=warning}
It can few minutes for namespaces to be created.
Wait few minutes and try again
:::

With this setup, the webstore namespace and its policies (like LimitRange and NetworkPolicies) are automatically managed using Argo CD and Helm, driven by simple Git changes.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
kubectl get ns --context hub-cluster
:::
<!-- prettier-ignore-end -->


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

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=yaml }
kubectl get limitrange  -n ui --context hub-cluster -o yaml
:::
<!-- prettier-ignore-end -->


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
