#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Building relay and headless joiner for client-side..."

echo "Building relay..."
cd "$ROOT/relay"
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o relay .

echo ""
echo "Client binary built successfully:"
ls -lh "$ROOT/relay/relay"
echo ""
echo "Now you can build the Docker image:"
echo "  cd docker && docker build -f Dockerfile.client -t whitelist-bypass-client .."
