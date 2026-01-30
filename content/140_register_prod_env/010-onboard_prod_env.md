---
title: "Register Prod Environment"
weight: 20
---

<!-- cspell:disable-next-line -->

::video{id=JD4z00Erkus}

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
4. **Project Updates**: ArgoCD Prod project settings and policies
5. **Application Deployment**: Deploys retail-store microservices to prod cluster

### Values Hierarchy in Action

The namespace configuration demonstrates the values hierarchy:

<!-- prettier-ignore-start -->

:::code{showCopyAction=false showLineNumbers=false language=bash }

# default-values.yaml (base configuration)

resources:
requests:
memory: "128Mi"
cpu: "100m"

# prod-values.yaml (production overrides)

resources:
requests:
memory: "256Mi" # Higher memory for prod
cpu: "200m" # Higher CPU for prod
limits:
memory: "512Mi" # Add limits for prod
cpu: "500m"
:::

### Verification

Check the prod onboarding progress in ArgoCD dashboard:


::alert[It may take 3 minutes to show new applications created. You may see deployment applicationset in degraded status. Team automation creates project, namespace and deployment at the same time. Deployments have reference to the project that is not yet available. It will find the project in next reconciliation in 3 minutes. Please Refresh the browser. ]{header="Important" type="warning"}


![Onboard Prod](/static/images/registerprod/registerprod.png)


### Accessing the Application

Once deployed, you can access the retail-store application from the terminal:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash }
app_url_prod
:::
<!-- prettier-ignore-end -->

### Comparing Environment Configurations

You can see the differences between dev and prod environments by comparing their Helm values files.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash }
cd ~/environment/gitops-repos/retail-store-config
for service in cart catalog checkout orders ui; do
    echo "📦 $service:"
    diff -u $service/dev/values.yaml $service/prod/values.yaml | \
        grep -E '^[-+]' | \
        grep -v '^[-+][-+][-+]' | \
        sed 's/^-/  Dev:  /' | \
        sed 's/^+/  Prod: /'
    echo ""
done
:::
<!-- prettier-ignore-end -->

The comparison shows key differences between dev and prod configurations:

- **Replica Count**: All services run with 2 replicas in prod (vs 1 in dev) for high availability and load distribution
- **UI Theme**: The UI uses different color themes - green for dev and blue for prod - making it easy to visually distinguish environments

These environment-specific configurations demonstrate how the same application can be deployed with different settings based on operational requirements. Production prioritizes availability and performance, while dev focuses on resource efficiency.

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=bash }
📦 cart:
  Dev:  replicaCount: 1
  Prod: replicaCount: 2

📦 catalog:
  Dev:  replicaCount: 1
  Prod: replicaCount: 2

📦 checkout:
  Dev:  replicaCount: 1
  Prod: replicaCount: 2

📦 orders:
  Dev:  replicaCount: 1
  Prod: replicaCount: 2

📦 ui:
  Dev:  replicaCount: 1
  Prod: replicaCount: 2
  Dev:    theme: green
  Prod:   theme: blue
:::
<!-- prettier-ignore-end -->
