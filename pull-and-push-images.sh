#!/bin/bash

# Pull Pre-built Images and Push to ECR Script
# This pulls AWS's official retail-store images and pushes to your ECR

set -e  # Exit on any error

# Configuration
VERSION=${1:-"0.2.0"}  # Using the available public version
SERVICES=("cart" "catalog" "checkout" "orders" "ui")

# Get AWS Account ID and Region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-west-2}
ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "🚀 Pulling AWS retail-store images and pushing to ECR"
echo "Version: $VERSION"
echo "ECR Registry: $ECR_REGISTRY"
echo ""

# Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
echo "✅ ECR login successful"
echo ""

# Create ECR repositories for container images first
echo "🏗️  Creating ECR repositories for container images..."
for service in "${SERVICES[@]}"; do
    echo "Creating repository: retail-store/$service"
    aws ecr create-repository --repository-name "retail-store/$service" --region "$AWS_REGION" 2>/dev/null || echo "Repository retail-store/$service already exists"
done
echo "✅ ECR repositories created"
echo ""

# Pull and push each service
for service in "${SERVICES[@]}"; do
    echo "📥 Pulling $service from AWS public ECR..."
    docker pull public.ecr.aws/aws-containers/retail-store-sample-$service:$VERSION
    
    echo "🏷️  Tagging for your ECR..."
    docker tag public.ecr.aws/aws-containers/retail-store-sample-$service:$VERSION $ECR_REGISTRY/retail-store/$service:$VERSION
    
    echo "⬆️  Pushing to your ECR..."
    docker push $ECR_REGISTRY/retail-store/$service:$VERSION
    
    # Clean up local images to save space
    echo "🧹 Cleaning up..."
    docker rmi public.ecr.aws/aws-containers/retail-store-sample-$service:$VERSION $ECR_REGISTRY/retail-store/$service:$VERSION
    
    echo "✅ $service:$VERSION transferred successfully"
    echo ""
done

echo "🎉 All images pulled and pushed to ECR successfully!"
echo ""

# Update template files with ECR repository URLs
echo "📝 Updating retail-store-config template files..."
RETAIL_STORE_CONFIG_DIR="/home/ec2-user/eks-blueprints-for-terraform-workshop/gitops/retail-store-config"

if [ -d "$RETAIL_STORE_CONFIG_DIR" ]; then
    for service in "${SERVICES[@]}"; do
        echo "Updating $service templates..."
        
        # Update dev values.yaml
        DEV_VALUES_FILE="$RETAIL_STORE_CONFIG_DIR/$service/dev/values.yaml"
        if [ -f "$DEV_VALUES_FILE" ]; then
            sed -i.bak "s|<<ecr_arn>>|$ECR_REGISTRY/retail-store/$service|g" "$DEV_VALUES_FILE"
            echo "  ✅ Updated $service dev values"
        else
            echo "  ⚠️  Warning: $DEV_VALUES_FILE not found"
        fi
        
        # Update prod values.yaml  
        PROD_VALUES_FILE="$RETAIL_STORE_CONFIG_DIR/$service/prod/values.yaml"
        if [ -f "$PROD_VALUES_FILE" ]; then
            sed -i.bak "s|<<ecr_arn>>|$ECR_REGISTRY/retail-store/$service|g" "$PROD_VALUES_FILE"
            echo "  ✅ Updated $service prod values"
        else
            echo "  ⚠️  Warning: $PROD_VALUES_FILE not found"
        fi
    done
    
    echo "📝 Template updates completed"
else
    echo "⚠️  Warning: retail-store-config directory not found at $RETAIL_STORE_CONFIG_DIR"
fi

echo ""
echo "📋 Your images are now available at:"
for service in "${SERVICES[@]}"; do
    echo "   $ECR_REGISTRY/retail-store/$service:$VERSION"
done

echo ""
echo "🚀 Creating ECR repositories and pushing Helm charts..."

# Get script directory
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOTDIR=$SCRIPTDIR

# Login to ECR for Helm
aws ecr get-login-password --region $AWS_REGION | helm registry login --username AWS --password-stdin $ECR_REGISTRY

# Push all charts to ECR
cd ${ROOTDIR}

# Process platform charts
echo "📦 Processing platform Helm charts..."
for chart in gitops/helm/platform/*.tgz; do
  if [ -f "$chart" ]; then
    # Extract chart name from filename (remove path, .tgz extension, and version)
    chart_name=$(basename "$chart" .tgz | sed 's/-[0-9]\+\.[0-9]\+\.[0-9]\+$//')
    repo_name="platform/$chart_name"
    
    echo "Processing platform chart: $chart_name -> Repository: $repo_name"
    
    # Create ECR repository if it doesn't exist
    echo "Creating ECR repository for $repo_name..."
    aws ecr create-repository --repository-name "$repo_name" --region "$AWS_REGION" 2>/dev/null || echo "Repository $repo_name already exists"
    
    echo "Pushing $chart to ECR..."
    helm push "$chart" oci://$ECR_REGISTRY/platform
  fi
done

# Process retail-store charts
echo "📦 Processing retail-store Helm charts..."
for chart in gitops/helm/retail-store/*.tgz; do
  if [ -f "$chart" ]; then
    # Extract chart name from filename (remove path, .tgz extension, and version)
    chart_name=$(basename "$chart" .tgz | sed 's/-[0-9]\+\.[0-9]\+\.[0-9]\+$//')
    repo_name="retail-store/$chart_name"
    
    echo "Processing retail-store chart: $chart_name -> Repository: $repo_name"
    
    # Create ECR repository if it doesn't exist
    echo "Creating ECR repository for $repo_name..."
    aws ecr create-repository --repository-name "$repo_name" --region "$AWS_REGION" 2>/dev/null || echo "Repository $repo_name already exists"
    
    echo "Pushing $chart to ECR..."
    helm push "$chart" oci://$ECR_REGISTRY/retail-store
  fi
done

echo "✅ All Helm charts pushed to ECR successfully!"
