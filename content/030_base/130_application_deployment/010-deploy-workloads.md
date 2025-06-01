---
title: "Webstore Deployment"
weight: 10
---

So far, we have created the namespace for the Webstore workload.  The workload Git repository is already configured to be scanned and deployed automatically by Argo CD.

Currently, the Webstore application is **not deployed** because the workload Git repository is empty.

![Workload GitRepo](/static/images/workload-gitrepo-empty.png)

### Copy Webstore Dev environment

We will now copy the **Dev environment** to the Git repository. Remember, all environments (like `dev`) apply customizations on top of the shared `base` folder. We will copy both the `base` and `dev` folders.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=yaml highlightLines='22,32'}
for svc in /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/workload/webstore/*; do
  svc_name=$(basename $svc)
  mkdir -p ${GITOPS_DIR}/workload/webstore/$svc_name
  cp -r $svc/base  ${GITOPS_DIR}/workload/webstore/$svc_name/ 2>/dev/null
  cp -r $svc/dev   ${GITOPS_DIR}/workload/webstore/$svc_name/ 2>/dev/null
done
:::
<!-- prettier-ignore-end -->



### 2. Git commit

```bash
cd $GITOPS_DIR/workload
git add .
git commit -m "add bootstrap workload applicationset"
git push
```

![Workload GitRepo](/static/images/create-deployment-dev-webstore-deployment.png)


### 3. Validate workload

:::alert{header="Important" type="warning"}
It takes a few minutes for Argo CD to synchronize, and then for Karpenter to provision the additional node.
It also takes a few minutes for the load balancer to be provisioned correctly.
:::

To access the webstore application, run:

```bash
app_url_hub
```

Access the webstore in the browser.

![webstore](/static/images/webstore-ui.png)
