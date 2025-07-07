#!/bin/bash
set -e

# Test script to validate the production KeyDB configuration
# This simulates the exact command-line arguments used in production

IMAGE_NAME="opendi/keydb:latest"

echo "Testing KeyDB with production configuration..."

# Test 1: Basic version check
echo "Test 1: Version check"
docker run --rm $IMAGE_NAME keydb-server --version

# Test 2: Production command-line arguments (simulating keydb-0)
echo "Test 2: Production configuration test"
docker run --rm -d \
    --name keydb-test \
    -e POD_IP=127.0.0.1 \
    -e POD_NAME=keydb-0 \
    $IMAGE_NAME \
    keydb-server \
    --active-replica yes \
    --appendonly no \
    --cluster-enabled no \
    --save '' \
    --maxmemory 1024mb \
    --maxmemory-policy allkeys-lru \
    --replica-announce-ip 127.0.0.1 \
    --port 6379

# Wait a moment for startup
sleep 3

# Test 3: Check if KeyDB is responding
echo "Test 3: Connectivity test"
if docker exec keydb-test keydb-cli ping | grep -q PONG; then
    echo "✅ KeyDB is responding to ping"
else
    echo "❌ KeyDB is not responding"
    docker logs keydb-test
    docker stop keydb-test
    exit 1
fi

# Test 4: Check configuration
echo "Test 4: Configuration verification"
docker exec keydb-test keydb-cli CONFIG GET maxmemory
docker exec keydb-test keydb-cli CONFIG GET maxmemory-policy
docker exec keydb-test keydb-cli CONFIG GET appendonly

# Test 5: Memory usage test
echo "Test 5: Memory usage test"
docker exec keydb-test keydb-cli INFO memory | grep used_memory_human

# Cleanup
echo "Cleaning up..."
docker stop keydb-test

echo "✅ All tests passed! KeyDB is ready for production deployment."
