#!/bin/bash

# Ensure local binaries are executable
chmod +x ./server
chmod +x ./cloudflared

echo "[INFO] Starting HomeCloud Server..."
./server &  # Run server in background
SERVER_PID=$!

echo "[INFO] Starting Cloudflare Tunnel..."
./cloudflared tunnel --url http://localhost:8080 & # Start Cloudflared
TUNNEL_PID=$!

trap "kill $SERVER_PID $TUNNEL_PID" EXIT

echo "[SUCCESS] Services started! Press Ctrl+C to stop."
wait
