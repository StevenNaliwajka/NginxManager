import subprocess
from pathlib import Path
import os

BASE_DIR = Path(__file__).resolve().parent
CONFIG_DIR = BASE_DIR.parent / "Config"

def get_certificate_if_needed(site, cert_path: Path, test_mode=False):
    domain = site["domain"]
    # default to single if not provided
    all_domains = site.get("all_domains", [domain])
    email = site.get("cert_email")
    plugin = site.get("cert_plugin")
    dns_provider = site.get("dns_provider")
    wildcard = site.get("use_wildcard", False)

    if cert_path.exists() and not test_mode:
        live_path = cert_path / "live"
        if (live_path / "fullchain.pem").exists() and (live_path / "privkey.pem").exists():
            print(f"Certificate already exists for {domain}")
            return
        else:
            print(f"[!] Cert path exists but cert files are missing. Reissuing for {domain}...")

    if plugin == "dns-01":
        if not email:
            raise ValueError(f"Missing cert_email for domain '{domain}' using DNS-01 plugin.")
        success = run_certbot_dns01(site, email, dns_provider, cert_path, wildcard, test_mode)
    elif plugin == "http-01":
        success = run_certbot_http01(site, email, cert_path, test_mode)
    else:
        print(f"[!] Unknown cert plugin '{plugin}' for {domain}")
        return

    if success and not test_mode:
        symlink_cert_to_letsencrypt(domain, cert_path, all_domains)
        reload_nginx()

def run_certbot_dns01(site, email, provider, cert_path, wildcard=False, test_mode=False):
    domain = site["domain"]
    all_domains = site.get("all_domains", [domain])

    creds_map = {
        "cloudflare": ("--dns-cloudflare", CONFIG_DIR / "cloudflare.ini"),
        "porkbun": ("--dns-porkbun", CONFIG_DIR / "porkbun.ini"),
    }

    if provider not in creds_map:
        print(f"Unsupported DNS provider for dns-01: {provider}")
        return False

    plugin_flag, creds_file = creds_map[provider]

    domains = []
    for d in all_domains:
        domains.extend(["-d", d])
    if wildcard:
        domains.extend(["-d", f"*.{domain.lstrip('*.')}"])

    cmd = [
        "certbot", "certonly",
        plugin_flag,
        f"--dns-{provider}-credentials", str(creds_file),
        f"--dns-{provider}-propagation-seconds=30",
        "--non-interactive",
        "--agree-tos",
        "--preferred-challenges", "dns",
        "--email", email,
        *domains,
        "--config-dir", str(cert_path),
        "--work-dir", str(cert_path / "work"),
        "--logs-dir", str(cert_path / "logs"),
    ]

    if test_mode:
        cmd.insert(1, "--dry-run")

    print(f"Requesting DNS-01 cert for {', '.join(all_domains)} ({'wildcard' if wildcard else 'standard'})")
    return subprocess.run(cmd).returncode == 0


def run_certbot_http01(site, email, cert_path, test_mode=False):
    domain = site["domain"]
    all_domains = site.get("all_domains", [domain])

    cmd = [
        "certbot", "certonly",
        "--standalone",
        "--non-interactive",
        "--agree-tos",
        "--preferred-challenges", "http",
        "--email", email,
    ]
    for d in all_domains:
        cmd.extend(["-d", d])
    cmd.extend([
        "--config-dir", str(cert_path),
        "--work-dir", str(cert_path / "work"),
        "--logs-dir", str(cert_path / "logs"),
    ])

    if test_mode:
        cmd.insert(1, "--dry-run")

    print(f"Requesting HTTP-01 cert for {', '.join(all_domains)}")
    return subprocess.run(cmd).returncode == 0

def symlink_cert_to_letsencrypt(domain: str, cert_path: Path, all_domains=None):
    target_domain = all_domains[0] if all_domains else domain
    letsencrypt_live = Path(f"/etc/letsencrypt/live/{target_domain}")
    source_live = cert_path / "live" / domain
    fullchain = source_live / "fullchain.pem"
    privkey = source_live / "privkey.pem"

    if not fullchain.exists() or not privkey.exists():
        print(f"[!] Missing expected cert files in {source_live}")
        return

    try:
        letsencrypt_live.mkdir(parents=True, exist_ok=True)

        for file_name in ["fullchain.pem", "privkey.pem"]:
            src = source_live / file_name
            dest = letsencrypt_live / file_name
            if dest.exists() or dest.is_symlink():
                dest.unlink()
            os.symlink(src, dest)

        print(f"[+] Symlinked certs for {', '.join(all_domains) if all_domains else domain} → /etc/letsencrypt/live/{target_domain}")
    except PermissionError:
        print(f"[!] Permission denied: could not symlink to /etc/letsencrypt/live/{target_domain}")


def reload_nginx():
    print("Reloading Nginx...")
    try:
        subprocess.run(["nginx", "-t"], check=True)
        subprocess.run(["systemctl", "reload", "nginx"], check=True)
        print("Nginx reloaded successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Failed to reload Nginx: {e}")
