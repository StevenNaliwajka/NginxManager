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
    sleep 1
else
    echo "PID $PID is not running, but PID file exists."
fi

# Check if PID file still exists and remove it
if [ -f "$PID_FILE" ]; then
    rm "$PID_FILE"
    echo "PID file cleaned up."
fi

echo "Nginx stopped successfully."
