#!/bin/bash

set -e

# Read project root from path.txt
PATH_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../Config/path.txt"
if [ ! -f "$PATH_FILE" ]; then
    echo "path.txt not found at $PATH_FILE"
    exit 1
fi

PROJECT_ROOT=$(cat "$PATH_FILE" | sed 's:/*$::')
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
    local src="$SITES_AVAILABLE/$domain"
    local dst="$SITES_ENABLED/$domain"
    local cert_dir="$PROJECT_ROOT/certs/${domain}"

    # Skip example config
    if [[ "$domain" == "example.com" ]]; then
        echo "Skipping example config: $domain"
        return
    fi

    # No config file found? Skip.
    if [ ! -f "$src" ]; then
        echo "Config not found: $src"
        return
    fi

    # Does this config define an SSL server block (listen 443 ssl)?
    if grep -q "listen 443" "$src"; then

        # 1) Deploy the fallback HTTP block from the same file, if it exists
        #    i.e., lines with `listen 80;` remain intact. So your site can at least run on port 80.
        # 2) If we also have valid certs in cert_dir, then keep the 443 block too.
        #    If certs are missing, we comment out or remove the 443 portion so it won't break Nginx.

        # The simplest approach is:
        #    * Always keep the entire file as-is (port 80 + port 443).
        #    * If certs do not exist, comment out the SSL lines.
        # That way, you get a working :80 server block AND the :443 block only if certs exist.

        if [ -d "$cert_dir" ] && [ -f "$cert_dir/fullchain.pem" ] && [ -f "$cert_dir/privkey.pem" ]; then
            # SSL certs exist => keep entire config
            ln -sf "$src" "$dst"
            echo "Linked full SSL-enabled site: $domain"
        else
            echo "No SSL certs for $domain => stripping SSL lines, but leaving port 80"

            # create a version of the config that has 443 lines removed
            sed '/listen 443/d;/ssl_/d;/fullchain.pem/d;/privkey.pem/d' "$src" > "$dst"
            echo "Deployed partial HTTP config for $domain"
        fi
    else
        # No mention of 443 => straightforward symlink
        ln -sf "$src" "$dst"
        echo "Linked: $domain"
    fi
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

# Test and reload Nginx
echo ""
echo "Testing Nginx configuration..."
"$NGINX_BIN" -t -c "$NGINX_CONF"

echo ""
if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null 2>&1; then
    PID=$(cat "$PID_FILE")
    echo "Reloading Nginx via PID: $PID"
    kill -HUP "$PID"
else
    echo "No running Nginx instance found to reload (or no PID file)."
fi

echo ""
echo "Deployment complete."
