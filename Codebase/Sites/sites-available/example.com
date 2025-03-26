# HTTP Server (Redirect to HTTPS)
server {
    listen 80;
    server_name example.com;    ### UPDATE HERE

    # Optional: redirect to HTTPS
    return 301 https://$host$request_uri;
}

# HTTPS Server
server {
    listen 443 ssl;
    server_name example.com;    ### UPDATE HERE

    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;

    location / {
        proxy_pass http://192.168.28.105;   ### UPDATE HERE
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}