#!/bin/bash

echo "Stopping Nginx..."

if sudo systemctl is-active --quiet nginx; then
    sudo systemctl stop nginx
    echo "Nginx has been stopped."
else
    echo "Nginx is not running."
fi
