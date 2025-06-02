---
title: "Webstore Staging: Namespace Setup with Overrides"
weight: 30
---

In this chapter, you’ll act as a ![Platform Task](/static/images/platform-task.png) platform engineer and create a namespace for the Webstore workload on the `spoke-staging` cluster.

This chapter builds on the namespace automation introduced in the **"Webstore Workload Onboarding>Namespace>Create Webstore Namespace"** chapter, which already configured Argo CD to install the namespace Helm chart.

Let’s quickly recap:  
You added an ApplicationSet (`namespace-webstore-applicationset.yaml`) that provisions namespaces by deploying the namespace Helm chart (Line 11-12) on Clusters with label workload_webstore = true (Line 7). The chart uses a default values file (line 11) and applies environment-specific overrides (line 12):

:::code{showCopyAction=false showLineNumbers=true language=bash highlightLines='7,11-12,18-19'}
    .
    .
    generators:
     - clusters:
        selector:
          matchLabels:
            workload_webstore: 'true'
    .
    .
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
    .
    .
:::

### 1. Set staging overrides

In this step, we’ll override only the CPU limits for the carts microservice:

```bash
cat > ~/environment/gitops-repos/platform/config/webstore/namespace/values/staging-values.yaml << 'EOF'
namespaces:
  carts:
    limitRanges:
      - name: default
        labels:
          app.kubernetes.io/created-by: staging-team
        limits:
          - type: Container
            default:
              cpu: "1000m"        # 500m × 2
            defaultRequest:
              cpu: "1000m"        # 500m × 2
            max:
              cpu: "4"            # 2 × 2
            min:
              cpu: "200m"         # 100m × 2
EOF
```


### 2. Git commit

Let's commit our changes:

:::code{showCopyAction=true showLineNumbers=false language=bash highlightLines='0'}
cd $GITOPS_DIR/platform
git add .
git commit -m "add namespace webstore staging values"
git push
:::

### 3. Enable workload_webstore labels on spoke cluster

We’ll update the Terraform configuration to enable the workload_webstore label:

```bash
sed -i "s/workload_webstore = false/workload_webstore = true/g" ~/environment/spoke/main.tf
```

### 4. Apply Terraform

Apply the Terraform changes:

```bash
cd ~/environment/spoke
terraform apply --auto-approve
```

### 5. Validate namespaces

:::alert{header=Note type=warning}
It can take a few minutes for the namespaces to be created.
Wait a few minutes and try again.
:::

With this setup, the webstore namespace and its policies (like LimitRange and NetworkPolicies) are automatically managed using ArgoCD and Helm, driven by simple Git changes.

```bash
kubectl get ns --context spoke-staging
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

To view the LimitRange set for the carts namespace in the spoke-staging cluster.

```bash
kubectl get limitrange  -n carts --context spoke-staging -o yaml
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
    namespace: carts
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

You can also see the application namespace-spoke-webstore on the ArgoCD dashboard.

![namespace-hub-webstore](/static/images/namespace-hub-webstore.png)
