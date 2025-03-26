#!/bin/bash

set -e

echo "Starting full setup..."

# Step 1: Install Nginx
echo ""
echo "Installing local Nginx..."
bash ./Codebase/Install/install-nginx.sh

# Step 2: Install Certbot
echo ""
echo "Installing Certbot (system-wide)..."
bash ./Codebase/Install/install-certbot.sh

echo ""
echo "Setup complete!"
echo "Now you can run: bash start-nginx.sh"
