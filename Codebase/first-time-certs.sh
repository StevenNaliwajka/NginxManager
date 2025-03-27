#!/bin/bash

export PATH="$PATH:$HOME/.local/bin:/root/.local/bin"


DOMAINS_FILE="./Config/domains.txt"
WEBROOT_PATH="/opt/letsencrypt-challenges"
EMAIL_FILE="./Config/email.txt"

if [ ! -f "$EMAIL_FILE" ]; then
    echo "Email file not found at $EMAIL_FILE"
    echo "Please create it with your contact email."
    exit 1
fi

EMAIL=$(cat "$EMAIL_FILE" | xargs)


echo ""
echo "Starting first-time SSL certificate generation for all domains..."
echo ""

# Ensure challenge path exists
mkdir -p "$WEBROOT_PATH"
chown -R www-data:www-data "$WEBROOT_PATH"

while IFS=, read -r domain ip; do
    domain=$(echo "$domain" | xargs)
    ip=$(echo "$ip" | xargs)

    if [[ -z "$domain" || -z "$ip" || "$domain" == \#* ]]; then
        continue
    fi

    echo "Processing $domain"

    certbot certonly --webroot \
      --webroot-path "$WEBROOT_PATH" \
      --agree-tos \
      --non-interactive \
      --no-eff-email \
      --email "$EMAIL" \
      --staging \
      -d "$domain"

    if [ $? -eq 0 ]; then
        echo "Certificate obtained for $domain"
    else
        echo "Failed to obtain certificate for $domain"
    fi

    echo ""
done < "$DOMAINS_FILE"

echo "Done processing all domains."
