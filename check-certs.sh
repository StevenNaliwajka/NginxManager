#!/bin/bash

echo "Attempting certbot renewal..."
sudo certbot renew

# Restart Nginx only if certs were actually renewed
if [ $? -eq 0 ]; then
    echo "Certs renewed. Restarting Nginx..."
    bash stop-nginx.sh
    bash start-nginx.sh
else
    echo "No certs were renewed. Nginx will keep running."
fi
