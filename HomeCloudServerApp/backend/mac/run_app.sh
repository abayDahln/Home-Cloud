#!/bin/bash

# Ensure local binary is executable
if [ -f "./server" ]; then
    chmod +x ./server
    SERVER_BIN="./server"
elif [ -f "./server-arm64" ]; then # Fallback for non-lipo environments or direct runs
    if [ "$(uname -m)" == "arm64" ]; then
        SERVER_BIN="./server-arm64"
    else
        SERVER_BIN="./server-amd64"
    fi
else # Assuming user just built for current architecture or cross-compiled one
    SERVER_BIN="./server"
fi

if [ ! -f "$SERVER_BIN" ]; then
    echo "[ERROR] Server binary not found! Please run build_app.sh first."
    exit 1
fi

chmod +x "$SERVER_BIN"

echo "[INFO] Starting HomeCloud Server..."
$SERVER_BIN &
SERVER_PID=$!

echo "[INFO] Starting Cloudflare Tunnel..."
cloudflared tunnel --url http://localhost:8080 &
TUNNEL_PID=$!

trap "kill $SERVER_PID $TUNNEL_PID" EXIT

echo "[SUCCESS] Services started! Press Ctrl+C to stop."
wait
