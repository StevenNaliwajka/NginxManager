#!/bin/bash

set -e

# Absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT_FILE="$SCRIPT_DIR/../Config/default_path.txt"
TEMPLATE_PATH="$SCRIPT_DIR/Templates/nginx.conf.template"

# Confirm default_path.txt exists
if [ ! -f "$PROJECT_ROOT_FILE" ]; then
    echo "Error: default_path.txt not found at $PROJECT_ROOT_FILE"
    exit 1
fi

# Read and clean path
PROJECT_ROOT=$(cat "$PROJECT_ROOT_FILE" | xargs)
FINAL_PATH="$PROJECT_ROOT/nginx/conf/nginx.conf"

echo "Using PROJECT_ROOT: $PROJECT_ROOT"
echo "Reading from template: $TEMPLATE_PATH"
echo "Writing output to: $FINAL_PATH"

# Confirm template exists
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "Error: nginx.conf.template not found at $TEMPLATE_PATH"
    exit 1
fi

# Make sure output dir exists
mkdir -p "$(dirname "$FINAL_PATH")"

# Perform the replacement
sed "s|{{PROJECT_ROOT}}|$PROJECT_ROOT|g" "$TEMPLATE_PATH" > "$FINAL_PATH"

echo "nginx.conf successfully generated at: $FINAL_PATH"
