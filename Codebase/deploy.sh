#!/bin/bash

# Exit on any error
set -e

SITES_AVAILABLE="./sites-available"
SITES_ENABLED="./sites-enabled"
# Path to NGINX binary
NGINX_BIN="/usr/sbin/nginx"

echo "Deploying Nginx configs..."

link_config() {
    local domain="$1"

    # Skip example.com
    if [ "$domain" == "example.com" ]; then
        echo "Skipping: $domain (example config)"
        return
    fi

    local src="$SITES_AVAILABLE/$domain"
    local dst="$SITES_ENABLED/$domain"

    if [ -f "$src" ]; then
        ln -sf "$src" "$dst"
        echo "Linked: $domain"
    else
        echo "Config not found: $domain"
    fi
}

# Deploy all or selected
if [ "$#" -eq 0 ]; then
    echo "No domains specified. Linking all configs in $SITES_AVAILABLE..."
    for file in "$SITES_AVAILABLE"/*; do
        domain=$(basename "$file")
        link_config "$domain"
    done
else
    for domain in "$@"; do
        link_config "$domain"
    done
fi

# Test and reload nginx
echo "Testing Nginx config..."
$NGINX_BIN -t

echo "Reloading Nginx..."
sudo systemctl reload nginx

echo "Nginx reloaded successfully."
