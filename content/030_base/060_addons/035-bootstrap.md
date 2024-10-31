---
title: "Bootstrap"
weight: 35
---

We want to configure Argo CD so that when a new addon, namespace, or workload is enabled through a label, Argo CD automatically detects this and generates the corresponding Application resource.

To automatically generate Argo CD applications, we will implement the "App of Apps" pattern.

### App of Apps pattern

Normally an Argo CD Application points to a git repo which contains manifests. For example, when provisioning a load balancer controller, it points to the AWS EKS Helm Charts Repository https://aws.github.io/eks-charts, which contains an `ìndex.yaml` file that references the chart package (tgz file).

![applicationset](/static/images/lb-helmchart-folder.png)

In the App of Apps pattern, a top-level Argo CD Application resource points to a Git repository folder that contains ApplicationSet files. The ApplicationSet files define how to generate the child Applications.

![applicationset](/static/images/app-of-apps.png)

In this chapter, we will create a bootstrap Argo CD application that points to the `platform/bootstrap` folder in our Git repository. As we commit applicationset files in this chapter and upcoming chapters in the repository, Argo CD will automatically detect the changes and generate corresponding Applications.

![applicationset](/static/images/bootstrap-appofapps.png)

### 1. Create bootstrap applicationset

The ApplicationSet creates a new Argo CD Application named "bootstrap" that points to the platform/bootstrap directory in our Git repository.

```bash
mkdir -p ~/environment/hub/bootstrap
cat > ~/environment/hub/bootstrap/bootstrap-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: bootstrap
  namespace: argocd
spec:
  syncPolicy:
    preserveResourcesOnDeletion: true
  generators:
  - clusters:
      selector:
        matchLabels:
          environment: control-plane
  template:
    metadata:
      name: 'bootstrap'
    spec:
      project: default
      source:
        repoURL: '{{metadata.annotations.platform_repo_url}}'
        path: '{{metadata.annotations.platform_repo_basepath}}{{metadata.annotations.platform_repo_path}}'
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

Note that it uses the annotations from the secret like `{{metadata.annotations.platform_repo_url}}`, which means that it will retrieve the value from the secret, like we can do manually with:

```bash
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o json | jq ".metadata.annotations.platform_repo_url" -r
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o json | jq ".metadata.annotations.platform_repo_path" -r
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o json | jq ".metadata.annotations.platform_repo_revision" -r
```

the Output should be similar to:

```
https://d1nkjb4pxwlir8.cloudfront.net/gitea/workshop-user/eks-blueprints-workshop-gitops-platform
bootstrap
HEAD
```

### 2. Local variable to read bootstrap applicationset

```bash
cat <<'EOF' >> ~/environment/hub/main.tf
locals{
  argocd_apps = {
    bootstrap   = file("${path.module}/bootstrap/bootstrap-applicationset.yaml")
  }
}
EOF
```

### 3. GitOps Bridge to create bootstrap root application

```bash
sed -i "s/#enableapps //g" ~/environment/hub/main.tf
```

The code provided above uncomments GitOps Bridge to create the Argo CD Application. In this case it creates bootstrap Application.

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='10-10'}
module "gitops_bridge_bootstrap" {
  source = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.0.1"
  cluster = {
    cluster_name = module.eks.cluster_name
    environment = local.environment
    metadata = local.addons_metadata
    addons = local.addons
  }
  apps = local.argocd_apps
  argocd = {
    namespace = local.argocd_namespace
  ...
:::
<!-- prettier-ignore-end -->

### 4. Apply Terraform

```bash
cd ~/environment/hub
terraform apply --auto-approve
```

### 5. Validate bootstrap Application

Navigate to the Argo CD dashboard in the UI and click on **Applications** to validate that the **bootstrap** Application was created successfully. The bootstrap Argo CD Application is currently configured to point to the `assets/platform/bootstrap` folder in our Git repository. This folder is still empty. In the upcoming chapters, we will add applicationset files for add-ons, namespaces, projects, and workloads to this platform/bootstrap directory.

![bootstrap-application](/static/images/bootstrap-application.jpg)
