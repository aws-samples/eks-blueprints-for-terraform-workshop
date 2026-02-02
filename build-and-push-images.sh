#!/bin/bash

# Build and Push Docker Images to ECR Script
# This script builds all retail-store microservices and pushes them directly to ECR

set -e  # Exit on any error

# Configuration
VERSION=${1:-"v1.3.0"}
SERVICES=("cart" "catalog" "checkout" "orders" "ui")

# Get AWS Account ID and Region (consistent with setup-template.sh)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-west-2}
ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "🚀 Building and pushing retail-store microservices to ECR"
echo "Version: $VERSION"
echo "ECR Registry: $ECR_REGISTRY"
echo "AWS Account: $ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
echo ""

# Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
echo "✅ ECR login successful"
echo ""

# Build and push each service
for service in "${SERVICES[@]}"; do
    echo "📦 Building $service..."
    
    # Build the image (path relative to eks-blueprints-for-terraform-workshop)
    docker build -t retail-store/$service:$VERSION gitops/retail-store-app/src/$service/
    
    # Tag for ECR (retail-store/service format)
    echo "🏷️  Tagging $service for ECR..."
    docker tag retail-store/$service:$VERSION $ECR_REGISTRY/retail-store/$service:$VERSION
    
    # Push to ECR
    echo "⬆️  Pushing $service to ECR..."
    docker push $ECR_REGISTRY/retail-store/$service:$VERSION
    
    # Clean up local image to save space
    echo "🧹 Cleaning up local images..."
    docker rmi retail-store/$service:$VERSION $ECR_REGISTRY/retail-store/$service:$VERSION
    
    echo "✅ $service:$VERSION built and pushed successfully"
    echo ""
done

echo "🎉 All images built and pushed to ECR successfully!"
echo ""
echo "📋 Your images are now available at:"
for service in "${SERVICES[@]}"; do
    echo "   $ECR_REGISTRY/retail-store/$service:$VERSION"
done
