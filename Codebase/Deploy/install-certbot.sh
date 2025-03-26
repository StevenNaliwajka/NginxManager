#!/bin/bash

set -e

# Resolve project path from path.txt
PATH_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../Config/path.txt"
if [ ! -f "$PATH_FILE" ]; then
    echo "path.txt not found at $PATH_FILE"
    exit 1
fi

PROJECT_ROOT=$(cat "$PATH_FILE" | sed 's:/*$::')

echo "Installing Certbot system-wide..."

# Update and install
sudo apt update
sudo apt install -y certbot

# Confirm install
if command -v certbot >/dev/null 2>&1; then
    echo ""
    echo "Certbot installed successfully!"
    echo "   Location: $(which certbot)"
    echo "   Project path: $PROJECT_ROOT"
else
    echo "Certbot installation failed."
    exit 1
fi
