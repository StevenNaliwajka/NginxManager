#!/bin/bash

set -e

# Load project root from path.txt
PATH_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../Config/path.txt"
if [ ! -f "$PATH_FILE" ]; then
    echo "path.txt not found at $PATH_FILE"
    exit 1
fi

PROJECT_ROOT=$(cat "$PATH_FILE" | sed 's:/*$::')
TEMPLATE_DIR="$PROJECT_ROOT/Codebase/Sites/sites-available"
DEPLOY_SCRIPT="$PROJECT_ROOT/Codebase/Deploy/deploy.sh"
STOP_NGINX="$PROJECT_ROOT/stop-nginx.sh"
START_NGINX="$PROJECT_ROOT/start-nginx.sh"

echo ""
echo "Attempting to generate SSL certs from .template configs..."

# Step 1: Temporarily copy templates into sites-enabled without SSL lines
TEMP_ENABLED_DIR="$PROJECT_ROOT/Codebase/Sites/sites-enabled"
mkdir -p "$TEMP_ENABLED_DIR"
rm -f "$TEMP_ENABLED_DIR"/*

for tmpl in "$TEMPLATE_DIR"/*.template; do
    domain=$(basename "$tmpl" .template)

    echo "Temporarily enabling non-SSL config for: $domain"

    temp_conf="$TEMP_ENABLED_DIR/$domain"
    sed '/ssl_certificate\|ssl_certificate_key/d' "$tmpl" | sed 's/ listen 443 ssl/ listen 80/' > "$temp_conf"
done

# Step 2: Start nginx with only these configs
echo ""
echo "Starting Nginx temporarily to allow cert issuance..."
bash "$START_NGINX"

# Step 3: Run certbot
for tmpl in "$TEMPLATE_DIR"/*.template; do
    DOMAIN_LINE=$(grep -E "^\s*server_name\s" "$tmpl" | sed -E 's/^\s*server_name\s+//;s/;$//')
    ROOT_LINE=$(grep -E "^\s*root\s" "$tmpl" | head -n1 | sed -E 's/^\s*root\s+//;s/;$//')

    [ -z "$DOMAIN_LINE" ] || [ -z "$ROOT_LINE" ] && continue

    ROOT_DIR="${ROOT_LINE//\{\{PROJECT_PATH\}\}/$PROJECT_ROOT}"
    IFS=' ' read -r -a DOMAINS <<< "$DOMAIN_LINE"

    echo " → Requesting cert for: ${DOMAINS[*]}"
    echo "   Using webroot: $ROOT_DIR"

    sudo certbot certonly --webroot -w "$ROOT_DIR" $(printf -- '-d %s ' "${DOMAINS[@]}") || {
        echo "Certbot failed for: ${DOMAINS[*]}"
    }
done

# Step 4: Stop temporary Nginx
echo ""
echo "Stopping temporary Nginx instance..."
bash "$STOP_NGINX"

# Step 5: Deploy full (SSL-enabled) configs and restart Nginx
echo "Redeploying full config and restarting Nginx..."
bash "$DEPLOY_SCRIPT"
bash "$START_NGINX"

echo ""
echo "First-time cert request complete."
