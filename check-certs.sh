#!/bin/bash

set -e

# Load project root from path.txt
PATH_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Codebase/Config/path.txt"
if [ ! -f "$PATH_FILE" ]; then
    echo "path.txt not found at $PATH_FILE"
    exit 1
fi

PROJECT_ROOT=$(cat "$PATH_FILE" | sed 's:/*$::')

STOP_SCRIPT="$PROJECT_ROOT/stop-nginx.sh"
START_SCRIPT="$PROJECT_ROOT/start-nginx.sh"

echo "Attempting certbot renewal..."
RENEW_OUTPUT=$(sudo certbot renew)

echo "$RENEW_OUTPUT"

if echo "$RENEW_OUTPUT" | grep -q "Congratulations, all renewals succeeded"; then
    echo "Certs renewed. Restarting Nginx..."
    bash "$STOP_SCRIPT"
    bash "$START_SCRIPT"
else
    echo "No certs were renewed. Nginx will keep running."
fi
