#!/bin/bash

DOMAINS_FILE="./Config/domains.txt"
WEBROOT_PATH="/opt/letsencrypt-challenges"

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

    sudo certbot certonly --webroot \
      --webroot-path "$WEBROOT_PATH" \
      --agree-tos \
      --non-interactive \
      --no-eff-email \
      --email you@example.com \
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
