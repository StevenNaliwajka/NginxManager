import json
import argparse
from pathlib import Path
from jinja2 import Environment, FileSystemLoader
from ssl_manager import get_certificate_if_needed

# -----------------------------
# Argument parsing
# -----------------------------
parser = argparse.ArgumentParser(description="Build Nginx configs from sites.json")
parser.add_argument(
    "--dry-run",
    action="store_true",
    help="Run in dry-run mode (test SSL cert requests only)"
)
args = parser.parse_args()
test_mode = args.dry_run

# -----------------------------
# Paths
# -----------------------------
BASE_DIR = Path(__file__).resolve().parent
CONFIG_FILE = BASE_DIR.parent / "Config/sites.json"
TEMPLATE_DIR = BASE_DIR / "Setup/Templates"
OUTPUT_DIR = BASE_DIR.parent / "GeneratedConfs"
CERTS_DIR = BASE_DIR.parent / "Certs"


# Setup Jinja2
env = Environment(loader=FileSystemLoader(str(TEMPLATE_DIR)))

# Load sites.json
with open(CONFIG_FILE) as f:
    sites = json.load(f)

# Template map: (type, ssl) -> template filename
template_map = {
    ("host", False): "host_http.conf.j2",
    ("host", True):  "host_https.conf.j2",
    ("proxy", False): "proxy_http.conf.j2",
    ("proxy", True):  "proxy_https.conf.j2",
}

# Process each site
for site in sites:
    domain = site["domain"]
    ssl_enabled = site.get("enable_ssl", False)
    route_type = site["routes"][0]["type"]  # assumes single route for now

    # Cert handling
    cert_path = None
    if ssl_enabled:
        cert_path = CERTS_DIR / domain
        get_certificate_if_needed(site, cert_path, test_mode=test_mode)

    # Select and render template
    template_name = template_map.get((route_type, ssl_enabled))
    if not template_name:
        print(f"[!] No template for site: {domain}")
        continue

    template = env.get_template(template_name)
    rendered = template.render(
        domain=domain,
        routes=site["routes"],
        cert_path=cert_path
    )

    # Write output config
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output_file = OUTPUT_DIR / f"{domain}.conf"
    with open(output_file, "w") as f:
        f.write(rendered)

    print(f"[+] Generated config for {domain} → {output_file}")
