# Nginx Deployer
Infrastructure as Code (IaC) style Nginx deployer + Cerbot manager

## What's it used for?

- Dynamic Nginx config generation
- Host or reverse proxy support
- Automated SSL with Certbot (DNS-01)
- DNS plugin support (Cloudflare, Porkbun)
- Single `sites.json` config file
- One-line setup and deployment
- Dry run mode for previewing configs
- Easy to version and replicate deployments
--------------

## Setup:
1) Clone repo. Must be cloned out of root(/~/) for proper function.   
/opt/ suggested.
```bash
sudo git clone https://github.com/StevenNaliwajka/NginxManager /opt/NginxManager
cd /opt/NginxManager
```
2) Run setup
```bash
sudo bash setup.sh
```
3) Update data in ./Config/sites.json to match your intended use.
```bash
sudo nano /Config/site.json
```

## Run:
1) Run the program
```bash
sudo bash run.sh
```


## Other Scripts:
- Stop - stops the program
```bash
sudo bash stop.sh
```
