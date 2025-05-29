---
title: "Webstore Staging Namespace Creation"
weight: 30
---


![Platform Task](/static/images/platform-task.png) Platform engineer tasks for onboarding an application involve creating a namespace. In this chapter you will create namespace for Webstore workload on spoke-staging cluster.

In "Webstore Workload Namespace Creation" chapter we have already configure to install helm chart with default-values. We already have default-values.yaml. 

namespace-webstore-applicationset.yaml created in that chapter shows it pickus up default-values.yaml( line 11) and then environment specific overrides( line 12).

:::code{showCopyAction=true showLineNumbers=true language=bash highlightLines='11-12'}
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

We are going to increase only CPU limits for carts microservices.

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
git commit -m "set namespace and webstore applicationset project to webstore"
git push
:::

### 3. Enable workload_webstore labels on spoke cluster

We'll update the Terraform configuration to enable the workload_webstore label:

```bash
sed -i "s/workload_webstore = false/workload_webstore = true/g" ~/environment/spoke/main.tf
```

### 4. Apply Terraform

Apply the Terraform changes:

```bash
cd ~/environment/spoke
terraform apply --auto-approve
```

### 5. Validate workload

:::alert{header="Important" type="warning"}
It takes a few minutes for Argo CD to synchronize, and then for Karpenter to provision the additional node.
It also takes a few minutes for the load balancer to be provisioned correctly.
:::

To access the webstore application, run:

```bash
app_url_staging
```

Access the webstore in the browser.

![webstore](/static/images/webstore-ui.png)

Congratulations! We have successfully set up a system where we can deploy workload applications using Argo CD Projects and ApplicationSets from a configuration cluster (the Hub) to a spoke cluster. This process can be easily replicated to manage several spoke clusters using the same mechanisms.
