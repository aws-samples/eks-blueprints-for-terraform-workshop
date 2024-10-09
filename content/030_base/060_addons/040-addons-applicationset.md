---
title: "Addons ApplicationSet"
weight: 40
---

The focus of this chapter is to set up Argo CD to install and manage add-ons for EKS clusters.

### 1. Configure Addons ApplicationSet

Previously, you created an "App of Apps" Application that referenced the "**bootstrap**" folder. You will add "addons-aws-load-balancer-controller-appset" Argo CD ApplicationSet in this bootstrap folder, which is configured to point to the GitOps Bridge v2 structured repository, which is already in your own "**~/environment/gitops-repos/addons**" repo.

Let's add the cluster-addons ApplicationSet in this repo:

```bash
cp $BASE_DIR/solution/gitops/platform/bootstrap/addons-applicationset.yaml $GITOPS_DIR/platform/bootstrap/addons-applicationset.yaml
```

Let's commit and push the changes to the repo:

```bash
git -C ${GITOPS_DIR}/platform add .  || true
git -C ${GITOPS_DIR}/platform commit -m "add addon applicationset" || true
git -C ${GITOPS_DIR}/platform push || true
```

### 2. Validate addons ApplicationSet

Navigate to the Argo CD dashboard in the UI and verify that the "cluster-addons" Application was created successfully.

![addons-rootapp](/static/images/addons-rootapp.jpg)

In the Argo CD dashboard, click on the "bootstrap" Application and examine the list of Applications that were generated from it.

![addons-rootapp](/static/images/cluster-addon-creation-flow.jpg)

For now there is no addons, as we didn't activate their deployment.

:::alert{header="Important" type="info"}
The ApplicationSet **cluster-addons**, point to the **eks-blueprint-workshop-gitops-addons** git repository which is synchronized from `~/environment/gitops-repos/addons` directory.
:::
