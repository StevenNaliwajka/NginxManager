#!/bin/bash

# Exit on errors
set -e

echo "Running Nginx Deployer..."

# Get project root and key paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
VENV_PATH="$PROJECT_ROOT/venv"
BUILD_SCRIPT="$PROJECT_ROOT/build_nginx.py"
GENERATED_DIR="$PROJECT_ROOT/GeneratedConfs"
NGINX_AVAILABLE="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"


DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      echo "Unknown argument: $arg"
      exit 1
      ;;
  esac
done

# Activate VENV
if [ ! -d "$VENV_PATH" ]; then
  echo "venv not found at $VENV_PATH. Run setup_venv.sh first."
  exit 1
fi

echo "Activating Python venv..."
source "$VENV_PATH/bin/activate"

# Clean old configs
echo "Cleaning previously generated configs..."
rm -rf "$GENERATED_DIR"
mkdir -p "$GENERATED_DIR"

echo "Building Nginx configuration files..."
python "$BUILD_SCRIPT"

# deploy if not dry run
if [ "$DRY_RUN" = true ]; then
  echo "Dry run enabled — skipping deployment to Nginx."
  echo "You can inspect configs in: $GENERATED_DIR"
else
  echo "Deploying configs to Nginx..."

  sudo mkdir -p "$NGINX_AVAILABLE" "$NGINX_ENABLED"

  for file in "$GENERATED_DIR"/*.conf; do
    filename=$(basename "$file")

    echo "Deploying: $filename"

    # Remove old symlink if exists
    sudo rm -f "$NGINX_ENABLED/$filename"

    # Overwrite site-available file and re-link
    sudo cp "$file" "$NGINX_AVAILABLE/$filename"
    sudo ln -s "$NGINX_AVAILABLE/$filename" "$NGINX_ENABLED/$filename"
  done

  echo "Testing and reloading Nginx..."
  sudo nginx -t && sudo systemctl reload nginx
  echo "Deployment complete."
fi
