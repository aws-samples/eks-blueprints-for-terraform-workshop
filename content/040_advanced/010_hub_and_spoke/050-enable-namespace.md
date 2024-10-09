---
title: "Namespace and Webstore workload"
weight: 50
---

In this chapter you will associate both namespace and workload application to webstore project created in the previous chapter

### 1. Set Project

:::code{showCopyAction=true showLineNumbers=false language=bash highlightLines='0'}
sed -i "s/project: default/project: webstore/g" $GITOPS_DIR/platform/config/workload/webstore/workload/webstore-applicationset.yaml
:::

Changes by the code snippet is highlighted below.

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

:::code{showCopyAction=true showLineNumbers=false language=bash highlightLines='0'}
cd $GITOPS_DIR/platform
git add .
git commit -m "set namespace and webstore applicationset project to webstore"
git push
:::

### 3. Enable workload_webstore labels on spoke cluster

```bash
sed -i "s/workload_webstore = false/workload_webstore = true/g" ~/environment/spoke/main.tf
```

### 4. Apply Terraform

```bash
cd ~/environment/spoke
terraform apply --auto-approve
```

Once we activate this, the webstore microservice will be deployed.
Because, we have configured our default Managed Node Group to only accept Critical Addons:

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

The webstore application is not able to be deployed on the managed node groups, and we are relying on Karpenter to create additional EC2 instances.

```bash
eks-node-viewer
```

![eks-node-viewer](/static/images/eks-node-viewer.jpg)

### 5. Validate workload

:::alert{header="Important" type="warning"}
It takes few minutes for Argo CD to synchronize, and then for Karpenter to provision the additional node.
It takes also few minutes for the loadbalancer to be provisioned correctly.
:::

```bash
app_url_staging
```

Access webstore in the browser.

![webstore](/static/images/webstore-ui.png)

Congratulations!, with this setup, you are able to deploy workloads applications using Argo CD Projects and ApplicationSets, from a configuration cluster (the Hub) to one spoke cluster, but you can easily duplicate this to manage severals spoke clusters with the same mechanisms.
