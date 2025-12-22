---
title: "Bootstrap the Cluster Repository"
weight: 10
---

### 3. ECR ReadOnly access 

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cat <<'EOF' >> ~/environment/hub/main.tf
################################################################################
# IAM policy for ECR Helm chart access
################################################################################
resource "aws_iam_policy" "ecr_helm_readonly" {
  name        = "ecr-helm-readonly-policy"
  description = "Read-only access to ECR for Helm charts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:ListImages"
        ]
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "argocd_ecr_helm" {
  role       = aws_iam_role.eks_capability_argocd.name
  policy_arn = aws_iam_policy.ecr_helm_readonly.arn
}
EOF
cd ~/environment/hub
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->


### 1. Register Hub Cluster

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }

cp  /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/bootstrap/register-cluster.yaml $GITOPS_DIR/platform/bootstrap
cd ${GITOPS_DIR}/platform/bootstrap
git add .
git commit -m "add bootstrap cluster registration"
git push 
:::
<!-- prettier-ignore-end -->

### 2. Copy Values

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
mkdir -p $GITOPS_DIR/platform/register-cluster/hub
cp /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/hub-register-cluster-values.yaml $GITOPS_DIR/platform/register-cluster/hub/values.yaml
mkdir -p $GITOPS_DIR/platform/register-cluster/dev
cp /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/dev-register-cluster-values.yaml $GITOPS_DIR/platform/register-cluster/dev/values.yaml
mkdir -p $GITOPS_DIR/platform/register-cluster/prod
cp /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/prod-register-cluster-values.yaml $GITOPS_DIR/platform/register-cluster/prod/values.yaml

cp /home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/default-register-cluster-values.yaml $GITOPS_DIR/platform/register-cluster/values.yaml
cd $GITOPS_DIR/platform
git add .
git commit -m "add hub cluster registration values and default registration values"
git push 
:::
<!-- prettier-ignore-end -->










<!-- cspell:disable-next-line -->

::video{id=pqw8FHhTiQY}

We'll configure an application to watch a folder - bootstrap in your platform Git repository. Any files in this folder get processed automatically.

![Hub Cluster Updated Metadata](/static/images/bootstrap-empty.png)

In upcoming chapters you will add files to this folder for addon, namespace and workload automation.

# Create the Bootstrap ApplicationSet

The ApplicationSet creates a new ArgoCD Application named "bootstrap" that points to the platform/bootstrap directory in the platform Git repository.

### 1. Create the Bootstrap ApplicationSet

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

Note Lines 22–24 use annotations from the ArgoCD cluster secret.

You can check values in your current environment.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o json | jq ".metadata.annotations.platform_repo_url" -r
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o json | jq ".metadata.annotations.platform_repo_basepath" -r
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o json | jq ".metadata.annotations.platform_repo_path" -r
kubectl --context hub-cluster get secrets -n argocd hub-cluster -o json | jq ".metadata.annotations.platform_repo_revision" -r
:::
<!-- prettier-ignore-end -->

The output should be similar to the following. It should point to bootstrap folder of platform repo. You will notice platform_repo_basepath is not used in this workshop so it is set to empty string:

```
https://d3mkl1q53qn8v6.cloudfront.net/gitea/workshop-user/eks-blueprints-workshop-gitops-platform

bootstrap
HEAD
```

### 2. Reference the Bootstrap ApplicationSet in Terraform

We created bootstrap applicationset in ~/environment/hub/bootstrap/bootstrap-applicationset.yaml. Let's recreate a variable to reference that.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
cat <<'EOF' >> ~/environment/hub/main.tf
locals{
  argocd_apps = {
    bootstrap   = file("${path.module}/bootstrap/bootstrap-applicationset.yaml")
  }
}
EOF
:::
<!-- prettier-ignore-end -->

### 3. Deploy the Bootstrap ApplicationSet using GitOps Bridge

We created a variable to reference bootstrap ApplicationSet in the previous step. We will use GitOps Bridge to create this ApplicationSet.

```bash
sed -i "s/#enableapps //g" ~/environment/hub/main.tf
```

The code provided above uncomments GitOps Bridge to create the ArgoCD Application. In this case, it creates the bootstrap Application.

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml highlightLines='10-10'}
module "gitops_bridge_bootstrap" {
  source = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.0.1"
  cluster = {
    cluster_name = module.eks.cluster_name
    environment = local.environment
    #enableannotation metadata = local.addons_metadata
    #enableaddons addons = local.addons
  }
  apps = local.argocd_apps
  argocd = {
    namespace = local.argocd_namespace
  ...
:::
<!-- prettier-ignore-end -->

# Label the hub-cluster

### 1. Add fleet_member label variable

The ApplicationSet cluster generator (line 16) filters clusters that have the label fleet_member = hub. Let's add this label to the hub cluster definition.

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

### 2. Enable Label Injection via GitOps Bridge

We will use GitOps Bridge to add labels to the hub-cluster object. The GitOps Bridge is configured to add labels on the specified cluster object.

<!-- prettier-ignore-start -->
:::code{language=yml showCopyAction=true showLineNumbers=false }
sed -i "s/#enableaddons//g" ~/environment/hub/main.tf
:::
<!-- prettier-ignore-end -->

The code above uncomments the addons variables in main.tf, as highlighted below. Any value assigned to GitOps Bridge `addons` (Line 8) variable gets assigned to the cluster label.

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

# Apply Terraform

```bash
cd ~/environment/hub
terraform apply --auto-approve
```

### Validate the Bootstrap Application in ArgoCD

Navigate to the ArgoCD dashboard in the UI and click on **Applications** to validate that the **bootstrap** Application was created successfully. The bootstrap ArgoCD Application is currently configured to point to the `bootstrap` folder in our platform Git repository.
![bootstrap-application](/static/images/bootstrap-application.jpg)

The folder is currently empty. In the upcoming chapters, you'll populate it with ApplicationSet files for add-ons, namespaces, projects, and workloads.

![bootstrap-application](/static/images/platform-repo-empty.png)
