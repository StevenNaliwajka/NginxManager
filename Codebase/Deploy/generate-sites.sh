#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/Codebase/Sites/sites-available"
PATH_FILE="$SCRIPT_DIR/Codebase/Config/path.txt"

if [ ! -f "$PATH_FILE" ]; then
    echo "Error: path.txt not found at $PATH_FILE"
    exit 1
fi

# Clean and trim path
PROJECT_PATH="$(sed 's:/*$::' < "$PATH_FILE" | tr -d '[:space:]')"

echo "Using PROJECT_PATH: $PROJECT_PATH"

# Optional cleanup of old rendered files
find "$TEMPLATE_DIR" -maxdepth 1 -type f ! -name '*.template' -exec rm -f {} +

shopt -s nullglob
for template in "$TEMPLATE_DIR"/*.template; do
    base="$(basename "$template" .template)"
    output="$TEMPLATE_DIR/$base"
    echo "Generating: $output"
    sed "s|{{PROJECT_PATH}}|$PROJECT_PATH|g" "$template" > "$output"
done

echo "All site templates rendered successfully."
