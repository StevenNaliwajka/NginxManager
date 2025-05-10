import subprocess
import argparse
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).resolve().parent
CONFIG_SRC_DIR = BASE_DIR / "GeneratedConfigs"
NGINX_ENABLED_DIR = Path("/etc/nginx/sites-enabled")
BUILD_SCRIPT = BASE_DIR / "build_nginx.py"

def is_nginx_active():
    result = subprocess.run(["systemctl", "is-active", "nginx"], capture_output=True, text=True)
    return result.stdout.strip() == "active"

def start_nginx():
    print("Starting Nginx...")
    try:
        subprocess.run(["systemctl", "start", "nginx"], check=True)
        print("Nginx started successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Failed to start Nginx: {e}")

def deploy_configs(dry_run=False):
    print(f"Running {'dry-run' if dry_run else 'live'} deployment...")

    # Step 1: Call build_nginx.py
    print(f"Running build_nginx.py {'--dry-run' if dry_run else ''}...")
    try:
        subprocess.run(["python3", str(BUILD_SCRIPT)] + (["--dry-run"] if dry_run else []), check=True)
    except subprocess.CalledProcessError as e:
        print(f"Failed to build configs: {e}")
        return

    # Step 2: Simulate or execute symlinks
    if not CONFIG_SRC_DIR.exists():
        print(f"Config directory missing: {CONFIG_SRC_DIR}")
        return

    for conf_file in CONFIG_SRC_DIR.glob("*.conf"):
        target_link = NGINX_ENABLED_DIR / conf_file.name

        if dry_run:
            print(f"[DRY] Would link {conf_file} → {target_link}")
        else:
            try:
                target_link.symlink_to(conf_file.resolve())
                print(f"[+] Linked {conf_file.name} → {target_link}")
            except FileExistsError:
                print(f"Replacing existing link: {target_link}")
                target_link.unlink()
                target_link.symlink_to(conf_file.resolve())

    # Step 3: Test Nginx config
    print("Testing Nginx configuration...")
    result = subprocess.run(["nginx", "-t"], capture_output=True, text=True)

    if result.returncode != 0:
        print("Nginx config test failed:")
        print(result.stderr)
        return

    if dry_run:
        print("[DRY] Skipping Nginx reload (dry-run mode).")
        return

    # Step 4: Reload Nginx (or start if not running)
    if is_nginx_active():
        print("Reloading Nginx...")
        try:
            subprocess.run(["systemctl", "reload", "nginx"], check=True)
            print("Nginx reloaded successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Failed to reload Nginx: {e}")
    else:
        print("Nginx is not running. Attempting to start...")
        start_nginx()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Deploy generated Nginx configs.")
    parser.add_argument("--dry-run", action="store_true", help="Simulate cert + config generation and deployment.")
    args = parser.parse_args()

    deploy_configs(dry_run=args.dry_run)
