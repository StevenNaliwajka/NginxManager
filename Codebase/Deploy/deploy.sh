#!/bin/bash

set -e

# Dynamically determine paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
NGINX_BIN="$PROJECT_ROOT/nginx/sbin/nginx"
NGINX_CONF="$PROJECT_ROOT/Codebase/Config/nginx.conf"

SITES_AVAILABLE="$PROJECT_ROOT/Codebase/Sites/sites-available"
SITES_ENABLED="$PROJECT_ROOT/Codebase/Sites/sites-enabled"

echo "Ensuring sites-enabled directory exists..."
mkdir -p "$SITES_ENABLED"

echo ""
echo "Deploying Nginx site configs..."

link_config() {
    local domain="$1"

    # Skip template
    if [[ "$domain" == "example.com" ]]; then
        echo "Skipping template config: $domain"
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
        link_config "$domain"
    done
else
    for domain in "$@"; do
        link_config "$domain"
    done
fi

# Test and reload Nginx
echo ""
echo "Testing Nginx configuration..."
$NGINX_BIN -t -c "$NGINX_CONF"

if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null 2>&1; then
    echo "Reloading Nginx..."
    $NGINX_BIN -s reload
else
    echo "No running Nginx instance found to reload."
fi

echo ""
echo "Deployment complete."
