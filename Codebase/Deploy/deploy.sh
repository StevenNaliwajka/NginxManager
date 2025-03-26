#!/bin/bash

set -e

# Read project root from path.txt
PATH_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../Config/path.txt"
if [ ! -f "$PATH_FILE" ]; then
    echo "path.txt not found at $PATH_FILE"
    exit 1
fi

PROJECT_ROOT=$(cat "$PATH_FILE" | sed 's:/*$::')  # Strip trailing slashes
NGINX_BIN="$PROJECT_ROOT/nginx/sbin/nginx"
NGINX_CONF="$PROJECT_ROOT/Codebase/Config/nginx.conf"
SITES_AVAILABLE="$PROJECT_ROOT/Codebase/Sites/sites-available"
SITES_ENABLED="$PROJECT_ROOT/Codebase/Sites/sites-enabled"
PID_FILE="/tmp/nginx-local.pid"

echo "Ensuring sites-enabled directory exists..."
mkdir -p "$SITES_ENABLED"

# Clean up old template symlinks if any
echo "Cleaning up *.template symlinks in sites-enabled..."
find "$SITES_ENABLED" -name "*.template" -type l -delete

echo ""
echo "Deploying Nginx site configs..."

link_config() {
    local domain="$1"

    if [[ "$domain" == "example.com" ]]; then
        echo "Skipping example config: $domain"
        return
    fi

    local src="$SITES_AVAILABLE/$domain"
    local dst="$SITES_ENABLED/$domain"

    if [ ! -f "$src" ]; then
        echo "Config not found: $src"
        return
    fi

    ln -sf "$src" "$dst"
    echo "Linked: $domain"
}

# Deploy all or selected domains
if [ "$#" -eq 0 ]; then
    echo "No domains specified. Deploying all from $SITES_AVAILABLE..."
    for file in "$SITES_AVAILABLE"/*; do
        domain=$(basename "$file")

        # Skip *.template files
        if [[ "$domain" == *.template ]]; then
            echo "Skipping template file: $domain"
            continue
        fi

        link_config "$domain"
    done
else
    for domain in "$@"; do
        if [[ "$domain" == *.template ]]; then
            echo "Skipping template argument: $domain"
            continue
        fi
        link_config "$domain"
    done
fi

# Test and reload
echo ""
echo "Testing Nginx configuration..."
$NGINX_BIN -t -c "$NGINX_CONF"

echo ""
if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null 2>&1; then
    PID=$(cat "$PID_FILE")
    echo "Reloading Nginx via PID: $PID"
    kill -HUP "$PID"
else
    echo "No running Nginx instance found to reload."
fi

echo ""
echo "Deployment complete."
