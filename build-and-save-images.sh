#!/bin/bash

# Build and Save Docker Images Script
# This script builds all retail-store microservices and saves them as tar files

set -e  # Exit on any error

# Configuration
VERSION=${1:-"v1.3.0"}
IMAGES_DIR="/Users/patilsb/Documents/workspace/eks-blueprints-for-terraform-workshop/gitops/images"
SERVICES=("cart" "catalog" "checkout" "orders" "ui")

echo "🚀 Building and saving retail-store microservices"
echo "Version: $VERSION"
echo "Output directory: $IMAGES_DIR"
echo ""

# Create images directory if it doesn't exist
mkdir -p "$IMAGES_DIR"

# Build and save each service
for service in "${SERVICES[@]}"; do
    echo "📦 Building $service..."
    
    # Build the image (path relative to eks-blueprints-for-terraform-workshop)
    docker build -t retail-store/$service:$VERSION gitops/retail-store-app/src/$service/
    
    # Save image to tar file
    echo "💾 Saving $service to tar file..."
    docker save retail-store/$service:$VERSION -o "$IMAGES_DIR/$service-$VERSION.tar"
    
    # Compress the tar file to save space
    echo "🗜️  Compressing $service image..."
    gzip "$IMAGES_DIR/$service-$VERSION.tar"
    
    echo "✅ $service saved as $service-$VERSION.tar.gz"
    echo ""
done

echo "🎉 All images built and saved successfully!"
echo ""
echo "📁 Saved images:"
ls -lh "$IMAGES_DIR"/*.tar.gz

echo ""
echo "📋 To load an image later:"
echo "   gunzip $IMAGES_DIR/cart-$VERSION.tar.gz"
echo "   docker load -i $IMAGES_DIR/cart-$VERSION.tar"
