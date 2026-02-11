#!/bin/bash

# Check if brew is installed
if ! command -v brew &> /dev/null; then
    echo "[INFO] Homebrew not found. Please install Homebrew from https://brew.sh/"
    exit 1
fi

echo "[INFO] Installing Go via Homebrew..."
brew update
brew install go

echo "[INFO] Installing Cloudflared via Homebrew..."
brew install cloudflared

echo "[SUCCESS] Tools setup complete."
