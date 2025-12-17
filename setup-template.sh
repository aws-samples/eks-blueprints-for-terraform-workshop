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
    
    # Get ARN for argocd-hub cluster
    HUB_CLUSTER_ARN=$(aws eks describe-cluster --name argocd-hub --region ${AWS_REGION:-us-west-2} --query 'cluster.arn' --output text)
    
    echo "Hub cluster ARN: $HUB_CLUSTER_ARN"
    
    # Get secrets for platform repo
    PLATFORM_URL="$(aws secretsmanager get-secret-value --secret-id argocd-workshop-platform --query SecretString --output text | jq -r .url)"
    GIT_USER="$(aws secretsmanager get-secret-value --secret-id argocd-workshop-platform --query SecretString --output text | jq -r .username)"
    GIT_PASS="$(aws secretsmanager get-secret-value --secret-id argocd-workshop-platform --query SecretString --output text | jq -r .password)"
    
    echo "Platform URL: $PLATFORM_URL"
    echo "Git User: $GIT_USER"
    
    # Update hub-cluster.yaml template
    TEMPLATE_FILE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/hub-cluster.yaml"
    
    if [ -f "$TEMPLATE_FILE" ]; then
        sed -i.bak \
            -e "s|<<arn>>|$HUB_CLUSTER_ARN|g" \
            -e "s|<<platform_url>>|$PLATFORM_URL|g" \
            "$TEMPLATE_FILE"
        echo "Updated $TEMPLATE_FILE with hub cluster ARN and platform URL"
    else
        echo "Warning: Template file $TEMPLATE_FILE not found"
    fi
    
    # Update platform-repo.yaml template
    PLATFORM_REPO_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/platform-repo.yaml"
    
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
    
    # Get secret ARN for platform_repo_credentials
    PLATFORM_REPO_SECRET_ARN=$(aws secretsmanager describe-secret --secret-id platform_repo_credentials --query 'ARN' --output text)
    
    # Update platform-repo-values.yaml template
    PLATFORM_REPO_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/platform-repo-values.yaml"
    
    if [ -f "$PLATFORM_REPO_VALUES_TEMPLATE" ]; then
        sed -i.bak \
            -e "s|<<url>>|$PLATFORM_URL|g" \
            -e "s|<<secret_arn>>|$PLATFORM_REPO_SECRET_ARN|g" \
            "$PLATFORM_REPO_VALUES_TEMPLATE"
        echo "Updated $PLATFORM_REPO_VALUES_TEMPLATE with platform URL and secret ARN"
    else
        echo "Warning: Template file $PLATFORM_REPO_VALUES_TEMPLATE not found"
    fi
    
    # Get retail store manifest URL from secret
    RETAIL_STORE_URL="$(aws secretsmanager get-secret-value --secret-id argocd-workshop-retail-store-manifest --query SecretString --output text | jq -r .url)"
    
    # Update retail-store-manifest-repo-values.yaml template
    RETAIL_STORE_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/retail-store-manifest-repo-values.yaml"
    
    if [ -f "$RETAIL_STORE_VALUES_TEMPLATE" ]; then
        sed -i.bak \
            -e "s|<<url>>|$RETAIL_STORE_URL|g" \
            -e "s|<<secret_arn>>|$PLATFORM_REPO_SECRET_ARN|g" \
            "$RETAIL_STORE_VALUES_TEMPLATE"
        echo "Updated $RETAIL_STORE_VALUES_TEMPLATE with retail store URL and secret ARN"
    else
        echo "Warning: Template file $RETAIL_STORE_VALUES_TEMPLATE not found"
    fi
    
    # Update bootstrap.yaml template
    BOOTSTRAP_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/bootstrap.yaml"
    
    if [ -f "$BOOTSTRAP_TEMPLATE" ]; then
        sed -i.bak "s|<<url>>|$PLATFORM_URL|g" "$BOOTSTRAP_TEMPLATE"
        echo "Updated $BOOTSTRAP_TEMPLATE with platform URL"
    else
        echo "Warning: Template file $BOOTSTRAP_TEMPLATE not found"
    fi
    
    # Update hub-register-cluster-values.yaml template
    HUB_CLUSTER_REG_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/hub-register-cluster-values.yaml"
    
    if [ -f "$HUB_CLUSTER_REG_VALUES_TEMPLATE" ]; then
        sed -i.bak "s|<<arn>>|$HUB_CLUSTER_ARN|g" "$HUB_CLUSTER_REG_VALUES_TEMPLATE"
        echo "Updated $HUB_CLUSTER_REG_VALUES_TEMPLATE with hub cluster ARN"
    else
        echo "Warning: Template file $HUB_CLUSTER_REG_VALUES_TEMPLATE not found"
    fi
    
    # Update default-register-cluster-values.yaml template
    DEFAULT_CLUSTER_REG_VALUES_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/default-register-cluster-values.yaml"
    
    if [ -f "$DEFAULT_CLUSTER_REG_VALUES_TEMPLATE" ]; then
        sed -i.bak "s|<<url>>|$PLATFORM_URL|g" "$DEFAULT_CLUSTER_REG_VALUES_TEMPLATE"
        echo "Updated $DEFAULT_CLUSTER_REG_VALUES_TEMPLATE with platform URL"
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
