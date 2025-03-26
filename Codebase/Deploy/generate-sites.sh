#!/bin/bash

set -e

TEMPLATE_DIR="Codebase/Sites/sites-available"
PATH_FILE="Codebase/Config/path.txt"

if [ ! -f "$PATH_FILE" ]; then
    echo "path.txt not found at $PATH_FILE"
    exit 1
fi

PROJECT_PATH=$(cat "$PATH_FILE" | sed 's:/*$::')

echo "Generating site configs using project path: $PROJECT_PATH"
echo

shopt -s nullglob
for template in "$TEMPLATE_DIR"/*.template; do
    base=$(basename "$template" .template)
    output="$TEMPLATE_DIR/$base"

    echo "Generating: $output"
    sed "s|{{PROJECT_PATH}}|$PROJECT_PATH|g" "$template" > "$output"
done

echo
echo "All site templates rendered successfully."
