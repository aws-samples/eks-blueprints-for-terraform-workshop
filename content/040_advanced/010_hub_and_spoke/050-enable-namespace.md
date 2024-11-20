---
title: "Namespace and Webstore workload"
weight: 50
---

In this chapter, we will associate both the namespace and workload applications with the webstore project created in the previous chapter.

### 1. Set Project

We'll update the project setting in the webstore applicationset file:

:::code{showCopyAction=true showLineNumbers=false language=bash highlightLines='0'}
sed -i "s/project: default/project: webstore/g" $GITOPS_DIR/platform/config/workload/webstore/workload/webstore-applicationset.yaml
:::

The changes made by the code snippet are highlighted below:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash highlightLines='0'}
cd $GITOPS_DIR/platform
git diff
:::
<!-- prettier-ignore-end -->

:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='8'}
--- a/config/workload/webstore/workload/webstore-applicationset.yaml
+++ b/config/workload/webstore/workload/webstore-applicationset.yaml
@@ -31,7 +31,7 @@ spec:
component: '{{path.basename}}'
workloads: 'true'
spec:

-      project: default

*      project: webstore
         source:
           repoURL: '{{metadata.annotations.workload_repo_url}}'
           path: '{{path}}/{{metadata.labels.environment}}'
  :::

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

When we activate this, the webstore microservice will be deployed. We have configured our default Managed Node Group to only accept Critical Addons:

```bash
cat ~/environment/spoke/main.tf | grep -A4 taints
```

```
      taints = local.aws_addons.enable_karpenter ? {
        dedicated = {
          key    = "CriticalAddonsOnly"
          operator   = "Exists"
          effect    = "NO_SCHEDULE"
```

As a result, the webstore application cannot be deployed on the managed node groups. We are relying on Karpenter to create additional EC2 instances for our application.

Let's check the node status:

```bash
eks-node-viewer
```

![eks-node-viewer](/static/images/eks-node-viewer.jpg)

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
