#!/bin/bash
set -e

# Load project root from path.txt (using unescaped quotes)
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

# Backup existing configs from sites-enabled to temporary backup directory
cp -f "$SITES_ENABLED"/* "$TEMP_NON_SSL_DIR" 2>/dev/null || true

echo ""
echo "Creating temporary non-SSL site configs for Certbot..."

for tmpl in "$TEMPLATE_DIR"/*.template; do
    domain_name=$(basename "$tmpl" .template)
    output_path="$SITES_ENABLED/$domain_name"
    # Remove lines with 'listen 443', 'ssl_', and certificate paths
    sed '/listen 443/d;/ssl_/d;/fullchain.pem/d;/privkey.pem/d' "$tmpl" > "$output_path"
    echo "Generated temporary non-SSL config: $output_path"
done

# Start temporary Nginx
echo ""
echo "Starting Nginx temporarily to allow cert issuance..."
$NGINX_BIN -c "$NGINX_CONF"
sleep 2

# Run Certbot per domain from each template.
for tmpl in "$TEMPLATE_DIR"/*.template; do
    DOMAIN_LINE=$(grep -E "^\s*server_name\s" "$tmpl" | sed -E 's/^\s*server_name\s+//;s/;$//')
    ROOT_LINE=$(grep -E "^\s*root\s" "$tmpl" | head -n1 | sed -E 's/^\s*root\s+//;s/;$//')

    if [ -z "$DOMAIN_LINE" ] || [ -z "$ROOT_LINE" ]; then
        echo "Skipping $(basename "$tmpl") due to missing domain or root."
        continue
    fi

    # Replace placeholder with actual project path
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

# Redeploy proper configs (with SSL enabled) using temporary non-SSL override
echo ""
echo "Redeploying full site configs with SSL (forcing non-SSL temporary mode)..."
bash "$DEPLOY_SCRIPT" --force-non-ssl

# Start final Nginx with proper SSL-enabled configs (certs should now be in place)
echo ""
echo "Starting Nginx with final configuration..."
bash "$START_SCRIPT"

echo ""
echo "First-time cert request complete and live with SSL (if certs were issued)."
