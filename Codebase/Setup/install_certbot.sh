#!/bin/bash

echo "Installing Certbot..."

# Check if certbot is installed
if ! command -v certbot >/dev/null 2>&1; then
  echo "Certbot not found. Installing..."
  sudo apt update
  sudo apt install -y certbot
  echo "Certbot installed successfully."
else
  echo "Certbot is already installed."
fi

# Optional: Check certbot version
certbot --version
