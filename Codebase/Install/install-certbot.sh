#!/bin/bash

set -e

echo "Installing Certbot system-wide..."

# Update package list
sudo apt update

# Install Certbot via apt
sudo apt install -y certbot

# Confirm installation
if command -v certbot >/dev/null 2>&1; then
    echo ""
    echo "Certbot installed successfully!"
    echo "Location: $(which certbot)"
else
    echo "Certbot installation failed."
    exit 1
fi
