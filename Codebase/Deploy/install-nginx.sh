#!/bin/bash

set -e

# Dynamically determine paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
INSTALL_DIR="$PROJECT_ROOT/nginx"
SRC_DIR="$PROJECT_ROOT/.nginx-src"
NGINX_VERSION="1.25.3"

REQUIRED_PACKAGES=(
    build-essential
    libpcre3
    libpcre3-dev
    zlib1g
    zlib1g-dev
    libssl-dev
    curl
)

echo "Installing Nginx $NGINX_VERSION locally into: $INSTALL_DIR"
echo ""

# Install required dependencies
echo "Installing required packages..."
# Use sudo only if not already root
SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

$SUDO apt update
$SUDO apt install -y "${REQUIRED_PACKAGES[@]}"
echo ""

# Prepare source build folder
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# Download Nginx source if not already present
if [ ! -f "nginx-$NGINX_VERSION.tar.gz" ]; then
    echo "⬇Downloading Nginx source..."
    curl -O "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"
fi

echo "Extracting source..."
tar -xzf "nginx-$NGINX_VERSION.tar.gz"
cd "nginx-$NGINX_VERSION"

# Build and install locally
echo "Building Nginx..."
./configure --prefix="$INSTALL_DIR"
make
make install

# Copy mime.types into your Config directory
MIME_SRC="$INSTALL_DIR/conf/mime.types"
MIME_DEST="$PROJECT_ROOT/Codebase/Config/mime.types"

if [ -f "$MIME_SRC" ]; then
    echo "Copying mime.types to Config/"
    cp "$MIME_SRC" "$MIME_DEST"
else
    echo "mime.types not found in $MIME_SRC — skipping copy"
fi

# Return to root
cd "$PROJECT_ROOT"

echo ""
echo "Nginx installed successfully to: $INSTALL_DIR"
echo ""
echo "To start Nginx with your local config, run:"
echo "    bash start-nginx.sh"
echo ""
