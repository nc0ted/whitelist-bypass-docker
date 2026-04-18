#!/bin/bash
set -e

echo "=== Whitelist Bypass Client ==="
echo "Platform: $PLATFORM"
echo "Tunnel Mode: $TUNNEL_MODE"
echo "Mode: $MODE"
echo ""

if [ "$PLATFORM" != "vk" ] && [ "$PLATFORM" != "telemost" ]; then
    echo "ERROR: PLATFORM must be 'vk' or 'telemost'"
    exit 1
fi

if [ "$TUNNEL_MODE" != "video" ] && [ "$TUNNEL_MODE" != "dc" ]; then
    echo "ERROR: TUNNEL_MODE must be 'video' or 'dc'"
    exit 1
fi

if [ -z "$MODE" ]; then
    if [ "$PLATFORM" = "vk" ]; then
        MODE="vk-headless-joiner"
    else
        MODE="telemost-headless-joiner"
    fi
fi

echo "Relay mode: $MODE"

if [ "$SERVICE_TYPE" = "joiner" ]; then
    if [ -z "$CALL_LINK" ]; then
        echo "ERROR: CALL_LINK is required for joiner service"
        echo "Please set CALL_LINK environment variable with the call URL"
        exit 1
    fi
    
    echo "Display Name: $DISPLAY_NAME"
    echo "Call Link: $CALL_LINK"
    echo ""
    
    if [ "$MODE" = "telemost-headless-joiner" ] || [ "$MODE" = "vk-headless-joiner" ]; then
        echo "Starting headless joiner..."
        
        JSON_PARAMS='{"joinLink":"'"$CALL_LINK"'","displayName":"'"$DISPLAY_NAME"'","tunnelMode":"'"$TUNNEL_MODE"'"}'
        
        {
            sleep 2
            echo "JOIN:$JSON_PARAMS"
            exec tail -f /dev/null
        } | /app/relay --mode "$MODE" --ws-port "$WS_PORT" --socks-port "$SOCKS_PORT" --docker-mode
    else
        exec /app/relay --mode "$MODE" --ws-port "$WS_PORT" --socks-port "$SOCKS_PORT"
    fi
else
    echo "Starting relay service..."
    echo "WebSocket port: $WS_PORT"
    echo "SOCKS5 port: $SOCKS_PORT"
    echo ""
    exec /app/relay --mode "$MODE" --ws-port "$WS_PORT" --socks-port "$SOCKS_PORT"
fi
