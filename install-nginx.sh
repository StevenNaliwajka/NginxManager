#!/bin/bash

set -e

NGINX_VERSION="1.25.3"
INSTALL_DIR="$(pwd)/nginx"
SRC_DIR="$(pwd)/.nginx-src"
PROJECT_ROOT="$(pwd)"

REQUIRED_PACKAGES=(
    build-essential
    libpcre3
    libpcre3-dev
    zlib1g
    zlib1g-dev
    libssl-dev
    curl
)

echo "Installing Nginx $NGINX_VERSION locally in: $INSTALL_DIR"
echo ""

# Install required packages
echo "Installing required packages..."
sudo apt update
sudo apt install -y "${REQUIRED_PACKAGES[@]}"
echo ""

# Download and extract Nginx source
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "nginx-$NGINX_VERSION.tar.gz" ]; then
    echo "Downloading Nginx source..."
    curl -O "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"
fi

echo "Extracting source..."
tar -xzf "nginx-$NGINX_VERSION.tar.gz"
cd "nginx-$NGINX_VERSION"

# Build and install
echo "Building Nginx..."
./configure --prefix="$INSTALL_DIR"
make
make install

# Return to project root
cd "$PROJECT_ROOT"

echo ""
echo "Nginx has been installed to: $INSTALL_DIR"
echo ""
echo "To start Nginx with your local config, run:"
echo "   bash start-nginx.sh"
echo ""
