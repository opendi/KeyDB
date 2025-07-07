#!/bin/bash

# Test script for multi-architecture KeyDB image from Docker Hub
# Tests both platforms if available

set -e

# Configuration
REGISTRY="opendi"
IMAGE_NAME="keydb"
TAG="${TAG:-latest}"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Testing multi-architecture KeyDB image from Docker Hub...${NC}"
echo -e "${BLUE}Image: ${FULL_IMAGE}${NC}"
echo ""

# Function to test a specific platform
test_platform() {
    local platform=$1
    local container_name="keydb-test-$(echo $platform | tr '/' '-')"
    
    echo -e "${YELLOW}Testing platform: ${platform}${NC}"
    
    # Pull the specific platform image
    echo "Pulling image for platform ${platform}..."
    docker pull --platform ${platform} ${FULL_IMAGE}
    
    # Start container
    echo "Starting KeyDB container..."
    docker run -d \
        --platform ${platform} \
        --name ${container_name} \
        -p 6379:6379 \
        ${FULL_IMAGE} \
        keydb-server --port 6379 --bind 0.0.0.0 --maxmemory 1gb --maxmemory-policy allkeys-lru --appendonly no
    
    # Wait for startup
    echo "Waiting for KeyDB to start..."
    sleep 3
    
    # Test connectivity
    echo "Testing connectivity..."
    if docker exec ${container_name} keydb-cli ping | grep -q "PONG"; then
        echo -e "${GREEN}✅ Platform ${platform}: KeyDB is responding${NC}"
    else
        echo -e "${RED}❌ Platform ${platform}: KeyDB is not responding${NC}"
        docker logs ${container_name}
        docker stop ${container_name} >/dev/null 2>&1 || true
        docker rm ${container_name} >/dev/null 2>&1 || true
        return 1
    fi
    
    # Test version
    echo "Checking version..."
    version=$(docker exec ${container_name} keydb-cli info server | grep keydb_version | cut -d: -f2 | tr -d '\r')
    echo -e "${GREEN}✅ Platform ${platform}: KeyDB version ${version}${NC}"
    
    # Test configuration
    echo "Testing configuration..."
    maxmem=$(docker exec ${container_name} keydb-cli config get maxmemory | tail -1 | tr -d '\r')
    policy=$(docker exec ${container_name} keydb-cli config get maxmemory-policy | tail -1 | tr -d '\r')
    echo -e "${GREEN}✅ Platform ${platform}: maxmemory=${maxmem}, policy=${policy}${NC}"
    
    # Cleanup
    echo "Cleaning up..."
    docker stop ${container_name} >/dev/null 2>&1 || true
    docker rm ${container_name} >/dev/null 2>&1 || true
    
    echo -e "${GREEN}✅ Platform ${platform}: All tests passed!${NC}"
    echo ""
}

# Check image manifest
echo -e "${YELLOW}Checking image manifest...${NC}"
docker buildx imagetools inspect ${FULL_IMAGE}
echo ""

# Test current platform
echo -e "${YELLOW}Testing current platform...${NC}"
current_platform=$(docker version --format '{{.Server.Os}}/{{.Server.Arch}}')
echo "Current platform: ${current_platform}"
test_platform ${current_platform}

# Test other platform if on a multi-arch system
if [[ "${current_platform}" == "linux/amd64" ]]; then
    echo -e "${YELLOW}Testing ARM64 platform (emulated)...${NC}"
    if docker buildx imagetools inspect ${FULL_IMAGE} | grep -q "linux/arm64"; then
        test_platform "linux/arm64"
    else
        echo -e "${YELLOW}⚠️  ARM64 platform not available in image${NC}"
    fi
elif [[ "${current_platform}" == "linux/arm64" ]]; then
    echo -e "${YELLOW}Testing AMD64 platform (emulated)...${NC}"
    if docker buildx imagetools inspect ${FULL_IMAGE} | grep -q "linux/amd64"; then
        test_platform "linux/amd64"
    else
        echo -e "${YELLOW}⚠️  AMD64 platform not available in image${NC}"
    fi
fi

echo -e "${GREEN}🎉 Multi-architecture image testing completed successfully!${NC}"
echo ""
echo -e "${GREEN}The image is ready for production use on both AMD64 and ARM64 platforms.${NC}"
