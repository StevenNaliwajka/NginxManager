#!/bin/bash

NGINX_BIN="/opt/frontend-gateway/nginx/sbin/nginx"
PID_FILE="/opt/frontend-gateway/nginx/logs/nginx.pid"

echo "Checking Nginx status..."

if [ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") > /dev/null 2>&1; then
    echo "Nginx is already running (PID $(cat "$PID_FILE"))."
    echo "Reloading config..."
    sudo "$NGINX_BIN" -s reload
else
    echo "Starting Nginx..."
    sudo "$NGINX_BIN"

    # Verify
    sleep 1
    if ps aux | grep -v grep | grep "$NGINX_BIN" > /dev/null; then
        echo "Nginx started successfully!"
    else
        echo "Failed to start Nginx."
        exit 1
    fi
fi
