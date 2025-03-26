#!/bin/bash

PID_FILE="/tmp/nginx-local.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "No running Nginx instance found (PID file not present)."
    exit 0
fi

PID=$(cat "$PID_FILE")

if ps -p "$PID" > /dev/null; then
    echo "Stopping Nginx (PID: $PID)..."
    kill "$PID"
    rm "$PID_FILE"
    echo "Nginx stopped successfully."
else
    echo "PID $PID not running. Cleaning up stale PID file."
    rm "$PID_FILE"
fi