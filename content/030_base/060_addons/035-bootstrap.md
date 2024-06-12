---
title: 'Bootstrap'
weight: 35
---

You want to configure Argo CD such that when a new addon, namespace, or workload is enabled through label, Argo CD should detect this and automatically generate the corresponding Application resource.

To automatically generate Argo CD applications, you will implement the "App of Apps" pattern.

### App of Apps pattern

Normally an Argo CD Application points to a git repo which contains mainifests. The loadbalancer controller you provisioned previously points to the AWS EKS Helm Charts Repository https://aws.github.io/eks-charts, which contains an ìndex.yaml` file that reference the chart package (tgz file).

 
 ![applicationset](/static/images/lb-helmchart-folder.png)


In the App of Apps pattern, a top-level Argo CD Application resource points to a Git repository folder that contains ApplicationSet files. The ApplicationSet files define how to generate the child Applications. 

![applicationset](/static/images/app-of-apps.png)


In this chapter, you will create a appofapps Argo CD application that points to the `platform/appofapps` folder in your GitHub repository. As you commit applicationset files in this chapter and upcoming chapters in the repository, Argo CD will automatically detect the changes and generate corresponding Applications.


![applicationset](/static/images/bootstrap-appofapps.png)




### 1. Create appofapps applicationset 

The ApplicationSet creates a new Argo CD Application named "appofapps" that points to the platform/appofapps directory in your Git repository.

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

Note, that it uses the annotations from the secret like `{{metadata.annotations.platform_repo_url}}`, which means that it will retrieve the value from the secret, like we can do manually with:

```bash
kubectl --context hub get secrets -n argocd hub-cluster -o json | jq ".metadata.annotations.platform_repo_url"
```

### 2. Local variable to read appofapps applicationset

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
The code provided above uncomments GitOps Bridge to create the Argo CD Application. In this case it creates appofapps Application.

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

### 4. Apply Terraform

```bash
cd ~/environment/hub
terraform apply --auto-approve
```

### 5. Validate appofapps Application

Navigate to the Argo CD dashboard in the UI and validate that the appofapps Application was created successfully. The appofapps Argo CD Application is currently configured to point to the `assets/platform/appofapps` folder in your Git repository. This folder is still empty. In the upcoming chapters, you will add applicationset files for add-ons, namespaces, projects, and workloads to this platform/appofapps directory.

![bootstrap-application](/static/images/bootstrap-application.png)
