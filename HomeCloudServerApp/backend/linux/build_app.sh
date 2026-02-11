#!/bin/bash

echo "[INFO] Building backend for Linux..."
cd ..
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=amd64

go build -o linux/server -ldflags "-s -w"

if [ $? -eq 0 ]; then
    echo "[SUCCESS] Build successful! Binary located at linux/server"
else
    echo "[ERROR] Build failed!"
    exit 1
fi
