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

# Remove existing Certbot installed via apt (if any)
if dpkg -l | grep -q certbot; then
    echo "Removing existing Certbot installed via apt..."
    sudo apt remove --purge -y certbot
fi

# Ensure pipx is installed
if ! command -v pipx >/dev/null 2>&1; then
    echo "Installing pipx..."
    sudo apt install -y pipx
    pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"
fi

# Install Certbot v2.0.0
pipx install certbot==2.0.0 --force

# Confirm install
if command -v certbot >/dev/null 2>&1; then
    echo ""
    echo "Certbot 2.0.0 installed successfully!"
    echo "   Version: $(certbot --version)"
    echo "   Location: $(which certbot)"
    echo "   Project path: $PROJECT_ROOT"
else
    echo "Certbot installation failed."
    exit 1
fi
