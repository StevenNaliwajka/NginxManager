#!/bin/bash
set -e
CERTBOT_BIN=$(command -v certbot || echo "/root/.local/bin/certbot")

# Support --staging flag
USE_STAGING=false
for arg in "$@"; do
    if [[ "$arg" == "--staging" ]]; then
        USE_STAGING=true
    fi
done

# Load project root from path.txt
PATH_FILE="$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)/../Config/path.txt"
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
START_SCRIPT="$PROJECT_ROOT/start-nginx.sh"
GEN_SITES_SCRIPT="$PROJECT_ROOT/Codebase/Deploy/generate-sites.sh"

# Ensure necessary directories exist
mkdir -p "$SITES_ENABLED"
mkdir -p "$TEMP_NON_SSL_DIR"

# Strip SSL blocks and prepare temporary HTTP-only configs
for tmpl in "$TEMPLATE_DIR"/*.template; do
    domain_name=$(basename "$tmpl" .template)

    if [[ "$domain_name" == "example.com" ]]; then
        continue
    fi

    non_ssl_path="$TEMP_NON_SSL_DIR/$domain_name"
    sed '/listen 443/,/}/d' "$TEMPLATE_DIR/$domain_name" > "$non_ssl_path"
    cp "$non_ssl_path" "$SITES_ENABLED/$domain_name"

done

echo ""
echo "Ensuring port 80 is free..."
sudo fuser -k 80/tcp || true

# Start temporary Nginx (with non-SSL configs) for Certbot's HTTP challenge
echo "\nStarting Nginx temporarily to allow cert issuance..."
"$NGINX_BIN" -c "$NGINX_CONF"
sleep 2

# Run Certbot for each valid template except example.com.template
for tmpl in "$TEMPLATE_DIR"/*.template; do
    domain_name=$(basename "$tmpl" .template)

    if [[ "$domain_name" == "example.com" ]]; then
        continue
    fi

    DOMAIN_LINE=$(grep -E "^\s*server_name\s" "$tmpl" | sed -E 's/^\s*server_name\s+//;s/;\$//' | cut -d'#' -f1 | xargs)
    ROOT_LINE=$(grep -E "^\s*root\s" "$tmpl" | head -n1 | sed -E 's/^\s*root\s+//;s/;\$//')

    if [ -z "$DOMAIN_LINE" ] || [ -z "$ROOT_LINE" ]; then
        continue
    fi

    ROOT_DIR="${ROOT_LINE//\{\{PROJECT_PATH\}\}/$PROJECT_ROOT}"

    if [ ! -d "$ROOT_DIR" ]; then
        echo "Webroot not found: $ROOT_DIR — skipping $domain_name"
        continue
    fi

    IFS=' ' read -r -a DOMAINS <<< "$DOMAIN_LINE"

    for DOMAIN in "${DOMAINS[@]}"; do
        echo -e "\n → Requesting cert for: $DOMAIN"
        CMD=(sudo "$CERTBOT_BIN" certonly --webroot \
            --config-dir /etc/letsencrypt \
            --work-dir /var/lib/letsencrypt \
            --logs-dir /var/log/letsencrypt \
            -w "$ROOT_DIR" -d "$DOMAIN")

        if \$USE_STAGING; then
            CMD+=(--server https://acme-staging-v02.api.letsencrypt.org/directory)
        fi

        "${CMD[@]}" || {
            echo "Certbot failed for: $DOMAIN"
            continue
        }
    done

done

# Stop temporary Nginx
echo "\nStopping temporary Nginx..."
bash "$STOP_SCRIPT"
sleep 2

# Regenerate site configs now that certs may exist
echo "\nRegenerating site configs with SSL (if certs exist)..."
bash "$GEN_SITES_SCRIPT"

# Start final Nginx with SSL configs (if certs were issued)
echo "\nStarting Nginx with final configuration..."
bash "$START_SCRIPT"

echo "\nFirst-time cert request complete and live with SSL (if certs were issued)."