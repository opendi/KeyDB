#!/bin/bash

# Multi-architecture build and push script for KeyDB
# Builds for both AMD64 and ARM64 platforms and pushes to Docker Hub

set -e

# Configuration
REGISTRY="opendi"
IMAGE_NAME="keydb"
TAG="${TAG:-latest}"
PLATFORMS="linux/amd64,linux/arm64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Building and pushing multi-architecture KeyDB image...${NC}"
echo -e "${BLUE}Registry: ${REGISTRY}${NC}"
echo -e "${BLUE}Image: ${IMAGE_NAME}${NC}"
echo -e "${BLUE}Tag: ${TAG}${NC}"
echo -e "${BLUE}Platforms: ${PLATFORMS}${NC}"
echo ""

# Check if logged into Docker Hub
echo -e "${YELLOW}Checking Docker Hub authentication...${NC}"
if ! cat ~/.docker/config.json 2>/dev/null | grep -q "auths"; then
    echo -e "${RED}❌ Not logged into Docker Hub. Please run 'docker login' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker Hub authentication verified${NC}"
echo ""

# Ensure buildx builder exists and is active
echo -e "${YELLOW}Setting up buildx builder...${NC}"
if ! docker buildx inspect keydb-builder >/dev/null 2>&1; then
    echo "Creating new buildx builder..."
    docker buildx create --name keydb-builder --driver docker-container --use
else
    echo "Using existing buildx builder..."
    docker buildx use keydb-builder
fi

# Bootstrap the builder if needed
echo -e "${YELLOW}Bootstrapping builder...${NC}"
docker buildx inspect --bootstrap

echo -e "${GREEN}✅ Builder ready${NC}"
echo ""

# Build and push multi-architecture image
echo -e "${YELLOW}Building and pushing multi-architecture image...${NC}"
echo "This may take several minutes..."
echo ""

docker buildx build \
    --platform ${PLATFORMS} \
    --tag ${REGISTRY}/${IMAGE_NAME}:${TAG} \
    --push \
    --progress=plain \
    .

echo ""
echo -e "${GREEN}✅ Multi-architecture build and push completed successfully!${NC}"
echo ""

# Verify the pushed image
echo -e "${YELLOW}Verifying pushed image...${NC}"
docker buildx imagetools inspect ${REGISTRY}/${IMAGE_NAME}:${TAG}

echo ""
echo -e "${GREEN}🎉 KeyDB multi-architecture image is now available at:${NC}"
echo -e "${BLUE}   docker pull ${REGISTRY}/${IMAGE_NAME}:${TAG}${NC}"
echo ""
echo -e "${GREEN}Supported platforms:${NC}"
echo -e "${BLUE}   - linux/amd64 (Intel/AMD 64-bit)${NC}"
echo -e "${BLUE}   - linux/arm64 (ARM 64-bit, Apple Silicon, AWS Graviton)${NC}"
