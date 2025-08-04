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

def normalize_domains(domain: str):
    """Returns (bare_domain, www_domain)."""
    if domain.startswith("www."):
        bare = domain[4:]
        return bare, domain
    else:
        return domain, f"www.{domain}"

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
        bare_domain, www_domain = normalize_domains(domain)
        all_domains = [bare_domain, www_domain]
        ssl_enabled = site.get("enable_ssl", False)
        routes = site.get("routes", [])

        cert_path = None
        if ssl_enabled:
            # store certs under bare domain
            cert_path = CERTS_DIR / bare_domain
            # pass www. and bare domains to cert manager
            site["all_domains"] = all_domains
            get_certificate_if_needed(site, cert_path, test_mode=test_mode)

        # Normalize route targets
        for route in routes:
            if route["type"] == "proxy" and not route["target"].startswith(("http://", "https://")):
                print(f"Auto-prepending 'http://' to target for {domain}")
                route["target"] = f"http://{route['target']}"

        # Load appropriate template once
        route_type = routes[0]["type"] if routes else "proxy"
        template_name = template_map.get((route_type, ssl_enabled))
        if not template_name:
            print(f"No template for site: {domain}")
            continue

        template = env.get_template(template_name)

        # Render entire config with all routes
        rendered = template.render(
            domain=domain,
            all_domains=all_domains,
            routes=routes,
            cert_path=cert_path,
            target=None
        )

        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        output_file = OUTPUT_DIR / f"{domain}.conf"
        with open(output_file, "w") as f:
            f.write("# Managed by NginxDeployer\n")
            f.write(rendered)

        print(f"Generated config for {domain} → {output_file}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build Nginx configs from sites.json")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Run in dry-run mode (test SSL cert requests only)"
    )
    args = parser.parse_args()
    build_configs(test_mode=args.dry_run)
