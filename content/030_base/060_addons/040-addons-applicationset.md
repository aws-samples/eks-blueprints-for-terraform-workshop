---
title: 'Addons ApplicationSet'
weight: 40
---

The focus of this chapter is to set up ArgoCD to install and manage add-ons for EKS clusters.

### 1. Addons

Previously, you created an "App of Apps" Application that referenced the "appofapps" folder to include all the files in this folder. You will add "cluster-addons" ArgoCD Application, which is configured to point to the cloned copy of the GitOps Bridge ApplicationSet repository in your own Git repo. Addons repo is under `assets/platform/addons/applicationset` folder.

![cluster-addons](/static/images/cluster-addons.png)


```bash
cat > ~/environment/wgit/assets/platform/appofapps/addons-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cluster-addons
  namespace: argocd
spec:
  syncPolicy:
    preserveResourcesOnDeletion: true
  generators:
  - clusters:
      selector:
        matchLabels:
          environment: hub
  template:
    metadata:
      name: 'cluster-addons'
    spec:
      project: default
      source:
        repoURL: '{{metadata.annotations.addons_repo_url}}'
        path: '{{metadata.annotations.addons_repo_basepath}}{{metadata.annotations.addons_repo_path}}'
        targetRevision: '{{metadata.annotations.addons_repo_revision}}'
        directory:
          recurse: true
      destination:
        namespace: 'argocd'
        name: '{{name}}'
      syncPolicy:
        automated:
          allowEmpty: true
EOF
```

### 2. Commit addons ApplicationSet to Git

 When pushing to from a remote git repository, if you haven't authenticated before, it will prompt you for your credentials.

```bash
cd ~/environment/wgit
git add .
git commit -m "add addons applicationset"
git push
```

> You may need to authenticate with username="<your github login>" and password="<github token>" to push on the repository

### 3. Validate addons ApplicationSet

::alert[The default configuration for ArgoCD is to check for updates in a git repository every 3 minutes. It might take upto 3 minutes to recognize the new file in the git repo. Click on REFRESH APPS on the ArgoCD Dashboard to refresh rightaway.]{header="cluster-addons Application"}

Navigate to the ArgoCD dashboard in the UI and verify that the "cluster-addons" Application was created successfully.

![addons-rootapp](/static/images/addons-rootapp.png)

In the ArgoCD dashboard, click on the "appofapps" Application and examine the list of Applications that were generated from it.

![addons-rootapp](/static/images/cluster-addon-creation-flow.png)

In the ArgoCD UI, click on the "Applications" on the left navigation bar. Click on the "cluster-addons" Application to see all of the ApplicationSets that were generated. Reviewing the ApplicationSet list under the "cluster-addons" Application shows all of the available add-ons curated by GitOps Bridge, even though they are not yet deployed into the EKS cluster.

![addons-rootapp](/static/images/cluster-addons-applicationset.png)





