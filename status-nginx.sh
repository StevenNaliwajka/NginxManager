#!/bin/bash

set -e

# Read dynamic project root path
PATH_FILE="Codebase/Config/path.txt"
if [ ! -f "$PATH_FILE" ]; then
    echo "path.txt not found at $PATH_FILE"
    exit 1
fi

PROJECT_ROOT=$(cat "$PATH_FILE" | sed 's:/*$::')
PID_FILE="/tmp/nginx-local.pid"
NGINX_BIN="$PROJECT_ROOT/nginx/sbin/nginx"

echo "Checking Nginx status..."

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Nginx is running (PID: $PID)"
    else
        echo "PID file exists, but no process found. Cleaning up..."
        rm -f "$PID_FILE"
    fi
else
    echo "No PID file found at $PID_FILE."

    # Fallback: check if Nginx is running using binary
    if pgrep -f "$NGINX_BIN" > /dev/null 2>&1; then
        PID=$(pgrep -f "$NGINX_BIN")
        echo "Nginx appears to be running (PID: $PID), but no PID file exists."
    else
        echo "Nginx is not running."
    fi
fi
