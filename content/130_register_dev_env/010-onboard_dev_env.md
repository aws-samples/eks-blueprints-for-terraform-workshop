---
title: "Register Dev Environment"
weight: 20
---
<!-- cspell:disable-next-line -->
::video{id=DEHzOZ4Wwzg}


Now that we have registered our dev and prod clusters, we can register our first application team. In this chapter, we'll register the retail-store team to the dev environment, which will automatically create their namespace, ArgoCD project, and deploy their applications.

### What is Team Registeration?

Team registering in a GitOps platform involves:

- Namespace Creation: Isolated environment for team resources
- ArgoCD Project: Scoped permissions and policies for the team
- Application Deployment: Automated deployment of team's microservices

This enables teams to self-service their deployments while maintaining platform governance.

### How the Automation Works

In the "Automate Team Registration" chapter, we set up an ApplicationSet that monitors the `register-team/` folder. When we add team configuration, it automatically:

1. Detects Team Folders: Scans for new team directories
2. Creates Namespace: Deploys namespace resources for isolation
3. Sets up ArgoCD Project: Configures team-specific permissions
4. Deploys Applications: Launches the retail-store microservices

### Team Structure

The retail-store team configuration includes:

- **environments.yaml**: Defines which applications(helm charts) to deploy and their versions
- **namespace/**: Kubernetes namespace configuration with values hierarchy
  - `default-values.yaml`: Base namespace configuration (RBAC, quotas, policies)
  - `dev-values.yaml`: Dev-specific overrides (optional)
  - `prod-values.yaml`: Prod-specific overrides (optional)
- **project/**: ArgoCD project settings and policies

The namespace Helm chart uses a **values hierarchy** where:

1. **Base Configuration**: `default-values.yaml` provides common settings for all environments
2. **Environment Overrides**: `<<env>>-values.yaml` files override specific values per environment
3. **Merge Strategy**: Environment-specific values take precedence over defaults

- project/: ArgoCD project settings and policies

### Implementation

Let's register the retail-store team to the dev environment:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash }
# Create retail-store team directory structure
mkdir -p $GITOPS_DIR/platform/register-team/retail-store

# Copy team environment configuration
cp $WORKSHOP_DIR/gitops/templates/retail-store-environments.yaml \
   $GITOPS_DIR/platform/register-team/retail-store/environments.yaml

# Copy namespace configuration with values hierarchy
# - default-values.yaml: Base configuration for all environments  
# - dev-values.yaml, prod-values.yaml: Environment-specific overrides (optional)
mkdir -p $GITOPS_DIR/platform/register-team/retail-store/namespace
cp $WORKSHOP_DIR/gitops/templates/namespace/default-values.yaml \
   $GITOPS_DIR/platform/register-team/retail-store/namespace/

# Copy ArgoCD project configuration (permissions, policies)
mkdir -p $GITOPS_DIR/platform/register-team/retail-store/project
cp $WORKSHOP_DIR/gitops/templates/project/dev-values.yaml \
   $GITOPS_DIR/platform/register-team/retail-store/project/

# Commit and push to trigger team registering
cd ${GITOPS_DIR}/platform
git add .
git commit -m "register retail-store team to dev environment"
git push 
:::
<!-- prettier-ignore-end -->

### What Happens Next

After pushing the team configuration:

1. ApplicationSet Detection: The register-team ApplicationSet detects the new retail-store folder
2. Team Application Creation: ArgoCD creates a `register-team-retail-store` Application
3. Namespace Deployment: Creates the `retail-store` namespace with RBAC and policies
4. Project Creation: Sets up the `retail-store` ArgoCD project with team permissions
5. Application Deployment: Deploys retail-store microservices (cart, catalog, checkout, orders, ui) to dev cluster

### Verification

Check the registering progress in ArgoCD:

#### Applications View:

- ✅ `register-team-retail-store` - Team registering Application (should be Synced)
- ✅ `retail-store-dev-*` - Individual microservice Applications (cart, catalog, etc.)

#### Projects View:

- ✅ `retail-store` - Team-specific project with scoped permissions

#### Clusters View (dev cluster):

- ✅ `retail-store` namespace created
- ✅ Microservices deployed and running

### Accessing the Application

Once deployed, you can access the retail-store application from the terminal:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash }
app_url_dev
:::
<!-- prettier-ignore-end -->
### Next Steps

With the dev environment successfully registered, you can:

- Deploy updates by modifying application versions in `environments.yaml`
- register additional teams using the same pattern
- Extend to production environments following similar processes

This demonstrates the power of GitOps automation - complex multi-service deployments triggered by simple Git commits.
