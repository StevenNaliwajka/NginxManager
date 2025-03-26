#!/bin/bash

#exit on error
set -e

SITES_AVAILABLE="./Config/sites-available"
SITES_ENABLED="./Codebase/sites-enabled"
# local nginx binary
NGINX_BIN="./nginx/sbin/nginx"
NGINX_CONF="./Config/nginx.conf"

echo "Ensuring $SITES_ENABLED exists..."
mkdir -p "$SITES_ENABLED"

echo "Deploying Nginx configs..."

link_config() {
    local domain="$1"

    # Skip template example
    if [ "$domain" == "example.com" ]; then
        echo "Skipping template: $domain"
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
echo ""
echo "Testing Nginx config..."
$NGINX_BIN -t -c "$NGINX_CONF"

echo "Reloading Nginx..."
$NGINX_BIN -s reload || true

echo ""
echo "Nginx deployed and reloaded successfully."
