#!/bin/bash

# Build for macOS (Universal or specific arch)
# Since Go cross-compilation is easy, we can build for both AMD64 and ARM64

echo "[INFO] Building backend for macOS..."
cd ..

# Build for AMD64
echo "[INFO] Building AMD64 Binary..."
GOOS=darwin GOARCH=amd64 go build -o mac/server-amd64 -ldflags "-s -w"

# Build for ARM64 (Apple Silicon)
echo "[INFO] Building ARM64 Binary..."
GOOS=darwin GOARCH=arm64 go build -o mac/server-arm64 -ldflags "-s -w"

if [ -f "mac/server-amd64" ] && [ -f "mac/server-arm64" ]; then
    echo "[SUCCESS] Build successful! Binaries located at 'mac/server-amd64' and 'mac/server-arm64'"
    
    # Create a universal binary if lipo is available (optional but good)
    if command -v lipo &> /dev/null; then
        lipo -create -output mac/server mac/server-amd64 mac/server-arm64
        echo "[INFO] Universal binary created: 'mac/server'"
        rm mac/server-amd64 mac/server-arm64
    else
        echo "[WARN] lipo not found, separate binaries kept."
    fi
else
    echo "[ERROR] Build failed!"
    exit 1
fi
