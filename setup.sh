#!/bin/bash

set -e

# Read dynamic path
PATH_FILE="Codebase/Config/path.txt"
if [ ! -f "$PATH_FILE" ]; then
    echo "path.txt not found at $PATH_FILE"
    exit 1
fi

PROJECT_ROOT=$(cat "$PATH_FILE" | sed 's:/*$::')
INSTALL_SCRIPT="$PROJECT_ROOT/Codebase/Deploy/install-nginx.sh"
NGINX_BIN="$PROJECT_ROOT/nginx/sbin/nginx"
LOG_DIR="$PROJECT_ROOT/logs"
GEN_NGINX="$PROJECT_ROOT/Codebase/Deploy/generate-nginx-conf.sh"
GEN_SITES="$PROJECT_ROOT/Codebase/Deploy/generate-sites.sh"
CERTBOT_SCRIPT="$PROJECT_ROOT/Codebase/Deploy/install-certbot.sh"
FIRST_TIME_CERT_SCRIPT="$PROJECT_ROOT/Codebase/Deploy/first-time-cert.sh"
CHECK_CERTS_SCRIPT="$PROJECT_ROOT/check-certs.sh"
START_SCRIPT="$PROJECT_ROOT/start-nginx.sh"

CRON_JOB="0 1 * * * bash $CHECK_CERTS_SCRIPT >> $PROJECT_ROOT/logs/certbot.log 2>&1"

echo ""
echo "Starting full setup from: $PROJECT_ROOT"

# Ensure logs directory exists
echo "Ensuring log directory exists at: $LOG_DIR"
mkdir -p "$LOG_DIR"

# Install Nginx if missing
if [ ! -f "$NGINX_BIN" ]; then
    echo ""
    echo "Nginx binary not found — running installer..."
    bash "$INSTALL_SCRIPT"
else
    echo ""
    echo "Nginx already installed at: $NGINX_BIN"
fi

# Confirm Nginx installed
if [ ! -x "$NGINX_BIN" ]; then
    echo "Nginx installation failed or binary not executable."
    exit 1
fi

# Generate configs
echo ""
echo "Generating dynamic configs..."
bash "$GEN_NGINX"
bash "$GEN_SITES"

# Install Certbot system-wide
echo ""
echo "Installing Certbot..."
bash "$CERTBOT_SCRIPT"

# Add cronjob if not already present
echo ""
echo "Ensuring daily Certbot renewal cronjob exists..."
CURRENT_CRONTAB=$(crontab -l 2>/dev/null || true)

if echo "$CURRENT_CRONTAB" | grep -F "$CRON_JOB" >/dev/null; then
    echo "Cronjob for cert renewal already exists."
else
    echo "Adding daily cert renewal job to crontab..."
    (echo "$CURRENT_CRONTAB"; echo "$CRON_JOB") | crontab -
fi

echo ""
echo "Setup complete!"
echo "You can check certs at: /etc/letsencrypt/live/<your-domain>"
echo ""


# Ensure webroot for Certbot exists
WEBROOT_DIR="$PROJECT_ROOT/Codebase/Website/.well-known/acme-challenge"
echo ""
echo "Ensuring webroot directory for Certbot exists at: $WEBROOT_DIR"
mkdir -p "$WEBROOT_DIR"
chmod -R 755 "$PROJECT_ROOT/Codebase/Website"

echo "Running first-time certificate generation..."
bash "$FIRST_TIME_CERT_SCRIPT"

echo ""
echo "All done. If certificates were successfully obtained, you can run:"
echo "  bash start-nginx.sh"
echo "to start your final Nginx configuration."
