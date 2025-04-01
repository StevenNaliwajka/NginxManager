#!/bin/bash

echo "Installing Cloudflare DNS plugin..."

# Get project root relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../../../"
VENV_PATH="$PROJECT_ROOT/venv"

# Ensure venv exists
if [ ! -d "$VENV_PATH" ]; then
  echo "Virtual environment not found at $VENV_PATH"
  echo "Please run setup_venv.sh first."
  exit 1
fi

# Activate the virtual environment
source "$VENV_PATH/bin/activate"

# Install plugin inside venv
pip install certbot-dns-cloudflare

echo "Configuring Cloudflare credentials..."

read -p "Enter your Cloudflare email: " CF_EMAIL
read -s -p "Enter your Cloudflare API key: " CF_API_KEY
echo

# Create config directory if needed
CONFIG_DIR="$PROJECT_ROOT/Config"
CLOUDFLARE_INI="$CONFIG_DIR/cloudflare.ini"
mkdir -p "$CONFIG_DIR"

# Write credentials to .ini file
cat <<EOF > "$CLOUDFLARE_INI"
dns_cloudflare_email = $CF_EMAIL
dns_cloudflare_api_key = $CF_API_KEY
EOF

# Secure the file
chmod 600 "$CLOUDFLARE_INI"

echo "Credentials saved to: $CLOUDFLARE_INI"
