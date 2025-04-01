#!/bin/bash

echo "Installing Nginx..."

# Install if not present
if ! command -v nginx >/dev/null 2>&1; then
  echo "Nginx not found. Installing..."
  sudo apt update
  sudo apt install -y nginx
  echo "Nginx installed successfully."
else
  echo "Nginx is already installed."
fi

# Enable service if needed
if ! systemctl is-enabled nginx >/dev/null 2>&1; then
  echo "Enabling Nginx service..."
  sudo systemctl enable nginx
else
  echo "Nginx service is already enabled."
fi

# If another process is listening on port 80 but systemd can't control it
if pgrep -x nginx > /dev/null && ! systemctl is-active --quiet nginx; then
  echo "Nginx process found, but not tracked by systemd. Killing and restarting..."
  sudo killall nginx
fi

# Restart cleanly via systemd
echo "Restarting Nginx with systemd..."
sudo nginx -t && sudo systemctl restart nginx
