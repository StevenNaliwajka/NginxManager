#!/bin/bash

# Paths
TEMPLATE_PATH="./Codebase/Templates/nginx.conf.template"
OUTPUT_PATH="./Codebase/Templates/nginx.conf"
DEFAULT_PATH_FILE="./Config/default_path.txt"

# Read the default path from file
if [ ! -f "$DEFAULT_PATH_FILE" ]; then
    echo "Error: default_path.txt not found at $DEFAULT_PATH_FILE"
    exit 1
fi

DEFAULT_PATH=$(cat "$DEFAULT_PATH_FILE" | xargs)

# Check the template exists
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "Error: nginx.conf.template not found at $TEMPLATE_PATH"
    exit 1
fi

# Build nginx.conf
sed "s|PROJECT_PATH|$DEFAULT_PATH|g" "$TEMPLATE_PATH" > "$OUTPUT_PATH"

echo "nginx.conf generated at: $OUTPUT_PATH"
