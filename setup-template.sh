#!/bin/bash

set -e

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $ACCOUNT_ID"

# Function to setup ArgoCD context
setup_argocd_context() {
    local cluster_name=$1
    local context_name=$2
    
    echo "Setting up ArgoCD context for cluster: $cluster_name with context: $context_name"
    
    # Update kubeconfig for the cluster with custom alias
    aws eks update-kubeconfig \
      --name $cluster_name \
      --region ${AWS_REGION:-us-west-2} \
      --alias $context_name
    
    # Set kubectl context
    kubectl config use-context "$context_name"
    
    # Verify connection
    kubectl get nodes
    
    echo "Successfully configured context: $context_name for cluster: $cluster_name"
    echo "---"
}

# Function to update template files
update_templates() {
    echo "Updating template files with cluster ARNs and secrets..."
    
    # Retry logic for getting hub cluster ARN
    # Get hub cluster ARN
    HUB_CLUSTER_ARN=$(aws eks describe-cluster --name argocd-hub --region ${AWS_REGION:-us-west-2} --query 'cluster.arn' --output text 2>/dev/null)
    echo "Hub cluster ARN: $HUB_CLUSTER_ARN"
    
    # Get repo org and credentials
    PLATFORM_URL="https://git-codecommit.${AWS_REGION}.amazonaws.com/v1/repos/platform"
    RETAIL_STORE_CONFIG_URL="https://git-codecommit.${AWS_REGION}.amazonaws.com/v1/repos/retail-store-config"
    echo "Platform URL: $PLATFORM_URL"
    echo "Retail Store Config URL: $RETAIL_STORE_CONFIG_URL"
    
    # Update register-hub-cluster-manual.yaml template
    TEMPLATE_FILE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/register-hub-cluster-manual.yaml"
    
    if [ -f "$TEMPLATE_FILE" ]; then
        # Get ECR registry URL
        ECR_REGISTRY_URL="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
        
        sed -i.bak \
            -e "s|<<arn>>|$HUB_CLUSTER_ARN|g" \
            -e "s|<<platform_url>>|$PLATFORM_URL|g" \
            -e "s|<<oci_registry_url>>|$ECR_REGISTRY_URL|g" \
            "$TEMPLATE_FILE"
        echo "Updated $TEMPLATE_FILE with hub cluster ARN, platform URL, and ECR registry URL"
    else
        echo "Warning: Template file $TEMPLATE_FILE not found"
    fi
    
    # Update register-platform-repo-manual.yaml template
    PLATFORM_REPO_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/register-repo/register-platform-repo-manual.yaml"
    
    if [ -f "$PLATFORM_REPO_TEMPLATE" ]; then
        sed -i.bak \
            -e "s|<<url>>|$PLATFORM_URL|g" \
            "$PLATFORM_REPO_TEMPLATE"
        echo "Updated $PLATFORM_REPO_TEMPLATE with platform repo URL"
    else
        echo "Warning: Template file $PLATFORM_REPO_TEMPLATE not found"
    fi
    
    # Update hub-cluster-values.yaml template
    # HUB_CLUSTER_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/hub-cluster-values.yaml"
    
    # if [ -f "$HUB_CLUSTER_VALUES_TEMPLATE" ]; then
    #     sed -i.bak "s|<<arn>>|$HUB_CLUSTER_ARN|g" "$HUB_CLUSTER_VALUES_TEMPLATE"
    #     echo "Updated $HUB_CLUSTER_VALUES_TEMPLATE with hub cluster ARN"
    # else
    #     echo "Warning: Template file $HUB_CLUSTER_VALUES_TEMPLATE not found"
    # fi
    
    # Get secret ARN for repo credentials (if using AWS Secrets Manager for CodeCommit)
    # Note: CodeCommit typically uses IAM authentication, not stored secrets
    # REPO_CREDENTIALS_SECRET_ARN=$(aws secretsmanager describe-secret --secret-id argocd-workshop-repo --query 'ARN' --output text 2>/dev/null || echo "")
    
    # Update platform-repo-values.yaml template
    PLATFORM_REPO_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/register-repo/platform-repo-values.yaml"
    
    if [ -f "$PLATFORM_REPO_VALUES_TEMPLATE" ]; then
        sed -i.bak \
            -e "s|<<url>>|$PLATFORM_URL|g" \
            "$PLATFORM_REPO_VALUES_TEMPLATE"
        echo "Updated $PLATFORM_REPO_VALUES_TEMPLATE with platform URL"
    else
        echo "Warning: Template file $PLATFORM_REPO_VALUES_TEMPLATE not found"
    fi
    
    # Update retail-store-config-repo-values.yaml template
    RETAIL_STORE_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/register-repo/retail-store-config-repo-values.yaml"
    
    if [ -f "$RETAIL_STORE_VALUES_TEMPLATE" ]; then
        sed -i.bak \
            -e "s|<<url>>|$RETAIL_STORE_CONFIG_URL|g" \
            "$RETAIL_STORE_VALUES_TEMPLATE"
        echo "Updated $RETAIL_STORE_VALUES_TEMPLATE with retail store config URL"
    else
        echo "Warning: Template file $RETAIL_STORE_VALUES_TEMPLATE not found"
    fi

    # Update retail-store-environments.yaml template
    RETAIL_STORE_ENV_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/retail-store-environments.yaml"
    
    if [ -f "$RETAIL_STORE_ENV_TEMPLATE" ]; then
        sed -i.bak "s|<<url>>|$RETAIL_STORE_CONFIG_URL|g" "$RETAIL_STORE_ENV_TEMPLATE"
        echo "Updated $RETAIL_STORE_ENV_TEMPLATE with retail store config URL"
    else
        echo "Warning: Template file $RETAIL_STORE_ENV_TEMPLATE not found"
    fi

    # Update dev-register-cluster-values.yaml template
    DEV_CLUSTER_REG_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/dev-register-cluster-values.yaml"
    
    if [ -f "$DEV_CLUSTER_REG_VALUES_TEMPLATE" ]; then
        # Get dev cluster server ARN
        DEV_CLUSTER_ARN=$(aws eks describe-cluster --name argocd-spoke-dev --query 'cluster.arn' --output text 2>/dev/null || echo "")
        if [ -z "$DEV_CLUSTER_ARN" ]; then
            echo "Warning: Could not get dev cluster ARN, using cluster name as fallback"
            DEV_CLUSTER_ARN="argocd-spoke-dev"
        fi
        
        sed -i.bak "s|<<arn>>|$DEV_CLUSTER_ARN|g" "$DEV_CLUSTER_REG_VALUES_TEMPLATE"
        echo "Updated $DEV_CLUSTER_REG_VALUES_TEMPLATE with dev cluster ARN: $DEV_CLUSTER_ARN"
    else
        echo "Warning: Template file $DEV_CLUSTER_REG_VALUES_TEMPLATE not found"
    fi

    # Update prod-register-cluster-values.yaml template
    PROD_CLUSTER_REG_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/prod-register-cluster-values.yaml"
    
    if [ -f "$PROD_CLUSTER_REG_VALUES_TEMPLATE" ]; then
        # Get prod cluster server ARN
        PROD_CLUSTER_ARN=$(aws eks describe-cluster --name argocd-spoke-prod --query 'cluster.arn' --output text 2>/dev/null || echo "")
        if [ -z "$PROD_CLUSTER_ARN" ]; then
            echo "Warning: Could not get prod cluster ARN, using cluster name as fallback"
            PROD_CLUSTER_ARN="argocd-spoke-prod"
        fi
        
        sed -i.bak "s|<<arn>>|$PROD_CLUSTER_ARN|g" "$PROD_CLUSTER_REG_VALUES_TEMPLATE"
        echo "Updated $PROD_CLUSTER_REG_VALUES_TEMPLATE with prod cluster ARN: $PROD_CLUSTER_ARN"
    else
        echo "Warning: Template file $PROD_CLUSTER_REG_VALUES_TEMPLATE not found"
    fi
    
    # Update bootstrap.yaml template
    BOOTSTRAP_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/bootstrap/bootstrap.yaml"
    
    if [ -f "$BOOTSTRAP_TEMPLATE" ]; then
        sed -i.bak "s|<<url>>|$PLATFORM_URL|g" "$BOOTSTRAP_TEMPLATE"
        echo "Updated $BOOTSTRAP_TEMPLATE with platform URL"
    else
        echo "Warning: Template file $BOOTSTRAP_TEMPLATE not found"
    fi
    
    # Update hub-register-cluster-values.yaml template
    HUB_CLUSTER_REG_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/hub-register-cluster-values.yaml"
    
    if [ -f "$HUB_CLUSTER_REG_VALUES_TEMPLATE" ]; then
        # Get ECR registry URL
        ECR_REGISTRY_URL="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
        
        sed -i.bak \
            -e "s|<<arn>>|$HUB_CLUSTER_ARN|g" \
            -e "s|<<url>>|$PLATFORM_URL|g" \
            -e "s|<<oci_registry_url>>|$ECR_REGISTRY_URL|g" \
            -e "s|<<retail_store_config_url>>|$RETAIL_STORE_CONFIG_URL|g" \
            "$HUB_CLUSTER_REG_VALUES_TEMPLATE"
        echo "Updated $HUB_CLUSTER_REG_VALUES_TEMPLATE with hub cluster ARN, platform URL, ECR registry URL, and retail store config URL"
    else
        echo "Warning: Template file $HUB_CLUSTER_REG_VALUES_TEMPLATE not found"
    fi
    
    # Update default-register-cluster-values.yaml template
    DEFAULT_CLUSTER_REG_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/register-cluster/default-register-cluster-values.yaml"
    
    if [ -f "$DEFAULT_CLUSTER_REG_VALUES_TEMPLATE" ]; then
        echo "Updated $DEFAULT_CLUSTER_REG_VALUES_TEMPLATE (no replacements needed)"
    else
        echo "Warning: Template file $DEFAULT_CLUSTER_REG_VALUES_TEMPLATE not found"
    fi
    
    IDENTITY_STORE_ID=$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' | tr -d '"')
    echo "Identity Store ID: $IDENTITY_STORE_ID"    
    # Update dev-values.yaml template
    DEV_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/project/dev-values.yaml"
    
    if [ -f "$DEV_VALUES_TEMPLATE" ]; then
        # Get Identity Store ID from SSO instances

        
        # Find all group placeholders and replace them dynamically
        GROUP_PLACEHOLDERS=$(grep -o '<<[^<>]*Store[^<>]*>>' "$DEV_VALUES_TEMPLATE" | sort -u)
        echo "Found group placeholders: $GROUP_PLACEHOLDERS"
        
        # Build sed replacement string
        SED_REPLACEMENTS=""
        for placeholder in $GROUP_PLACEHOLDERS; do
            # Extract group name (remove << and >>)
            GROUP_NAME=$(echo "$placeholder" | sed 's/<<//g' | sed 's/>>//g')
            echo "Processing group: $GROUP_NAME"
            
            # Get group UUID from Identity Center with explicit error handling
            GROUP_UUID=$(aws identitystore list-groups \
                --identity-store-id "$IDENTITY_STORE_ID" \
                --filters "AttributePath=DisplayName,AttributeValue=$GROUP_NAME" \
                --query 'Groups[0].GroupId' \
                --output text 2>/dev/null)
            
            # Check if GROUP_UUID is valid
            if [ -n "$GROUP_UUID" ] && [ "$GROUP_UUID" != "None" ] && [ "$GROUP_UUID" != "null" ]; then
                SED_REPLACEMENTS="$SED_REPLACEMENTS -e s|$placeholder|$GROUP_UUID|g"
                echo "Found group $GROUP_NAME with UUID: $GROUP_UUID"
            else
                echo "Warning: Group $GROUP_NAME not found in Identity Center"
                echo "Debug: Raw AWS response for $GROUP_NAME:"
                aws identitystore list-groups \
                    --identity-store-id "$IDENTITY_STORE_ID" \
                    --filters "AttributePath=DisplayName,AttributeValue=$GROUP_NAME" 2>/dev/null || echo "AWS command failed"
            fi
        done
        
        # Apply all replacements
        sed -i.bak \
            -e "s|<<oci_registry_url>>|$ECR_REGISTRY_URL|g" \
            -e "s|<<retail_store_config_url>>|$RETAIL_STORE_CONFIG_URL|g" \
            $SED_REPLACEMENTS \
            "$DEV_VALUES_TEMPLATE"
        echo "Updated $DEV_VALUES_TEMPLATE with ECR registry URL, retail store config URL, and IDC group UUIDs"
    else
        echo "Warning: Template file $DEV_VALUES_TEMPLATE not found"
    fi
    
    # Update prod-values.yaml template
    PROD_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/project/prod-values.yaml"
    
    if [ -f "$PROD_VALUES_TEMPLATE" ]; then
        # Find all group placeholders and replace them dynamically
        GROUP_PLACEHOLDERS=$(grep -o '<<[^<>]*Store[^<>]*>>' "$PROD_VALUES_TEMPLATE" | sort -u)
        
        # Build sed replacement string
        SED_REPLACEMENTS=""
        for placeholder in $GROUP_PLACEHOLDERS; do
            # Extract group name (remove << and >>)
            GROUP_NAME=$(echo "$placeholder" | sed 's/<<//g' | sed 's/>>//g')
            
            # Get group UUID from Identity Center
            GROUP_UUID=$(aws identitystore list-groups --identity-store-id $IDENTITY_STORE_ID --filters AttributePath=DisplayName,AttributeValue=$GROUP_NAME --query 'Groups[0].GroupId' --output text 2>/dev/null || echo "")
            
            if [ -n "$GROUP_UUID" ] && [ "$GROUP_UUID" != "None" ]; then
                SED_REPLACEMENTS="$SED_REPLACEMENTS -e s|$placeholder|$GROUP_UUID|g"
                echo "Found group $GROUP_NAME with UUID: $GROUP_UUID"
            else
                echo "Warning: Group $GROUP_NAME not found in Identity Center"
            fi
        done
        
        # Apply all replacements
        sed -i.bak \
            -e "s|<<oci_registry_url>>|$ECR_REGISTRY_URL|g" \
            -e "s|<<retail_store_config_url>>|$RETAIL_STORE_CONFIG_URL|g" \
            $SED_REPLACEMENTS \
            "$PROD_VALUES_TEMPLATE"
        echo "Updated $PROD_VALUES_TEMPLATE with ECR registry URL, retail store config URL, and IDC group UUIDs"
    else
        echo "Warning: Template file $PROD_VALUES_TEMPLATE not found"
    fi
    
    # Update admin-project.yaml template
    ADMIN_PROJECT_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/project/admin-project.yaml"
    
    if [ -f "$ADMIN_PROJECT_TEMPLATE" ]; then
        # Find all group placeholders and replace them dynamically
        GROUP_PLACEHOLDERS=$(grep -o '<<[^<>]*>>' "$ADMIN_PROJECT_TEMPLATE" | grep -v '<<oci_registry_url>>' | grep -v '<<platform_url>>' | sort -u)
        
        # Build sed replacement string for groups
        SED_REPLACEMENTS=""
        for placeholder in $GROUP_PLACEHOLDERS; do
            # Extract group name (remove << and >>)
            GROUP_NAME=$(echo "$placeholder" | sed 's/<<//g' | sed 's/>>//g')
            
            # Get group UUID from Identity Center
            GROUP_UUID=$(aws identitystore list-groups --identity-store-id $IDENTITY_STORE_ID --filters AttributePath=DisplayName,AttributeValue=$GROUP_NAME --query 'Groups[0].GroupId' --output text 2>/dev/null || echo "")
            
            if [ -n "$GROUP_UUID" ] && [ "$GROUP_UUID" != "None" ]; then
                SED_REPLACEMENTS="$SED_REPLACEMENTS -e s|$placeholder|$GROUP_UUID|g"
                echo "Found group $GROUP_NAME with UUID: $GROUP_UUID"
            else
                echo "Warning: Group $GROUP_NAME not found in Identity Center"
            fi
        done
        
        # Apply all replacements
        sed -i.bak \
            -e "s|<<oci_registry_url>>|$ECR_REGISTRY_URL|g" \
            -e "s|<<platform_url>>|$PLATFORM_URL|g" \
            $SED_REPLACEMENTS \
            "$ADMIN_PROJECT_TEMPLATE"
        echo "Updated $ADMIN_PROJECT_TEMPLATE with ECR registry URL, platform URL, and IDC group UUIDs"
    else
        echo "Warning: Template file $ADMIN_PROJECT_TEMPLATE not found"
    fi
    
    echo "Template updates completed"
    echo "---"
}

echo "Starting ArgoCD template setup..."

# Setup contexts for all clusters

setup_argocd_context "argocd-spoke-dev" "dev" 
setup_argocd_context "argocd-spoke-prod" "prod"
setup_argocd_context "argocd-hub" "hub"

# Update template files
update_templates

echo "All ArgoCD contexts configured and templates updated successfully!"

# Initialize Terraform in hub and spoke directories
echo "Initializing Terraform in hub directory..."
cd ~/environment/hub
terraform init

echo "Initializing Terraform in spoke directory..."
cd ~/environment/spoke
terraform init

echo "Terraform initialization completed!"
