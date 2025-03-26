#!/bin/bash

PID_FILE="/tmp/nginx-local.pid"
NGINX_BIN="./nginx/sbin/nginx"

echo "Checking Nginx status..."

# Check if PID file exists
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")

    if ps -p "$PID" > /dev/null; then
        echo "Nginx is running (PID: $PID)"
    else
        echo "PID file exists, but process is not running. Cleaning up..."
        rm "$PID_FILE"
    fi
else
    echo "No PID file found at $PID_FILE"

    # Check if process is running by name (fallback)
    if pgrep -f "$NGINX_BIN" > /dev/null; then
        PID=$(pgrep -f "$NGINX_BIN")
        echo "Nginx appears to be running (PID: $PID), but no PID file was found."
    else
        echo "Nginx is not running."
    fi
fi
