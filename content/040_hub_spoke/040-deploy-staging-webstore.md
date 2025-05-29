---
title: "Deploy Webstore Staging"
weight: 40
---

So far, we have created the namespace for the Webstore workload. However, we have not deployed the application yet. The workload Git repository is already configured to be scanned and deployed automatically by Argo CD.

In this chapter application team ![Developer Task](/static/images/developer-task.png) deploys the webstore staging application independently, without any direct involvement from the platform team.


### 1. Copy Webstore Staging environment

We'll update the project setting in the webstore applicationset file:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash}
for svc in /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/workload/webstore/*; do
  svc_name=$(basename $svc)
  mkdir -p ${GITOPS_DIR}/workload/webstore/$svc_name
  cp -r $svc/staging ${GITOPS_DIR}/workload/webstore/$svc_name/ 2>/dev/null
done
:::
<!-- prettier-ignore-end -->

### 2. Git commit

Let's commit our changes:

:::code{showCopyAction=true showLineNumbers=false language=bash highlightLines='0'}
cd $GITOPS_DIR/workload
git add .
git commit -m "set namespace and webstore applicationset project to webstore"
git push
:::



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
