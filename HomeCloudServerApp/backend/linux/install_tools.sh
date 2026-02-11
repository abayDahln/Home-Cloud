#!/bin/bash

# Function to detect the OS/Distro
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo "Unable to detect OS. Please install Go manually."
        exit 1
    fi
}

install_go() {
    echo "[INFO] Installing Go..."
    sudo -v
    
    case "$OS" in
        ubuntu|debian|pop|kali|linuxmint)
            sudo apt-get update
            sudo apt-get install -y golang
            ;;
        arch|manjaro)
            sudo pacman -Sy --noconfirm go
            ;;
        fedora)
            sudo dnf install -y golang
            ;;
        opensuse|suse)
            sudo zypper install -y go
            ;;
        *)
            echo "[WARN] Unsupported distro: $OS. Please install Go manually."
            return 1
            ;;
    esac
}

install_cloudflared() {
    echo "[INFO] Installing Cloudflared..."
    
    # Check if cloudflared binary already exists
    if [ -f "$(pwd)/cloudflared" ]; then
        echo "[INFO] Cloudflared binary exists locally."
        return 0
    fi

    # Determine architecture
    ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
    case $ARCH in
        amd64|x86_64)
            URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
            ;;
        arm64|aarch64)
            URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
            ;;
        *)
            echo "[ERROR] Unsupported architecture: $ARCH"
            return 1
            ;;
    esac

    echo "[INFO] Downloading Cloudflared from $URL..."
    curl -L --output cloudflared "$URL"
    chmod +x cloudflared
    echo "[INFO] Cloudflared installed locally."
}


detect_os
if ! command -v go &> /dev/null; then
    install_go
else
    echo "[INFO] Go is already installed."
fi

install_cloudflared

echo "[SUCCESS] Installation complete! You may need to restart your terminal or source your profile."
