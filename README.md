# NginxDeployer
Two modes
## host
- Installs Nginx
- Installs Certbot (Let’s Encrypt)
- Sets up reverse proxy to local app (e.g., localhost:3000)
- Creates and enables Nginx config
- ptionally registers service with network-manager (via API or file append)
## reverse proxy
- Same, but proxies to remote upstreams on the LAN
- Focused on routing, not hosting
- Can optionally fetch certs if handling public-facing traffic