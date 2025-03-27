#!/bin/bash

set -e

# Set project-relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

TEMPLATE_DIR="$PROJECT_ROOT/Codebase/Templates"
DOMAINS_FILE="$PROJECT_ROOT/Config/domains.txt"
OUTPUT_DIR="$PROJECT_ROOT/sites-enabled"

PHASE="$1"

if [[ "$PHASE" != "--phase" ]]; then
    echo "Usage: $0 --phase [init|full]"
    exit 1
fi

MODE="$2"

if [[ "$MODE" != "init" && "$MODE" != "full" ]]; then
    echo "Error: phase must be 'init' or 'full'"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Select the template based on phase
if [[ "$MODE" == "init" ]]; then
    TEMPLATE_PATH="$TEMPLATE_DIR/example.com.http.template"
else
    TEMPLATE_PATH="$TEMPLATE_DIR/example.com.template"
fi

echo ""
echo "Generating Nginx configs for phase: $MODE"
echo "Using template: $TEMPLATE_PATH"
echo ""

FIRST_LINE=true

while IFS=, read -r domain ip; do
    # Skip header if present
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

    output_file="$OUTPUT_DIR/$domain"
    echo "→ $domain ($ip)"

    sed "s/{{DOMAIN}}/$domain/g; s/{{IP}}/$ip/g" "$TEMPLATE_PATH" > "$output_file"
done < "$DOMAINS_FILE"

echo ""
echo "Config generation complete. Files are in $OUTPUT_DIR"
