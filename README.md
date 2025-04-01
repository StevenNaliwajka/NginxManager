# Nginx Deployer


## What's it used for?

- Dynamic Nginx config generation
- Host or reverse proxy support
- Automated SSL with Certbot (DNS-01)
- DNS plugin support (Cloudflare, Porkbun)
- Single `sites.json` config file
- One-line setup and deployment
- Dry run mode for previewing configs
- Easy to version and replicate deployments


## Setup
1) Clone repo
```bash
git clone https://github.com/StevenNaliwajka/NginxManager
cd NginxManager
```
2) Run setup
```bash
bash setup.sh
```
3) Update data in ./Config/sites.json to match your intended use.
4) Run the program
```bash
bash run.sh
```


## Other Scripts

- Stop - stops the program
```bash
bash stop.sh
```
