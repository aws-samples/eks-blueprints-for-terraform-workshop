---
title: "Bootstrap"
weight: 10
---

**This chapter sets up one of the foundational building blocks in Argo CD automation**

In this chapter, we begin the automation process. You'll configure Argo CD to automatically detect when a new add-on, namespace, or workload is enabled via a label and generate the corresponding Application resource. This is one of several steps that will build on each other throughout the workshop.

We’ll configure a bootstrap application that uses the App of Apps pattern to watch a folder - bootstrap in your platform Git repository. Any files in this folder get processed automatically.

![Hub Cluster Updated Metadata](/static/images/bootstrap-empty.png)



### 1. Create bootstrap applicationset

The ApplicationSet creates a new Argo CD Application named "bootstrap" that points to the platform/bootstrap directory in our Git repository.


<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='16,22,23,24'}
mkdir -p ~/environment/hub/bootstrap
cat > ~/environment/hub/bootstrap/bootstrap-applicationset.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: bootstrap
  namespace: argocd
spec:
  goTemplate: true
  syncPolicy:
    preserveResourcesOnDeletion: true
  generators:
    - clusters:
        selector:
          matchLabels:
            fleet_member: hub
  template:
    metadata:
      name: 'bootstrap'
    spec:
      project: default
      source:
        repoURL: '{{ .metadata.annotations.platform_repo_url }}'
        path: '{{ .metadata.annotations.platform_repo_basepath }}{{ .metadata.annotations.platform_repo_path }}'
        targetRevision: '{{ .metadata.annotations.platform_repo_revision }}'
        directory:
          recurse: true
      destination:
        namespace: 'argocd'
        name: '{{ .name }}'
      syncPolicy:
        automated:
          allowEmpty: true

EOF

:::
<!-- prettier-ignore-end -->

Note Lines 22–24 use annotations from the Argo CD cluster secret. You can check values in your current environment.

```bash
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o json | jq ".metadata.annotations.platform_repo_url" -r
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o json | jq ".metadata.annotations.platform_repo_basepath" -r
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o json | jq ".metadata.annotations.platform_repo_path" -r
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o json | jq ".metadata.annotations.platform_repo_revision" -r
```


The output should be similar to the following. It should point to bootstrap folder of platform repo:

```
https://d3mkl1q53qn8v6.cloudfront.net/gitea/workshop-user/eks-blueprints-workshop-gitops-platform

bootstrap
HEAD
```

### 2. Add fleet_member label
The ApplicationSet generator (line 16) filters clusters that have the label fleet_member = hub. Let’s add this label to the hub cluster definition.


![Hub Cluster Metadata](/static/images/hubcluster-initial-labels.png)

Lets add fleet_member label.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=true language=json highlightLines='5'}
cat <<'EOF' >> ~/environment/hub/main.tf

locals{
  addons = merge(
    { fleet_member = "hub" },
    { tenant = "tenant1" },
    #enableaddonvariable local.aws_addons,
    #enableaddonvariable local.oss_addons,
    #enablewebstore{ workload_webstore = true }  
  )

}

EOF
:::
<!-- prettier-ignore-end -->


### 3. Update labels

We need to update addons labels on the hub-cluster object. To do this, we will use the GitOps Bridge. The GitOps Bridge is configured to update labels on the specified cluster object.

```bash
sed -i "s/#enableaddons//g" ~/environment/hub/main.tf
```

The code above uncomments the addons variables in main.tf, as highlighted below.

<!-- prettier-ignore-start -->
:::code{language=yml showCopyAction=false showLineNumbers=false highlightLines='8'}
module "gitops_bridge_bootstrap" {
  source = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.0.1"
  cluster = {
    cluster_name = module.eks.cluster_name
    environment = local.environment
    #enableannotation metadata = local.annotations
    addons = local.addons
}
:::
<!-- prettier-ignore-end -->


### 4. GitOps Bridge root application

We have created bootstrap ApplicationSet in step 1. We will use GitOps Bridge to create this ApplicationSet.

```bash
sed -i "s/#enableapps //g" ~/environment/hub/main.tf
```

The code provided above uncomments GitOps Bridge to create the Argo CD Application. In this case, it creates the bootstrap Application.

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='10-10'}
module "gitops_bridge_bootstrap" {
  source = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.0.1"
  cluster = {
    cluster_name = module.eks.cluster_name
    environment = local.environment
    #enableannotation metadata = local.addons_metadata
    addons = local.addons
  }
  apps = local.argocd_apps
  argocd = {
    namespace = local.argocd_namespace
  ...
:::
<!-- prettier-ignore-end -->


### 5. Add variable to read bootstrap applicationset

```bash
cat <<'EOF' >> ~/environment/hub/main.tf
locals{
  argocd_apps = {
    bootstrap   = file("${path.module}/bootstrap/bootstrap-applicationset.yaml")
  }
}
EOF
```


### 6. Apply Terraform

```bash
cd ~/environment/hub
terraform apply --auto-approve
```

### 7. Validate bootstrap Application

Navigate to the Argo CD dashboard in the UI and click on **Applications** to validate that the **bootstrap** Application was created successfully. The bootstrap Argo CD Application is currently configured to point to the `bootstrap` folder in our platform Git repository.
![bootstrap-application](/static/images/bootstrap-application.jpg)

The folder is currently empty. In the upcoming chapters, you'll populate it with ApplicationSet files for add-ons, namespaces, projects, and workloads.

![bootstrap-application](/static/images/platform-repo-empty.png)
