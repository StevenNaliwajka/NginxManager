#!/bin/bash

set -e

# Read dynamic path
PATH_FILE="Config/default_path.txt"
if [ ! -f "$PATH_FILE" ]; then
    echo "default_path.txt not found at $PATH_FILE"
    exit 1
fi

# PATHING
PROJECT_ROOT=$(cat "$PATH_FILE" | sed 's:/*$::')
INSTALL_NGINX="$PROJECT_ROOT/Codebase/Install/install-nginx.sh"
INSTALL_CERTBOT="$PROJECT_ROOT/Codebase/Install/install-certbot.sh"
NGINX_BIN="$PROJECT_ROOT/nginx/sbin/nginx"
CHECK_CERTS_SCRIPT="$PROJECT_ROOT/Codebase/check-certs.sh"
DEPLOY_SCRIPT="$PROJECT_ROOT/Codebase/deploy.sh"
START_SCRIPT="$PROJECT_ROOT/start.sh"
FIRST_TIME_CERT="$PROJECT_ROOT/Codebase/first-time-certs.sh"
NGINX_CONF_SCRIPT="$PROJECT_ROOT/Codebase/build-nginx-conf.sh"

CRON_JOB="0 1 */2 * * bash $CHECK_CERTS_SCRIPT >> $PROJECT_ROOT/logs/certbot.log 2>&1"

# Check for domains.txt or email.txt
MISSING=false

# Check for domains.txt
if [ ! -f "./Config/domains.txt" ]; then
    echo "domain,ip" > ./Config/domains.txt
    echo "'Config/domains.txt' not found. A new one has been created."
    MISSING=true
fi

# Check for email.txt
if [ ! -f "./Config/email.txt" ]; then
    echo "you@example.com" > ./Config/email.txt
    echo "'Config/email.txt' not found. A new one has been created."
    MISSING=true
fi

# Exit if any were missing
if [ "$MISSING" = true ]; then
    echo ""
    echo "Please configure the missing file(s) in Config/ before continuing."
    exit 1
fi


# Install Nginx if missing
if [ ! -f "$NGINX_BIN" ]; then
    echo ""
    echo "Nginx binary not found — running installer..."
    bash "$INSTALL_NGINX"
else
    echo ""
    echo "Nginx already installed at: $NGINX_BIN"
fi

# Confirm Nginx installed
if [ ! -x "$NGINX_BIN" ]; then
    echo "Nginx installation failed or binary not executable."
    exit 1
fi

# Build nginx Conf
echo ""
echo "Building Nginx Conf..."
bash "$NGINX_CONF_SCRIPT"

# Install Certbot
echo ""
echo "Installing Certbot..."
bash "$INSTALL_CERTBOT"

# Build pages as HTTP ONLY
echo ""
echo "Building Reverse-Proxy Pages..."
bash "$DEPLOY_SCRIPT" --phase init

# Start Nginx
echo ""
echo "Start Nginx..."
bash "$START_SCRIPT"

# Get Certifications
echo ""
echo "Attempting to collect certifications..."
bash "$FIRST_TIME_CERT"


# Now Build pages /w FULL HTTPS
echo ""
echo "Building Reverse-Proxy Pages w/ HTTPS..."
bash "$DEPLOY_SCRIPT" --phase full

# Restart Nginx
echo ""
echo "Start Nginx..."
bash "$START_SCRIPT"



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