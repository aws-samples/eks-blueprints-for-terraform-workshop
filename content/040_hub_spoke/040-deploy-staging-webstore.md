---
title: "Deploy Webstore to Staging"
weight: 40
---

::video{id=gnzumq6rntI}


In this chapter application team ![Developer Task](/static/images/developer-task.png) deploys the webstore staging application independently, without any direct involvement from the platform team.

So far, we’ve created the staging namespace for the Webstore workload, but we haven’t deployed the staging Webstore application itself yet. 

This chapter builds on the namespace automation introduced in the **"Webstore Workload Onboarding > workload > Automate Webstore Deployment"** chapter, which already configured ArgoCD to deploy both staging and prod environment.

![Webstore Workload Folders](/static/images/create-deployment-allenv-webstore.png)

### 1. Copy Webstore Staging environment

We will now copy the **Staging environment** code to the workoad Git repository. Remember, all environments (like `staging`) apply customizations on top of the shared `base` folder. We have already have base, We will copy `staging` folders.
<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash}
for svc in /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/workload/webstore/*; do
  svc_name=$(basename $svc)
  mkdir -p ${GITOPS_DIR}/workload/webstore/$svc_name
  cp -r $svc/staging ${GITOPS_DIR}/workload/webstore/$svc_name/ 2>/dev/null
done
:::
<!-- prettier-ignore-end -->

### 2. Commit the changes

Let's commit our changes:

:::code{showCopyAction=true showLineNumbers=false language=bash highlightLines='0'}
cd $GITOPS_DIR/workload
git add .
git commit -m "add staging manifests for webstore microservices"
git push
:::



### 3. Validate the deployment

:::alert{header="Important" type="warning"}
It takes a few minutes for ArgoCD to synchronize, and then for Karpenter to provision the additional node.
It also takes a few minutes for the load balancer to be provisioned correctly.
:::

To access the webstore application, run:

```bash
app_url_staging
```

Access the webstore in the browser.

![webstore](/static/images/webstore-ui.png)


