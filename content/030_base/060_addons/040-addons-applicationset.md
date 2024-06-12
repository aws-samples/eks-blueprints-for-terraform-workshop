---
title: 'Addons ApplicationSet'
weight: 40
---

The focus of this chapter is to set up Argo CD to install and manage add-ons for EKS clusters.

### 1. Clone repository

Make a clone of your GitHub repository locally so that you can add applicationset files to it. Instead of cloning the entire repo, checkout only `assets` folder to keep things simple using sparse-checkout. (Note, this also checkouts files not tied to a directory)


```bash
cd ~/environment
git clone --no-checkout https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_LOGIN}/eks-blueprints-for-terraform-workshop.git wgit
cd wgit
git sparse-checkout init --cone
git sparse-checkout set assets
git checkout
```

::::expand{header="What is in my cloned repo?"}
This repository contains resources for managing Kubernetes clusters in the **assets** directory. It includes Kubernetes YAML files for deploying workloads, ApplicationSets, and configuration values for addons, namespaces, and projects.

![Kubernetes Addons](/static/images/platform-github-folders.png)
::::

### 2. Configure Addons ApplicationSet

Previously, you created an "App of Apps" Application that referenced the "appofapps" folder to include all the files in this folder. You will add "cluster-addons" Argo CD Application, which is configured to point to the cloned copy of the GitOps Bridge ApplicationSet repository in your own Git repo. Addons repo is under `assets/platform/addons/applicationset` folder.

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

### 3. Commit addons ApplicationSet to Git

 When pushing to from a remote git repository, if you haven't authenticated before, it will prompt you for your credentials.

```bash
cd ~/environment/wgit
git add .
git commit -m "add addons applicationset"
git push
```

> You may need to authenticate with username="<your github login>" and password="<github token>" to push on the repository

### 4. Validate addons ApplicationSet

::alert[The default configuration for Argo CD is to check for updates in a git repository every 3 minutes. It might take upto 3 minutes to recognize the new file in the git repo. Click on REFRESH APPS on the Argo CD Dashboard to refresh rightaway.]{header="cluster-addons Application"}

Navigate to the Argo CD dashboard in the UI and verify that the "cluster-addons" Application was created successfully.

![addons-rootapp](/static/images/addons-rootapp.png)

In the Argo CD dashboard, click on the "appofapps" Application and examine the list of Applications that were generated from it.

![addons-rootapp](/static/images/cluster-addon-creation-flow.png)

In the Argo CD UI, click on the "Applications" on the left navigation bar. Click on the "cluster-addons" Application to see all of the ApplicationSets that were generated. Reviewing the ApplicationSet list under the "cluster-addons" Application shows all of the available add-ons curated by GitOps Bridge, even though they are not yet deployed into the EKS cluster.

![addons-rootapp](/static/images/cluster-addons-applicationset.png)





