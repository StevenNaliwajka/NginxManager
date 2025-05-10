import subprocess
import argparse
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
CONFIG_SRC_DIR = BASE_DIR / "GeneratedConfigs"
NGINX_ENABLED_DIR = Path("/etc/nginx/sites-enabled")
BUILD_SCRIPT = BASE_DIR / "build_nginx.py"

def get_nginx_substate():
    result = subprocess.run(
        ["systemctl", "show", "nginx", "--property=SubState"],
        capture_output=True,
        text=True
    )
    line = result.stdout.strip()
    print(f"[DEBUG] systemctl SubState output: {line}")
    return line.split("=")[-1] if "=" in line else "unknown"

def start_nginx():
    print("Starting Nginx...")
    try:
        subprocess.run(["systemctl", "start", "nginx"], check=True)
        print("Nginx started successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Failed to start Nginx: {e}")

def reload_or_start_nginx():
    substate = get_nginx_substate()

    if substate == "running":
        print("Reloading Nginx...")
        try:
            subprocess.run(["systemctl", "reload", "nginx"], check=True)
            print("Nginx reloaded successfully.")
        except subprocess.CalledProcessError as e:
            print(f"Reload failed, attempting to start instead: {e}")
            start_nginx()
    else:
        print(f"Nginx is not running (SubState={substate}). Starting it...")
        start_nginx()

def deploy_configs(dry_run=False):
    print(f"Running {'dry-run' if dry_run else 'live'} deployment...")

    print(f"Running build_nginx.py {'--dry-run' if dry_run else ''}...")
    try:
        subprocess.run(["python3", str(BUILD_SCRIPT)] + (["--dry-run"] if dry_run else []), check=True)
    except subprocess.CalledProcessError as e:
        print(f"Failed to build configs: {e}")
        return

    if not CONFIG_SRC_DIR.exists():
        print(f"Config directory missing: {CONFIG_SRC_DIR}")
        return

    for conf_file in CONFIG_SRC_DIR.glob("*.conf"):
        target_link = NGINX_ENABLED_DIR / conf_file.name

        if dry_run:
            print(f"[DRY] Would link {conf_file} → {target_link}")
        else:
            try:
                if target_link.exists() or target_link.is_symlink():
                    target_link.unlink()
                target_link.symlink_to(conf_file.resolve())
                print(f"Linked {conf_file.name} → {target_link}")
            except Exception as e:
                print(f"Failed to create symlink: {e}")
                continue

    print("Testing Nginx configuration...")
    result = subprocess.run(["nginx", "-t"], capture_output=True, text=True)
    if result.returncode != 0:
        print("Nginx config test failed:")
        print(result.stderr)
        return
    else:
        print("Nginx configuration test passed.")

    if dry_run:
        print("Dry-run mode: skipping reload/start.")
        return

    reload_or_start_nginx()

    print("--- Nginx Status ---")
    status = subprocess.run(["systemctl", "status", "nginx"], capture_output=True, text=True)
    print(status.stdout)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Deploy generated Nginx configs.")
    parser.add_argument("--dry-run", action="store_true", help="Simulate cert + config generation and deployment.")
    args = parser.parse_args()

    deploy_configs(dry_run=args.dry_run)
