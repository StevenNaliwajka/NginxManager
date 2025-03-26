#!/bin/bash

set -e

TEMPLATE="./Codebase/Config/nginx.conf.template"
OUTPUT="./Codebase/Config/nginx.conf"
PATH_FILE="./Codebase/Config/path.txt"

if [ ! -f "$PATH_FILE" ]; then
    echo "Missing path.txt — please create it with your absolute path (e.g. /opt/)"
    exit 1
fi

PROJECT_PATH=$(cat "$PATH_FILE" | sed 's:/*$::')
sed "s|{{PROJECT_PATH}}|$PROJECT_PATH|g" "$TEMPLATE" > "$OUTPUT"

echo "Generated nginx.conf with path: $PROJECT_PATH"
