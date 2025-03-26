#!/bin/bash

set -e

# Resolve project path from path.txt
PATH_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../Config/path.txt"
if [ ! -f "$PATH_FILE" ]; then
    echo "path.txt not found at $PATH_FILE"
    exit 1
fi

PROJECT_ROOT=$(cat "$PATH_FILE" | sed 's:/*$::')

echo "Installing Certbot v2.0.0 system-wide using pipx..."

# Remove any apt-installed Certbot
sudo apt remove -y certbot || true

# Ensure pipx is installed
if ! command -v pipx &>/dev/null; then
    echo "Installing pipx..."
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
fi

# Add pipx binary path to PATH for this session
export PATH="$PATH:/root/.local/bin"

# Install or upgrade Certbot via pipx
pipx install --force certbot==2.0.0

# Check if certbot is installed correctly
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
