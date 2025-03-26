#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SCRIPT="$PROJECT_ROOT/Codebase/Deploy/install-nginx.sh"
NGINX_BIN="$PROJECT_ROOT/nginx/sbin/nginx"
LOG_DIR="$PROJECT_ROOT/logs"

echo ""
echo "Starting full setup from: $PROJECT_ROOT"

# Ensure logs directory exists
echo "Ensuring log directory exists at: $LOG_DIR"
mkdir -p "$LOG_DIR"

# Install Nginx if missing
if [ ! -f "$NGINX_BIN" ]; then
    echo ""
    echo "Nginx binary not found — running installer..."
    bash "$INSTALL_SCRIPT"
else
    echo ""
    echo "Nginx already installed at: $NGINX_BIN"
fi

# Confirm binary was installed
if [ ! -x "$NGINX_BIN" ]; then
    echo "Nginx installation failed or binary not found."
    exit 1
fi

echo ""
echo "Setup complete!"
echo ""
echo "Verify your config at: $PROJECT_ROOT/Codebase/Sites/sites-available/naliwajka.com"
echo "Then start Nginx using:"
echo "    bash start-nginx.sh"
echo ""
