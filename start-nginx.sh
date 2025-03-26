#!/bin/bash

set -e
cd "$(dirname "$0")"

NGINX_BIN="./nginx/sbin/nginx"
NGINX_CONF="$(pwd)/Config/nginx.conf"
PID_FILE="/tmp/nginx-local.pid"

if [ ! -f "$NGINX_BIN" ]; then
    echo "Nginx not found. Run ./install-nginx.sh first."
    exit 1
fi

# Stop if already running
if pgrep -f "$NGINX_BIN" > /dev/null; then
    echo "Stopping existing Nginx instance..."
    $NGINX_BIN -s stop || true
    sleep 1
fi

echo "Starting local Nginx from: $NGINX_BIN"
$NGINX_BIN -c "$NGINX_CONF" -g "pid $PID_FILE;"

echo "Nginx is now running using $NGINX_CONF"
