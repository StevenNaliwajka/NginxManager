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

# Upgrade pip
sudo python3 -m pip install --upgrade pip

# Install certbot 2.0.0 globally
sudo python3 -m pip install certbot==2.0.0

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
