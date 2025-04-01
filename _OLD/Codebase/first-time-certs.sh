#!/bin/bash

set -e

export PATH="$PATH:$HOME/.local/bin:/root/.local/bin"

CERTS_ISSUED=0

# Config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOMAINS_FILE="$PROJECT_ROOT/Config/domains.txt"
EMAIL_FILE="$PROJECT_ROOT/Config/email.txt"
WEBROOT_PATH="/opt/letsencrypt-challenges"

# Validate email
if [ ! -f "$EMAIL_FILE" ]; then
    echo "Email file not found at $EMAIL_FILE"
    echo "Please create it with your contact email."
    exit 1
fi

EMAIL=$(cat "$EMAIL_FILE" | xargs)

# Ensure challenge path exists
mkdir -p "$WEBROOT_PATH/.well-known/acme-challenge"
chown -R www-data:www-data "$WEBROOT_PATH"

echo ""
echo "Starting first-time SSL certificate generation for all domains..."
echo ""

FIRST_LINE=true

while IFS=, read -r domain ip; do
    # Skip header
    if $FIRST_LINE; then
        FIRST_LINE=false
        if [[ "$domain" == "domain" && "$ip" == "ip" ]]; then
            continue
        fi
    fi

    domain=$(echo "$domain" | xargs)
    ip=$(echo "$ip" | xargs)

    if [[ -z "$domain" || -z "$ip" || "$domain" == \#* ]]; then
        continue
    fi

    echo "Processing $domain"

    # Test file
    TOKEN_NAME="test-token-$RANDOM"
    TOKEN_PATH="$WEBROOT_PATH/.well-known/acme-challenge/$TOKEN_NAME"
    echo "live-check" | tee "$TOKEN_PATH" >/dev/null
    chmod 644 "$TOKEN_PATH"

    # Allow Nginx to serve it
    sleep 2

    # Test accessibility
    if curl -s --max-time 5 "http://$domain/.well-known/acme-challenge/$TOKEN_NAME" | grep -q "live-check"; then
        echo "Challenge path verified for $domain"
    else
        echo "Cannot reach challenge path for $domain"
        echo "Skipping certificate request for $domain"
        rm -f "$TOKEN_PATH"
        continue
    fi

    rm -f "$TOKEN_PATH"

    #--staging \
    # Request certificate
    certbot certonly --webroot \
      --webroot-path "$WEBROOT_PATH" \
      --agree-tos \
      --non-interactive \
      --no-eff-email \
      --email "$EMAIL" \
      -d "$domain"

    if [ $? -eq 0 ]; then
        echo "Certificate obtained for $domain"
        CERTS_ISSUED=$((CERTS_ISSUED + 1))
    else
        echo "Failed to obtain certificate for $domain"
    fi

    echo ""
done < "$DOMAINS_FILE"

echo "Done processing all domains."

if [ "$CERTS_ISSUED" -eq 0 ]; then
    echo "No certificates were successfully issued."
    exit 1
else
    echo "$CERTS_ISSUED certificate(s) were successfully issued."
    exit 0
fi
