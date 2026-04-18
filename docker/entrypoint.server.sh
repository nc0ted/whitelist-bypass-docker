#!/bin/bash
set -e

echo "=== Whitelist Bypass Server (Creator) ==="
echo "Platform: $PLATFORM"
echo "Tunnel Mode: $TUNNEL_MODE"
echo "Resources: $RESOURCES"
echo ""

if [ "$PLATFORM" != "vk" ] && [ "$PLATFORM" != "telemost" ]; then
    echo "ERROR: PLATFORM must be 'vk' or 'telemost'"
    exit 1
fi

if [ "$TUNNEL_MODE" != "video" ] && [ "$TUNNEL_MODE" != "dc" ]; then
    echo "ERROR: TUNNEL_MODE must be 'video' or 'dc'"
    exit 1
fi

if [ -z "$COOKIE_FILE" ]; then
    if [ "$PLATFORM" = "vk" ]; then
        COOKIE_FILE="/app/cookies.json"
    else
        COOKIE_FILE="/app/cookies-yandex.json"
    fi
fi

if [ ! -f "$COOKIE_FILE" ]; then
    echo "ERROR: Cookie file not found: $COOKIE_FILE"
    echo "Please mount your cookies file:"
    if [ "$PLATFORM" = "vk" ]; then
        echo "  -v /path/to/cookies.json:/app/cookies.json"
    else
        echo "  -v /path/to/cookies-yandex.json:/app/cookies-yandex.json"
    fi
    exit 1
fi

ARGS="--cookies $COOKIE_FILE --resources $RESOURCES"

if [ "$PLATFORM" = "vk" ]; then
    if [ -n "$VK_PEER_ID" ]; then
        ARGS="$ARGS --peer-id $VK_PEER_ID"
    fi
    
    echo "Starting VK Call creator..."
    echo "Command: /app/headless-vk-creator $ARGS"
    echo ""
    exec /app/headless-vk-creator $ARGS
else
    echo "Starting Telemost creator..."
    echo "Command: /app/headless-telemost-creator $ARGS"
    echo ""
    exec /app/headless-telemost-creator $ARGS
fi
