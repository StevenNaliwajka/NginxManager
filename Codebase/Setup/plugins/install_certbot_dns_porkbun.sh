#!/bin/bash

echo "Installing Porkbun DNS plugin inside virtual environment..."

# Get script location and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../../../"
VENV_PATH="$PROJECT_ROOT/.venv"

# Ensure venv exists
if [ ! -d "$VENV_PATH" ]; then
  echo "Virtual environment not found at $VENV_PATH"
  echo "Please run setup_venv.sh first."
  exit 1
fi

# Activate the venv
source "$VENV_PATH/bin/activate"

# Install plugin using pip inside venv
pip install certbot-dns-porkbun

echo "Configuring Porkbun credentials..."

read -p "Enter your Porkbun API key: " PB_API_KEY
read -s -p "Enter your Porkbun Secret API key: " PB_SECRET
echo

# Save credentials to config
CONFIG_DIR="$PROJECT_ROOT/Config"
PORKBUN_INI="$CONFIG_DIR/porkbun.ini"
mkdir -p "$CONFIG_DIR"

cat <<EOF > "$PORKBUN_INI"
certbot_dns_porkbun:dns_porkbun_api_key = $PB_API_KEY
certbot_dns_porkbun:dns_porkbun_secret_api_key = $PB_SECRET
EOF

chmod 600 "$PORKBUN_INI"

echo "Credentials saved to: $PORKBUN_INI"
