#!/bin/bash

# Get absolute path two levels up
TARGET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/Config"

# Ensure the target config directory exists
mkdir -p "$TARGET_DIR"

# Define the JSON content
read -r -d '' JSON_CONTENT << 'EOF'
[
  {
    "domain": "gifs.example.com",
    "dns_provider": "cloudflare",
    "routes": [
      {
        "location": "/",
        "type": "host",
        "target": "/var/www/gifs.example.com/gifs"
      }
    ],
    "enable_ssl": true,
    "cert_plugin": "dns-01",
    "cert_email": "admin@example.com"
  },
  {
    "domain": "gifs.example.com",
    "dns_provider": "porkbun",
    "routes": [
      {
        "location": "/",
        "type": "host",
        "target": "/var/www/gifs.example.com/gifs"
      }
    ],
    "enable_ssl": true,
    "cert_plugin": "http-01",
    "cert_email": "admin@example.com"
  },
  {
    "domain": "api.example.net",
    "dns_provider": "manual",
    "routes": [
      {
        "location": "/",
        "type": "proxy",
        "target": "http://localhost:5000"
      }
    ],
    "enable_ssl": false
  }
]

EOF

# Write the JSON to the target path
echo "$JSON_CONTENT" > "$TARGET_DIR/sites.json"

echo "Created $TARGET_DIR/sites.json"
