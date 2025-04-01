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

# Optional: Start and enable Nginx
echo "Starting and enabling Nginx..."
sudo systemctl enable nginx
sudo systemctl start nginx
