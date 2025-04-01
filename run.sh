#!/bin/bash

# Exit immediately on any error
set -e

echo "Running Nginx Deployer..."

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
VENV_PATH="$PROJECT_ROOT/venv"
BUILD_SCRIPT="$PROJECT_ROOT/Codebase/build_nginx.py"
GENERATED_DIR="$PROJECT_ROOT/GeneratedConfs"
NGINX_AVAILABLE="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"

# Parse CLI flags
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

# Activate Python virtual environment
if [ ! -d "$VENV_PATH" ]; then
  echo "Virtual environment not found at $VENV_PATH. Please run setup_venv.sh first."
  exit 1
fi

echo "Activating Python virtual environment..."
source "$VENV_PATH/bin/activate"

# Clean and rebuild config files
echo "Cleaning previously generated configs..."
rm -rf "$GENERATED_DIR"
mkdir -p "$GENERATED_DIR"

echo "Generating Nginx configuration files..."
python "$BUILD_SCRIPT"

# Deploy configs unless dry run is specified
if [ "$DRY_RUN" = true ]; then
  echo "Dry run enabled. Skipping deployment."
  echo "Generated configs can be found in: $GENERATED_DIR"
else
  echo "Deploying configuration files to Nginx..."

  sudo mkdir -p "$NGINX_AVAILABLE" "$NGINX_ENABLED"

  for file in "$GENERATED_DIR"/*.conf; do
    filename=$(basename "$file")

    echo "Deploying: $filename"

    # Remove existing files if they exist
    sudo rm -f "$NGINX_ENABLED/$filename"
    sudo rm -f "$NGINX_AVAILABLE/$filename"

    # Copy and link new configs
    sudo cp "$file" "$NGINX_AVAILABLE/$filename"
    sudo ln -s "$NGINX_AVAILABLE/$filename" "$NGINX_ENABLED/$filename"
  done

  echo "Testing Nginx configuration..."
  if sudo nginx -t; then
    echo "Reloading Nginx..."
    sudo systemctl reload nginx
    echo "Deployment completed successfully."
  else
    echo "Nginx configuration test failed. Aborting reload."
    exit 1
  fi
fi
