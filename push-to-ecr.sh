#!/bin/bash

# Push Docker Images to ECR Script
# This script tags and pushes all retail-store microservices to ECR

set -e  # Exit on any error

# Configuration
VERSION=${1:-"v1.3.0"}
SERVICES=("cart" "catalog" "checkout" "orders" "ui")

# Get AWS Account ID and Region (consistent with setup-template.sh)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${AWS_REGION:-us-west-2}
ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "🚀 Pushing retail-store microservices to ECR"
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

# Tag and push each service
for service in "${SERVICES[@]}"; do
    echo "📦 Processing $service..."
    
    # Tag for ECR (retail-store/service format)
    echo "🏷️  Tagging $service for ECR..."
    docker tag retail-store/$service:$VERSION $ECR_REGISTRY/retail-store/$service:$VERSION
    
    # Push to ECR
    echo "⬆️  Pushing $service to ECR..."
    docker push $ECR_REGISTRY/retail-store/$service:$VERSION
    
    echo "✅ $service:$VERSION pushed successfully"
    echo ""
done

echo "🎉 All images pushed to ECR successfully!"
echo ""
echo "📋 Your images are now available at:"
for service in "${SERVICES[@]}"; do
    echo "   $ECR_REGISTRY/retail-store/$service:$VERSION"
done
