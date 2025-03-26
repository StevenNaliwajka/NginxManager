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

# Ensure necessary directories exist
mkdir -p "$SITES_ENABLED"
mkdir -p "$TEMP_NON_SSL_DIR"

echo ""
echo "Creating temporary non-SSL site configs for Certbot..."

# 1) Generate a temporary non-SSL config for each *.template (except example.com.template)
for tmpl in "$TEMPLATE_DIR"/*.template; do
    domain_name=$(basename "$tmpl" .template)

    # Skip example.com.template
    if [ "$domain_name" = "example.com" ]; then
        echo "Skipping $tmpl because it's the example domain."
        continue
    fi

    temp_config="$SITES_ENABLED/$domain_name"

    # Remove lines with 'listen 443', 'ssl_', and cert paths
    sed '/listen 443/d;/ssl_/d;/fullchain.pem/d;/privkey.pem/d' "$tmpl" > "$temp_config"
    echo "Generated temporary non-SSL config: $temp_config"

    # Save a backup copy in the temporary backup directory
    cp "$temp_config" "$TEMP_NON_SSL_DIR/"
done

# Start temporary Nginx (with non-SSL configs) for Certbot's HTTP challenge
echo ""
echo "Starting Nginx temporarily to allow cert issuance..."
"$NGINX_BIN" -c "$NGINX_CONF"
sleep 2

# 2) Run Certbot for each valid template except example.com.template
for tmpl in "$TEMPLATE_DIR"/*.template; do
    domain_name=$(basename "$tmpl" .template)

    # Skip example.com.template
    if [ "$domain_name" = "example.com" ]; then
        echo "Skipping certbot for $tmpl (example domain)."
        continue
    fi

    DOMAIN_LINE=$(grep -E "^\s*server_name\s" "$tmpl" | sed -E 's/^\s*server_name\s+//;s/;$//')
    ROOT_LINE=$(grep -E "^\s*root\s" "$tmpl" | head -n1 | sed -E 's/^\s*root\s+//;s/;$//')

    if [ -z "$DOMAIN_LINE" ] || [ -z "$ROOT_LINE" ]; then
        echo "Skipping $(basename "$tmpl") due to missing domain or root."
        continue
    fi

    # Replace the placeholder with the actual project root
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
        continue
    }
done

# Stop temporary Nginx
echo ""
echo "Stopping temporary Nginx..."
bash "$STOP_SCRIPT"
sleep 2

# 3) Redeploy proper SSL configs if certs exist; else restore non-SSL
echo ""
echo "Redeploying site configs..."
for tmpl in "$TEMPLATE_DIR"/*.template; do
    domain_name=$(basename "$tmpl" .template)

    # Skip example.com.template
    if [ "$domain_name" = "example.com" ]; then
        echo "Skipping final deploy for example.com."
        continue
    fi

    cert_dir="$PROJECT_ROOT/certs/$domain_name"
    dest_conf="$SITES_ENABLED/$domain_name"

    if [ -d "$cert_dir" ] && [ -f "$cert_dir/fullchain.pem" ] && [ -f "$cert_dir/privkey.pem" ]; then
        echo "Deploying SSL-enabled config for $domain_name"
        bash "$DEPLOY_SCRIPT" "$domain_name"
    else
        echo "No certs found for $domain_name; restoring temporary non-SSL config..."
        cp "$TEMP_NON_SSL_DIR/$domain_name" "$dest_conf"
    fi
done

# 4) Start final Nginx with SSL configs (if certs were issued)
echo ""
echo "Starting Nginx with final configuration..."
bash "$START_SCRIPT"

echo ""
echo "First-time cert request complete and live with SSL (if certs were issued)."
