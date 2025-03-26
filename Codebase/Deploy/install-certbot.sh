#!/bin/bash

set -e

# Resolve project path from path.txt
PATH_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../Config/path.txt"
if [ ! -f "$PATH_FILE" ]; then
    echo "path.txt not found at $PATH_FILE"
    exit 1
fi

PROJECT_ROOT=$(cat "$PATH_FILE" | sed 's:/*$::')

echo "Installing Certbot v2.0.0 system-wide using pip..."

# Remove apt-installed certbot if present
sudo apt remove -y certbot || true

# Ensure python3-pip is installed
if ! command -v pip3 &>/dev/null; then
    echo "pip3 not found. Installing python3-pip..."
    sudo apt update
    sudo apt install -y python3-pip
fi

# Upgrade pip
echo "Upgrading pip..."
sudo python3 -m pip install --upgrade pip

# Install certbot 2.0.0 globally
echo "Installing Certbot v2.0.0..."
sudo python3 -m pip install --upgrade "certbot==2.0.0"

# Confirm it's installed correctly
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
