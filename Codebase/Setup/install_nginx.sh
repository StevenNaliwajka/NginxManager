#!/bin/bash

echo "Installing Nginx..."

# Check if nginx is already installed
if ! command -v nginx >/dev/null 2>&1; then
  echo "Nginx not found. Installing..."
  sudo apt update
  sudo apt install -y nginx
  echo "Nginx installed successfully."
else
  echo "Nginx is already installed."
fi

# Enable the nginx service only if it's not already enabled
if ! systemctl is-enabled nginx >/dev/null 2>&1; then
  echo "Enabling Nginx service..."
  sudo systemctl enable nginx
else
  echo "Nginx service is already enabled."
fi

# Start or reload nginx depending on current state
if systemctl is-active --quiet nginx; then
  echo "Nginx is already running. Reloading..."
  sudo nginx -t && sudo systemctl reload nginx
else
  echo "Starting Nginx..."
  sudo nginx -t && sudo systemctl start nginx
fi
