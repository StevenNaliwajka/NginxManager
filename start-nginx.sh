#!/bin/bash

set -e
cd "$(dirname "$0")"

# Read dynamic project path
PATH_FILE="Codebase/Config/path.txt"
if [ ! -f "$PATH_FILE" ]; then
    echo "path.txt not found at $PATH_FILE"
    exit 1
fi

PROJECT_ROOT=$(cat "$PATH_FILE" | sed 's:/*$::')
NGINX_BIN="$PROJECT_ROOT/nginx/sbin/nginx"
NGINX_CONF="$PROJECT_ROOT/Codebase/Config/nginx.conf"
PID_FILE="/tmp/nginx-local.pid"
DEPLOY_SCRIPT="$PROJECT_ROOT/Codebase/Deploy/deploy.sh"

# Run deploy before start
if [ -f "$DEPLOY_SCRIPT" ]; then
    echo "Deploying site configs before starting Nginx..."
    bash "$DEPLOY_SCRIPT"
fi

# Gracefully stop via PID file if running
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Stopping existing Nginx instance (PID: $PID)..."
        kill -QUIT "$PID"
        sleep 1
    else
        echo "Stale PID file found. Removing..."
        rm -f "$PID_FILE"
    fi
else
    echo "No PID file found — checking port 80 manually..."
fi

# Fallback: check for any process using port 80
if ss -tuln | grep -q ':80'; then
    echo "Port 80 is already in use."

    if pgrep nginx > /dev/null; then
        echo "Attempting to gracefully shut down existing Nginx on port 80..."
        pkill -QUIT nginx
        sleep 1
    else
        echo "Port 80 is in use, but not by Nginx. You'll need to free it manually."
        exit 1
    fi
fi

# Start Nginx
echo "Starting local Nginx from: $NGINX_BIN"
$NGINX_BIN -c "$NGINX_CONF"

# Confirm it actually started
sleep 0.5
if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null 2>&1; then
    echo "Nginx is now running using $NGINX_CONF (PID: $(cat "$PID_FILE"))"
else
    echo "Nginx failed to start. Check logs or configuration."
    exit 1
fi
