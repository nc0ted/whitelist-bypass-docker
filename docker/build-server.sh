#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Building headless creators for server-side..."

echo "Building headless-vk-creator..."
cd "$ROOT/headless/vk"
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o headless-vk-creator .

echo "Building headless-telemost-creator..."
cd "$ROOT/headless/telemost"
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o headless-telemost-creator .

echo ""
echo "Server binaries built successfully:"
ls -lh "$ROOT/headless/vk/headless-vk-creator"
ls -lh "$ROOT/headless/telemost/headless-telemost-creator"
echo ""
echo "Now you can build the Docker image:"
echo "  cd docker && docker build -f Dockerfile.server -t whitelist-bypass-server .."
