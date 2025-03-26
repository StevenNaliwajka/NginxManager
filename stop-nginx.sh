#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="/tmp/nginx-local.pid"

echo "Stopping Nginx..."

if [ ! -f "$PID_FILE" ]; then
    echo "No PID file found — Nginx may not be running."
    exit 0
fi

PID=$(cat "$PID_FILE")

if ps -p "$PID" > /dev/null 2>&1; then
    echo "Stopping Nginx (PID: $PID)..."
    kill -QUIT "$PID"
    sleep 1
else
    echo "PID $PID not running — removing stale PID file..."
fi

rm -f "$PID_FILE"
echo "PID file cleaned up."
echo "Nginx stopped successfully."
