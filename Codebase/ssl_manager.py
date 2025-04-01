import subprocess
from pathlib import Path
import shutil
import os

BASE_DIR = Path(__file__).resolve().parent
CONFIG_DIR = BASE_DIR.parent / "Config"

def get_certificate_if_needed(site, cert_path: Path, test_mode=False):
    domain = site["domain"]
    email = site.get("cert_email")
    plugin = site.get("cert_plugin")
    dns_provider = site.get("dns_provider")
    wildcard = site.get("use_wildcard", False)

    if cert_path.exists() and not test_mode:
        print(f"Certificate already exists for {domain}")
        return

    if plugin == "dns-01":
        success = run_certbot_dns01(domain, email, dns_provider, cert_path, wildcard, test_mode)
    elif plugin == "http-01":
        success = run_certbot_http01(domain, email, cert_path, test_mode)
    else:
        print(f"[!] Unknown cert plugin '{plugin}' for {domain}")
        return

    if success and not test_mode:
        symlink_cert_to_letsencrypt(domain, cert_path)
        reload_nginx()

def run_certbot_dns01(domain, email, provider, cert_path, wildcard=False, test_mode=False):
    creds_map = {
        "cloudflare": ("--dns-cloudflare", CONFIG_DIR / "cloudflare.ini"),
        "porkbun": ("--dns-porkbun", CONFIG_DIR / "porkbun.ini"),
    }

    if provider not in creds_map:
        print(f"Unsupported DNS provider for dns-01: {provider}")
        return False

    plugin_flag, creds_file = creds_map[provider]

    domains = [f"-d {domain}"]
    if wildcard:
        domains.append(f"-d *.{domain.lstrip('*.')}")

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

    print(f"Requesting DNS-01 cert for {domain} ({'wildcard' if wildcard else 'standard'})")
    return subprocess.run(cmd).returncode == 0

def run_certbot_http01(domain, email, cert_path, test_mode=False):
    cmd = [
        "certbot", "certonly",
        "--standalone",
        "--non-interactive",
        "--agree-tos",
        "--preferred-challenges", "http",
        "--email", email,
        "-d", domain,
        "--config-dir", str(cert_path),
        "--work-dir", str(cert_path / "work"),
        "--logs-dir", str(cert_path / "logs"),
    ]

    if test_mode:
        cmd.insert(1, "--dry-run")

    print(f"Requesting HTTP-01 cert for {domain}")
    return subprocess.run(cmd).returncode == 0

def symlink_cert_to_letsencrypt(domain: str, cert_path: Path):
    letsencrypt_live = Path(f"/etc/letsencrypt/live/{domain}")
    source_live = cert_path / "live"
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

        print(f"[+] Symlinked certs for {domain} → /etc/letsencrypt/live/{domain}")
    except PermissionError:
        print(f"[!] Permission denied: could not symlink to /etc/letsencrypt/live/{domain}")

def reload_nginx():
    print("Reloading Nginx...")
    try:
        subprocess.run(["nginx", "-t"], check=True)
        subprocess.run(["systemctl", "reload", "nginx"], check=True)
        print("Nginx reloaded successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Failed to reload Nginx: {e}")
