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

echo ""
echo "Attempting to generate SSL certs from .template configs..."

for tmpl in "$TEMPLATE_DIR"/*.template; do
    # Extract server_name and root lines
    DOMAIN_LINE=$(grep -E "^\s*server_name\s" "$tmpl" | sed -E 's/^\s*server_name\s+//;s/;$//')
    ROOT_LINE=$(grep -E "^\s*root\s" "$tmpl" | head -n1 | sed -E 's/^\s*root\s+//;s/;$//')

    # Skip if empty or invalid
    if [ -z "$DOMAIN_LINE" ] || [ -z "$ROOT_LINE" ]; then
        echo "Skipping $tmpl due to missing domain or root."
        continue
    fi

    # Replace {{PROJECT_PATH}} in root line
    ROOT_DIR="${ROOT_LINE//\{\{PROJECT_PATH\}\}/$PROJECT_ROOT}"

    # Convert space-separated domains into array
    IFS=' ' read -r -a DOMAINS <<< "$DOMAIN_LINE"

    echo "\n → Requesting cert for: ${DOMAINS[*]}"
    echo "   Using webroot: $ROOT_DIR"

    sudo certbot certonly --webroot -w "$ROOT_DIR" $(printf -- '-d %s ' "${DOMAINS[@]}") || {
        echo "Certbot failed for: ${DOMAINS[*]}"
    }
done

echo "\nFirst-time cert request complete."
