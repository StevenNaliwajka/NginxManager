#!/bin/bash

echo "Welcome to Nginx Deployer Setup"

# Setup Configs
bash Codebase/Setup/create_config.sh

# Make directories
mkdir -p Certs Logs Utils

# Install Python
bash Codebase/Setup/install_python.sh

# Create VENV and install requirements
bash Codebase/Setup/setup_venv.sh

# Install certbot
bash Codebase/Setup/install_certbot.sh

# Install Nginx
bash Codebase/Setup/install_nginx.sh

# Install Opt Dependencies
bash Codebase/Setup/select_dns_plugins.sh



echo "Setup complete!"
echo "Update './Config/sites.json'"
echo "After that, deploy your configuration with ./run.sh"
