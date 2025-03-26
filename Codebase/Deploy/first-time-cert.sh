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
GEN_SITES_SCRIPT="$PROJECT_ROOT/Codebase/Deploy/generate-sites.sh"

# Ensure necessary directories exist
mkdir -p "$SITES_ENABLED"
mkdir -p "$TEMP_NON_SSL_DIR"

echo "Stopping any existing Nginx on port 80 (if running)..."
sudo fuser -k 80/tcp || true

# Start temporary Nginx (with non-SSL configs) for Certbot's HTTP challenge
echo ""
echo "Starting Nginx temporarily to allow cert issuance..."
"$NGINX_BIN" -c "$NGINX_CONF"
sleep 2

# Run Certbot for each valid template except example.com.template
for tmpl in "$TEMPLATE_DIR"/*.template; do
    domain_name=$(basename "$tmpl" .template)

    # Skip example.com
    if [[ "$domain_name" == "example.com" ]]; then
        echo "Skipping config/certbot steps for $domain_name."
        continue
    fi

    DOMAIN_LINE=$(grep -E "^\s*server_name\s" "$tmpl" | sed -E 's/^\s*server_name\s+//;s/;$//' | cut -d'#' -f1 | xargs)
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

    # Workaround for certbot bug: handle domains individually if multiple
    if [ "${#DOMAINS[@]}" -gt 1 ]; then
        echo -e "\n → Multiple domains detected for $domain_name. Requesting certs one-by-one to avoid Certbot bug..."
        for DOMAIN in "${DOMAINS[@]}"; do
            echo "   → Requesting cert for: $DOMAIN"
            sudo certbot certonly --webroot --force-renewal -w "$ROOT_DIR" -d "$DOMAIN" || {
                echo "Certbot failed for: $DOMAIN"
                continue
            }
        done
    else
        DOMAIN="${DOMAINS[0]}"
        echo -e "\n → Requesting cert for: $DOMAIN"
        echo "   Using webroot: $ROOT_DIR"

        sudo certbot certonly --webroot --force-renewal -w "$ROOT_DIR" -d "$DOMAIN" || {
            echo "Certbot failed for: $DOMAIN"
            continue
        }
    fi
done

# Stop temporary Nginx
echo ""
echo "Stopping temporary Nginx..."
bash "$STOP_SCRIPT"
sleep 2

# Regenerate site configs now that certs may exist
echo ""
echo "Regenerating site configs with SSL (if certs exist)..."
bash "$GEN_SITES_SCRIPT"

# Redeploy proper SSL configs if certs exist; else restore non-SSL
echo ""
echo "Redeploying site configs..."
for tmpl in "$TEMPLATE_DIR"/*.template; do
    domain_name=$(basename "$tmpl" .template)

    # Skip example.com
    if [[ "$domain_name" == "example.com" ]]; then
        echo "Skipping config/certbot steps for $domain_name."
        continue
    fi

    cert_path="/etc/letsencrypt/live/$domain_name"
    dest_conf="$SITES_ENABLED/$domain_name"

    if [ -d "$cert_path" ] && [ -f "$cert_path/fullchain.pem" ] && [ -f "$cert_path/privkey.pem" ]; then
        echo "Deploying SSL-enabled config for $domain_name"
        bash "$DEPLOY_SCRIPT" "$domain_name"
    else
        echo "No certs found for $domain_name; restoring temporary non-SSL config..."
        cp "$TEMP_NON_SSL_DIR/$domain_name" "$dest_conf"
    fi
done

# Start final Nginx with SSL configs (if certs were issued)
echo ""
echo "Starting Nginx with final configuration..."
bash "$START_SCRIPT"

echo ""
echo "First-time cert request complete and live with SSL (if certs were issued)."
