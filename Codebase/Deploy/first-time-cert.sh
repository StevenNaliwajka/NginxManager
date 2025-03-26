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
SITES_ENABLED="$PROJECT_ROOT/Codebase/Sites/sites-enabled"
TEMP_NON_SSL_DIR="$PROJECT_ROOT/.tmp-non-ssl"
NGINX_BIN="$PROJECT_ROOT/nginx/sbin/nginx"
NGINX_CONF="$PROJECT_ROOT/Codebase/Config/nginx.conf"
STOP_SCRIPT="$PROJECT_ROOT/stop-nginx.sh"
DEPLOY_SCRIPT="$PROJECT_ROOT/Codebase/Deploy/deploy.sh"
START_SCRIPT="$PROJECT_ROOT/start-nginx.sh"

mkdir -p "$SITES_ENABLED"
mkdir -p "$TEMP_NON_SSL_DIR"

echo ""
echo "Creating temporary non-SSL site configs for Certbot..."

for tmpl in "$TEMPLATE_DIR"/*.template; do
    domain_name=$(basename "$tmpl" .template)
    output_path="$SITES_ENABLED/$domain_name"

    # Remove lines with ssl_*, listen 443, and cert paths
    sed '/listen 443/d;/ssl_/d;/fullchain.pem/d;/privkey.pem/d' "$tmpl" > "$output_path"
    echo "Generated temporary non-SSL config: $output_path"
done

# Start temporary Nginx
echo ""
echo "Starting Nginx temporarily to allow cert issuance..."
$NGINX_BIN -c "$NGINX_CONF"
sleep 2

# Run Certbot per domain
for tmpl in "$TEMPLATE_DIR"/*.template; do
    DOMAIN_LINE=$(grep -E "^\s*server_name\s" "$tmpl" | sed -E 's/^\s*server_name\s+//;s/;$//')
    ROOT_LINE=$(grep -E "^\s*root\s" "$tmpl" | head -n1 | sed -E 's/^\s*root\s+//;s/;$//')

    if [ -z "$DOMAIN_LINE" ] || [ -z "$ROOT_LINE" ]; then
        echo "Skipping $(basename "$tmpl") due to missing domain or root."
        continue
    fi

    ROOT_DIR="${ROOT_LINE//\{\{PROJECT_PATH\}\}/$PROJECT_ROOT}"

    if [ ! -d "$ROOT_DIR" ]; then
        echo "Webroot not found: $ROOT_DIR — skipping $(basename "$tmpl")"
        continue
    fi

    IFS=' ' read -r -a DOMAINS <<< "$DOMAIN_LINE"
    echo -e "\n → Requesting cert for: ${DOMAINS[*]}"
    echo "   Using webroot: $ROOT_DIR"

    sudo certbot certonly --webroot -w "$ROOT_DIR" $(printf -- '-d %s ' "${DOMAINS[@]}") || {
        echo "Certbot failed for: ${DOMAINS[*]}"
    }
done

# Stop temporary Nginx
echo ""
echo "Stopping temporary Nginx..."
bash "$STOP_SCRIPT"
sleep 2

# Clear temporary site configs
echo "Cleaning up temporary non-SSL configs..."
rm -f "$SITES_ENABLED"/*

# Redeploy proper configs (with SSL)
echo ""
echo "Redeploying full site configs with SSL..."
bash "$DEPLOY_SCRIPT"

# Start final Nginx
bash "$START_SCRIPT"

echo ""
echo "First-time cert request complete and live with SSL."
