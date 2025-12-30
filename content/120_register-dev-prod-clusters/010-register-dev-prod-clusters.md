---
title: "Register Dev & Prod Clusters"
weight: 10
---

Now that we have established hub-spoke access, we need to register the dev and prod clusters with ArgoCD so it can deploy applications to these environments. This step activates the cluster registration automation we set up earlier.

### Why Register Dev & Prod Clusters?

In upcoming chapters, we'll deploy applications to dev and prod environments. ArgoCD needs to know about these clusters to:
- Deploy applications to the correct target environments
- Monitor application health across all clusters  


### How the Automation Works

In the "Automate Cluster Registration" chapter, we created an ApplicationSet that monitors the `register-cluster/` folder. When we add cluster configuration files to this folder, the ApplicationSet automatically:

1. Detects New Folders: Scans for new directories under `register-cluster/`
2. Creates Applications: Generates ArgoCD Applications for each cluster
3. Deploys Helm Chart: Uses the `argocd-cluster-secret` chart to create cluster secrets
4. Registers Clusters: Makes clusters available for application deployment

### Implementation

We'll add configuration files for both dev and prod clusters to trigger the automated registration process.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash }

# Copy dev and prod cluster configuration files
mkdir -p $GITOPS_DIR/platform/register-cluster/dev
cp $WORKSHOP_DIR/gitops/templates/register-cluster/dev-register-cluster-values.yaml $GITOPS_DIR/platform/register-cluster/dev/values.yaml

mkdir -p $GITOPS_DIR/platform/register-cluster/prod  
cp $WORKSHOP_DIR/gitops/templates/register-cluster/prod-register-cluster-values.yaml $GITOPS_DIR/platform/register-cluster/prod/values.yaml

# Commit and push to trigger automation
cd $GITOPS_DIR/platform
git add .
git commit -m "add dev and prod cluster registration values"
git push 
:::
<!-- prettier-ignore-end -->



### Verification

Navigate to ArgoCD dashboard **Settings > Clusters** to validate cluster registration. You should see:
- ✅ **hub** (existing)
- ✅ **dev** (newly registered)  
- ✅ **prod** (newly registered)

![Hub-Spoke Access Architecture](/static/images/register-dev-prod-clusters/register-dev-prod-clusters.png)




