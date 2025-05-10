import json
import argparse
from pathlib import Path
from jinja2 import Environment, FileSystemLoader
from Codebase.ssl_manager import get_certificate_if_needed

# Template map: (type, ssl) -> template filename
template_map = {
    ("host", False): "host_http.conf.j2",
    ("host", True):  "host_https.conf.j2",
    ("proxy", False): "proxy_http.conf.j2",
    ("proxy", True):  "proxy_https.conf.j2",
}

def build_configs(test_mode=False):
    BASE_DIR = Path(__file__).resolve().parent
    CONFIG_FILE = BASE_DIR.parent / "Config/sites.json"
    TEMPLATE_DIR = BASE_DIR / "Templates"
    OUTPUT_DIR = BASE_DIR.parent / "GeneratedConfs"
    CERTS_DIR = BASE_DIR.parent / "Certs"

    env = Environment(loader=FileSystemLoader(str(TEMPLATE_DIR)))

    with open(CONFIG_FILE) as f:
        sites = json.load(f)

    for site in sites:
        domain = site["domain"]
        ssl_enabled = site.get("enable_ssl", False)
        routes = site.get("routes", [])

        for route in routes:
            route_type = route["type"]

            # Cert handling
            cert_path = None
            if ssl_enabled:
                cert_path = CERTS_DIR / domain
                get_certificate_if_needed(site, cert_path, test_mode=test_mode)

            # Fix target if proxy missing scheme
            if route_type == "proxy" and not route["target"].startswith(("http://", "https://")):
                print(f"[*] Auto-prepending 'http://' to target for {domain}")
                route["target"] = f"http://{route['target']}"

            template_name = template_map.get((route_type, ssl_enabled))
            if not template_name:
                print(f"[!] No template for site: {domain}")
                continue

            template = env.get_template(template_name)

            # Determine root path (for host type)
            if route_type == "host":
                target = route.get("target") or f"/var/www/{domain}/html"
            else:
                target = None

            rendered = template.render(
                domain=domain,
                routes=[route],
                cert_path=cert_path,
                target=target
            )

            OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
            output_file = OUTPUT_DIR / f"{domain}.conf"
            with open(output_file, "w") as f:
                f.write("# Managed by NginxDeployer\n")
                f.write(rendered)

            print(f"[+] Generated config for {domain} → {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build Nginx configs from sites.json")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Run in dry-run mode (test SSL cert requests only)"
    )
    args = parser.parse_args()
    build_configs(test_mode=args.dry_run)
