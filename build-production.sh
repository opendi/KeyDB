#!/bin/bash
set -e

# Production KeyDB Docker Build Script
# This script builds the KeyDB image for ARM64 architecture to match production requirements

# Configuration
IMAGE_NAME="opendi/keydb"
TAG="latest"
PLATFORM="linux/arm64"

echo "Building KeyDB for production environment..."
echo "Platform: $PLATFORM"
echo "Image: $IMAGE_NAME:$TAG"

# Check if buildx is available
if ! docker buildx version >/dev/null 2>&1; then
    echo "Error: docker buildx is required for multi-platform builds"
    echo "Please install Docker Desktop or enable buildx"
    exit 1
fi

# Create builder if it doesn't exist
if ! docker buildx ls | grep -q keydb-builder; then
    echo "Creating buildx builder..."
    docker buildx create --name keydb-builder --use
fi

# Build the image
echo "Building KeyDB image..."
docker buildx build \
    --platform $PLATFORM \
    --tag $IMAGE_NAME:$TAG \
    --load \
    --progress=plain \
    .

echo "Build completed successfully!"
echo "Image: $IMAGE_NAME:$TAG"

# Test the image
echo "Testing the built image..."
docker run --rm $IMAGE_NAME:$TAG keydb-server --version

echo "Production KeyDB image is ready!"
