#!/bin/bash

set -e

# Determine path relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve project path from path.txt
PATH_FILE="$SCRIPT_DIR/../../Config/default_path.txt"
if [ ! -f "$PATH_FILE" ]; then
    echo "default_path.txt not found at $PATH_FILE"
    exit 1
fi

PROJECT_ROOT=$(cat "$PATH_FILE" | sed 's:/*$::')

echo "Installing Certbot v2.0.0 using pipx (isolated)..."

# Remove apt certbot
sudo apt remove -y certbot || true

# Install pipx if missing
if ! command -v pipx &>/dev/null; then
    echo "Installing pipx..."
    sudo apt update
    sudo apt install -y pipx
    pipx ensurepath
fi

# Ensure pipx is on PATH
export PATH="$PATH:$HOME/.local/bin:/root/.local/bin"

# Install certbot in pipx-managed environment
pipx install --force certbot==2.0.0

# Check certbot version
if certbot --version 2>/dev/null | grep -q "2.0.0"; then
    echo ""
    echo "Certbot 2.0.0 installed successfully!"
    echo "   Version: $(certbot --version)"
    echo "   Location: $(which certbot)"
    echo "   Project path: $PROJECT_ROOT"
else
    echo "Certbot installation failed."
    exit 1
fi
