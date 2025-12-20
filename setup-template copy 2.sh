#!/bin/bash

set -e

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
    for i in {1..10}; do
        if HUB_CLUSTER_ARN=$(aws eks describe-cluster --name argocd-hub --region ${AWS_REGION:-us-west-2} --query 'cluster.arn' --output text 2>/dev/null); then
            echo "Hub cluster ARN: $HUB_CLUSTER_ARN"
            break
        fi
        echo "Attempt $i: Hub cluster not found, waiting 30 seconds..."
        sleep 30
        if [ $i -eq 10 ]; then
            echo "Error: Could not get hub cluster ARN after 10 attempts"
            return 1
        fi
    done
    
    # Retry logic for getting platform secrets from repo_org
    for i in {1..10}; do
        if REPO_ORG=$(aws secretsmanager get-secret-value --secret-id argocd-workshop-repo-org --query SecretString --output text 2>/dev/null | jq -r .REPO_ORG); then
            PLATFORM_URL="$REPO_ORG/platform"
            break
        fi
        echo "Attempt $i: Repo org secret not found, waiting 30 seconds..."
        sleep 30
        if [ $i -eq 10 ]; then
            echo "Error: Could not get platform URL after 10 attempts"
            return 1
        fi
    done
    
    for i in {1..10}; do
        if GIT_USER=$(aws secretsmanager get-secret-value --secret-id argocd-workshop-repo-org --query SecretString --output text 2>/dev/null | jq -r .GIT_USER); then
            break
        fi
        echo "Attempt $i: Repo org username not found, waiting 30 seconds..."
        sleep 30
        if [ $i -eq 10 ]; then
            echo "Error: Could not get git username after 10 attempts"
            return 1
        fi
    done
    
    for i in {1..10}; do
        if GIT_PASS=$(aws secretsmanager get-secret-value --secret-id argocd-workshop-repo-org --query SecretString --output text 2>/dev/null | jq -r .GIT_PASSWORD); then
            break
        fi
        echo "Attempt $i: Platform secret password not found, waiting 30 seconds..."
        sleep 30
        if [ $i -eq 10 ]; then
            echo "Error: Could not get git password after 10 attempts"
            return 1
        fi
    done
    
    echo "Platform URL: $PLATFORM_URL"
    echo "Git User: $GIT_USER"
    
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
            -e "s|<<user>>|$GIT_USER|g" \
            -e "s|<<password>>|$GIT_PASS|g" \
            "$PLATFORM_REPO_TEMPLATE"
        echo "Updated $PLATFORM_REPO_TEMPLATE with platform repo credentials"
    else
        echo "Warning: Template file $PLATFORM_REPO_TEMPLATE not found"
    fi
    
    # Update hub-cluster-values.yaml template
    HUB_CLUSTER_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/hub-cluster-values.yaml"
    
    if [ -f "$HUB_CLUSTER_VALUES_TEMPLATE" ]; then
        sed -i.bak "s|<<arn>>|$HUB_CLUSTER_ARN|g" "$HUB_CLUSTER_VALUES_TEMPLATE"
        echo "Updated $HUB_CLUSTER_VALUES_TEMPLATE with hub cluster ARN"
    else
        echo "Warning: Template file $HUB_CLUSTER_VALUES_TEMPLATE not found"
    fi
    
    # Get secret ARN for repo_credentials
    for i in {1..10}; do
        if REPO_CREDENTIALS_SECRET_ARN=$(aws secretsmanager describe-secret --secret-id argocd-workshop-repo-credentials --query 'ARN' --output text 2>/dev/null); then
            break
        fi
        echo "Attempt $i: Repo credentials secret not found, waiting 30 seconds..."
        sleep 30
        if [ $i -eq 10 ]; then
            echo "Error: Could not get repo credentials secret ARN after 10 attempts"
            return 1
        fi
    done
    
    # Update platform-repo-values.yaml template
    PLATFORM_REPO_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/register-repo/platform-repo-values.yaml"
    
    if [ -f "$PLATFORM_REPO_VALUES_TEMPLATE" ]; then
        sed -i.bak \
            -e "s|<<url>>|$PLATFORM_URL|g" \
            -e "s|<<secret_arn>>|$REPO_CREDENTIALS_SECRET_ARN|g" \
            "$PLATFORM_REPO_VALUES_TEMPLATE"
        echo "Updated $PLATFORM_REPO_VALUES_TEMPLATE with platform URL and secret ARN"
    else
        echo "Warning: Template file $PLATFORM_REPO_VALUES_TEMPLATE not found"
    fi
    
    # Get retail store manifest URL from secret
    for i in {1..10}; do
        if RETAIL_STORE_URL=$(aws secretsmanager get-secret-value --secret-id argocd-workshop-retail-store-manifest-repo --query SecretString --output text 2>/dev/null | jq -r .url); then
            break
        fi
        echo "Attempt $i: Retail store manifest secret not found, waiting 30 seconds..."
        sleep 30
        if [ $i -eq 10 ]; then
            echo "Error: Could not get retail store URL after 10 attempts"
            return 1
        fi
    done
    
    # Update retail-store-manifest-repo-values.yaml template
    RETAIL_STORE_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/register-repo/retail-store-manifest-repo-values.yaml"
    
    if [ -f "$RETAIL_STORE_VALUES_TEMPLATE" ]; then
        sed -i.bak \
            -e "s|<<url>>|$RETAIL_STORE_URL|g" \
            -e "s|<<secret_arn>>|$REPO_CREDENTIALS_SECRET_ARN|g" \
            "$RETAIL_STORE_VALUES_TEMPLATE"
        echo "Updated $RETAIL_STORE_VALUES_TEMPLATE with retail store URL and secret ARN"
    else
        echo "Warning: Template file $RETAIL_STORE_VALUES_TEMPLATE not found"
    fi

    # Update retail-store-environments.yaml template
    RETAIL_STORE_ENV_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/retail-store-environments.yaml"
    
    if [ -f "$RETAIL_STORE_ENV_TEMPLATE" ]; then
        sed -i.bak "s|<<url>>|$RETAIL_STORE_URL|g" "$RETAIL_STORE_ENV_TEMPLATE"
        echo "Updated $RETAIL_STORE_ENV_TEMPLATE with retail store URL"
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
        # Get retail store config URL from repo_org secret
        REPO_ORG=$(aws secretsmanager get-secret-value --secret-id argocd-workshop-repo-org --query SecretString --output text 2>/dev/null | jq -r .REPO_ORG)
        RETAIL_STORE_CONFIG_URL="$REPO_ORG/retail-store-manifest"
        
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
