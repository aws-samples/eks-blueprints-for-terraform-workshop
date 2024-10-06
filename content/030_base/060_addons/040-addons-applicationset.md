---
title: 'Addons ApplicationSet'
weight: 40
---

The focus of this chapter is to set up Argo CD to install and manage add-ons for EKS clusters.

### 1. Configure Addons ApplicationSet

Previously, you created an "App of Apps" Application that referenced the "bootstrap" folder. You will add "cluster-addons" Argo CD ApplicationSet in bootstrap folder, which is configured to point to the cloned copy of the GitOps Bridge ApplicationSet repository in your own "addons" repo.

![cluster-addons](/static/images/cluster-addons.png)

 ~/environment/gitops-repos/addons
```bash
cp $BASE_DIR/solution/gitops/platform/bootstrap/addons-applicationset.yaml $GITOPS_DIR/platform/bootstrap/addons-applicationset.yaml
```

```bash
git -C ${GITOPS_DIR}/platform add .  || true
git -C ${GITOPS_DIR}/platform commit -m "add addon applicationset" || true
git -C ${GITOPS_DIR}/platform push || true
```

### 2. Validate addons ApplicationSet

::alert[The default configuration for Argo CD is to check for updates in a git repository every 3 minutes. It might take up to 3 minutes to recognize the new file in the git repo. Click on REFRESH APPS on the Argo CD Dashboard to refresh right away.]{header="cluster-addons Application"}

Navigate to the Argo CD dashboard in the UI and verify that the "cluster-addons" Application was created successfully.

![addons-rootapp](/static/images/addons-rootapp.jpg)

In the Argo CD dashboard, click on the "bootstrap" Application and examine the list of Applications that were generated from it.

![addons-rootapp](/static/images/cluster-addon-creation-flow.jpg)

In the Argo CD UI, click on the "Applications" on the left navigation bar. Click on the "cluster-addons" Application to see all of the ApplicationSets that were generated. Reviewing the ApplicationSet list under the "cluster-addons" Application shows all of the available add-ons curated by GitOps Bridge, even though they are not yet deployed into the EKS cluster.

![addons-rootapp](/static/images/cluster-addons-applicationset.jpg)


:::alert{header="Important" type="info"}
The ApplicationSet **cluster-addons**, point to the **eks-blueprint-workshop-gitops-addons** git repository which is synchronised from `~/environment/gitops-repos/addons` directory.
:::


