#!/bin/bash

set -e

# Function to setup ArgoCD context
setup_argocd_context() {
    local cluster_name=$1
    local context_name=$2
    
    echo "Setting up ArgoCD context for cluster: $cluster_name with context: $context_name"
    
    # Update kubeconfig for the cluster
    aws eks update-kubeconfig --name $cluster_name --region ${AWS_REGION:-us-west-2}
    
    # Set kubectl context
    kubectl config use-context arn:aws:eks:${AWS_REGION:-us-west-2}:$(aws sts get-caller-identity --query Account --output text):cluster/$cluster_name
    
    # Verify connection
    kubectl get nodes
    
    echo "Successfully configured context for $cluster_name"
    echo "---"
}

# Function to update template files
update_templates() {
    echo "Updating template files with cluster ARNs and secrets..."
    
    # Get ARN for argocd-hub cluster
    HUB_CLUSTER_ARN=$(aws eks describe-cluster --name argocd-hub --region ${AWS_REGION:-us-west-2} --query 'cluster.arn' --output text)
    
    echo "Hub cluster ARN: $HUB_CLUSTER_ARN"
    
    # Update hub-cluster.yaml template
    TEMPLATE_FILE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/hub-cluster.yaml"
    
    if [ -f "$TEMPLATE_FILE" ]; then
        sed -i.bak "s|<<arn>>|$HUB_CLUSTER_ARN|g" "$TEMPLATE_FILE"
        echo "Updated $TEMPLATE_FILE with hub cluster ARN"
    else
        echo "Warning: Template file $TEMPLATE_FILE not found"
    fi
    
    # Get secrets for platform repo
    gitops_platform_url="$(aws secretsmanager get-secret-value --secret-id ${PROJECT_CONTEXT_PREFIX:-eks-blueprints-workshop}-platform --query SecretString --output text | jq -r .url)"
    GIT_USER="$(aws secretsmanager get-secret-value --secret-id ${PROJECT_CONTEXT_PREFIX:-eks-blueprints-workshop}-retail-store-manifest --query SecretString --output text | jq -r .username)"
    GIT_PASS="$(aws secretsmanager get-secret-value --secret-id ${PROJECT_CONTEXT_PREFIX:-eks-blueprints-workshop}-retail-store-manifest --query SecretString --output text | jq -r .password)"
    
    echo "Platform URL: $gitops_platform_url"
    echo "Git User: $GIT_USER"
    
    # Update platform-repo.yaml template
    PLATFORM_REPO_TEMPLATE="$HOME/eks-blueprints-for-terraform-workshop/gitops/templates/platform-repo.yaml"
    
    if [ -f "$PLATFORM_REPO_TEMPLATE" ]; then
        sed -i.bak \
            -e "s|<<url>>|$gitops_platform_url|g" \
            -e "s|<<user>>|$GIT_USER|g" \
            -e "s|<<password>>|$GIT_PASS|g" \
            "$PLATFORM_REPO_TEMPLATE"
        echo "Updated $PLATFORM_REPO_TEMPLATE with platform repo credentials"
    else
        echo "Warning: Template file $PLATFORM_REPO_TEMPLATE not found"
    fi
    
    echo "Template updates completed"
    echo "---"
}

echo "Starting ArgoCD template setup..."

# Setup contexts for all clusters
setup_argocd_context "argocd-hub" "hub"
setup_argocd_context "argocd-spoke-dev" "dev" 
setup_argocd_context "argocd-spoke-prod" "prod"

# Update template files
update_templates

echo "All ArgoCD contexts configured and templates updated successfully!"

