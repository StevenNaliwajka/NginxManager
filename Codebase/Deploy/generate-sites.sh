#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/Codebase/Sites/sites-available"
PATH_FILE="$SCRIPT_DIR/Codebase/Config/path.txt"

if [ ! -f "$PATH_FILE" ]; then
    echo "Error: path.txt not found at $PATH_FILE"
    exit 1
fi

PROJECT_PATH="$(sed 's:/*$::' < "$PATH_FILE" | tr -d '[:space:]')"
echo "Using PROJECT_PATH: $PROJECT_PATH"
echo "Cleaning existing rendered site configs..."

# Remove all rendered (non-template) site configs
find "$TEMPLATE_DIR" -maxdepth 1 -type f ! -name '*.template' -exec rm -f {} +

shopt -s nullglob
TEMPLATES=("$TEMPLATE_DIR"/*.template)

if [ ${#TEMPLATES[@]} -eq 0 ]; then
    echo "No templates found in $TEMPLATE_DIR"
    exit 1
fi

echo "Rendering site configs from templates..."
for template in "${TEMPLATES[@]}"; do
    base="$(basename "$template" .template)"
    output="$TEMPLATE_DIR/$base"
    echo " → $output"
    sed "s|{{PROJECT_PATH}}|$PROJECT_PATH|g" "$template" > "$output"
done

echo "All site templates rendered successfully."
