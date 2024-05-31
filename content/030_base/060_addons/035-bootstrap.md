---
title: 'Bootstrap'
weight: 35
---

You want to configure ArgoCD such that when a new addon, namespace, or workload is enabled through label, ArgoCD should detect this and automatically generate the corresponding Application resource.

To automatically generate ArgoCD applications, you will implement the "App of Apps" pattern.

### App of Apps pattern

Normally an ArgoCD Application points to a git repo which contains mainifests. The loadbalancer controller you provisioned previously points to the git repo https://aws.github.io/eks-charts.

 
 ![applicationset](/static/images/lb-helmchart-folder.png)


In the App of Apps pattern, a top-level ArgoCD Application resource points to a Git repository folder that contains ApplicationSet files. The ApplicationSet files define how to generate the child Applications. 

![applicationset](/static/images/app-of-apps.png)


In this chapter, you will create a appofapps ArgoCD application that points to the `platform/appofapps` folder in your GitHub repository. As you commit applicationset files in this chapter and upcoming chapters in the repository, ArgoCD will automatically detect the changes and generate corresponding Applications.


![applicationset](/static/images/bootstrap-appofapps.png)


### 1. Clone repository

Make a clone of your GitHub repository locally so that you can add applicationset files to it.

```bash
cd ~/environment
```

Copy the provided code snippet, replace the placeholder value "<<replace with your github login>>" with your actual GitHub login, used to fork the repository. We use the full HTTPS clone URL in the format "https<span>://</span>github.com/<span><<</span>your github username<span>>></span>/<span><<</span>github repo name<span>>></span>.git". **Then execute the updated code.**

```bash
export GITHUB_LOGIN="<<replace with your github repo login>>"
```

Instead of cloning the entire repo, checkout only assets/platform/bootstrap folder to keep things simple.

```bash
git clone --no-checkout https://github.com/${GITHUB_LOGIN}/eks-blueprints-for-terraform-workshop.git wgit
cd wgit
git sparse-checkout init --cone
git sparse-checkout set assets
git checkout
```

::::expand{header="What is in my cloned repo?"}
This repository contains resources for managing Kubernetes clusters in the **assets** directory. It includes Kubernetes YAML files for deploying workloads, ApplicationSets, and configuration values for addons, namespaces, and projects.

![Kubernetes Addons](/static/images/platform-github-folders.png)
::::


### 2 Create appofapps applicationset 

The ApplicationSet creates a new ArgoCD Application named "appofapps" that points to the platform/appofapps directory in your Git repository.

```bash
mkdir ~/environment/hub/appofapps
cat > ~/environment/hub/appofapps/appofapps-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: appofapps
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
      name: 'appofapps'
    spec:
      project: default
      source:
        repoURL: '{{metadata.annotations.platform_repo_url}}'
        path: '{{metadata.annotations.platform_repo_basepath}}appofapps'
        targetRevision: '{{metadata.annotations.platform_repo_revision}}'
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


### 3. Local variable to read appofapps applicationset

```bash
cat <<'EOF' >> ~/environment/hub/main.tf
locals{
  argocd_apps = {
    appofapps   = file("${path.module}/appofapps/appofapps-applicationset.yaml")
  }
}
EOF
```

### 3. GitOps Bridge to create appofapps root application

```bash
sed -i "s/#enableapps//g" ~/environment/hub/main.tf
```
The code provided above uncomments GitOps Bridge to create the ArgoCD Application. In this case it creates appofapps Application.

:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='10-10'}
module "gitops_bridge_bootstrap" {
  source  = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.0.1"
  cluster = {
    cluster_name = module.eks.cluster_name
    environment  = local.environment
     metadata     = local.addons_metadata
     addons       = local.addons
  }
  apps = local.argocd_apps
  argocd = {
    namespace        = local.argocd_namespace
:::

### 4 Apply Terraform

```bash
cd ~/environment/hub
terraform apply --auto-approve
```

### 4 Validate appofapps Application

Navigate to the ArgoCD dashboard in the UI and validate that the appofapps Application was created successfully. The appofapps ArgoCD Application is currently configured to point to the `assets/platform/appofapps` folder in your Git repository. This folder is still empty. In the upcoming chapters, you will add applicationset files for add-ons, namespaces, projects, and workloads to this platform/appofapps directory.

![bootstrap-application](/static/images/bootstrap-application.png)
