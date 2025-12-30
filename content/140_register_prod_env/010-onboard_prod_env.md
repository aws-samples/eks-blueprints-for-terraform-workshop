---
title: "Onboard Prod Environment"
weight: 20
---

---
title: "Onboard Prod Environment"
weight: 20
---

In the previous chapter, you onboarded the retail-store team to the dev environment. Now we'll extend their deployment to the production environment by adding prod configuration to their existing team setup.

### Multi-Environment Strategy

Rather than creating separate team configurations, we'll:
- **Extend environments.yaml**: Add prod environment to the existing configuration
- **Add Environment Overrides**: Use `prod-values.yaml` files for production-specific settings
- **Leverage Values Hierarchy**: Base configuration from `default-values.yaml` + prod overrides

This approach maintains consistency while allowing environment-specific customizations.

### Implementation

Let's extend the retail-store team to the prod environment:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash }

# Append Prod environment configuration to existing environments.yaml
cat <<'EOF' >> $GITOPS_DIR/platform/register-team/retail-store/environments.yaml
  - env: prod
    cluster: prod
    versions:
      cart: "1.3.0"
      checkout: "1.3.0"
      catalog: "1.3.0"
      ui: "1.3.0"
      orders: "1.3.0"
EOF

# Copy prod-specific namespace overrides
# These override default-values.yaml for production-specific settings
cp $WORKSHOP_DIR/gitops/templates/namespace/prod-values.yaml \
   $GITOPS_DIR/platform/register-team/retail-store/namespace/

# Copy prod-specific ArgoCD project overrides  
cp $WORKSHOP_DIR/gitops/templates/project/prod-values.yaml \
   $GITOPS_DIR/platform/register-team/retail-store/project/

# Commit and push to trigger prod environment onboarding
cd ${GITOPS_DIR}/platform
git add .
git commit -m "onboard retail-store team to prod environment"
git push 
:::
<!-- prettier-ignore-end -->

### What Happens Next

After pushing the prod configuration:

1. **ApplicationSet Detection**: The register-team ApplicationSet detects the updated environments.yaml
2. **Prod Applications Creation**: ArgoCD creates `retail-store-prod-*` Applications for each microservice
3. **Namespace Deployment**: Creates the `retail-store` namespace on prod cluster using:
   - **Base Configuration**: `default-values.yaml` (shared settings)
   - **Prod Overrides**: `prod-values.yaml` (production-specific settings like resource limits, security policies)
4. **Project Updates**: Updates the `retail-store` ArgoCD project with prod permissions
5. **Application Deployment**: Deploys retail-store microservices to prod cluster

### Values Hierarchy in Action

The namespace configuration demonstrates the values hierarchy:
```yaml
# default-values.yaml (base configuration)
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"

# prod-values.yaml (production overrides)  
resources:
  requests:
    memory: "256Mi"    # Higher memory for prod
    cpu: "200m"        # Higher CPU for prod
  limits:
    memory: "512Mi"    # Add limits for prod
    cpu: "500m"
```

### Verification

Check the prod onboarding progress in ArgoCD:

#### **Applications View:**
- ✅ `register-team-retail-store` - Team onboarding Application (should be Synced)
- ✅ `retail-store-dev-*` - Dev microservice Applications (existing)
- ✅ `retail-store-prod-*` - **New** prod microservice Applications (cart, catalog, etc.)

#### **Projects View:**
- ✅ `retail-store` - Team project now managing both dev and prod

#### **Clusters View:**
- **Dev Cluster**: `retail-store` namespace (existing)
- **Prod Cluster**: `retail-store` namespace (**newly created** with prod-specific settings)

### Accessing the Applications

Once deployed, you can access the retail-store application in both environments:

#### **Dev Environment:**
1. Get the LoadBalancer URL from the `ui` service in dev cluster's `retail-store` namespace
2. Navigate to the URL to see the dev e-commerce application

#### **Prod Environment:**
1. Get the LoadBalancer URL from the `ui` service in prod cluster's `retail-store` namespace  
2. Navigate to the URL to see the production e-commerce application

### Next Steps

With both dev and prod environments onboarded, you can:
- **Version Management**: Update application versions independently per environment in `environments.yaml`
- **Environment-Specific Configuration**: Modify `prod-values.yaml` for production-specific settings
- **Team Scaling**: Onboard additional teams using the same multi-environment pattern
- **GitOps Workflows**: Implement promotion workflows from dev to prod

This demonstrates **enterprise-grade GitOps** - managing complex multi-environment deployments with environment-specific overrides through simple Git operations.
