#!/bin/bash

DNS_PLUGINS=()

# Get Dir for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/plugins"

# Parse CLI Flags
for arg in "$@"; do
  case "$arg" in
    --cloudflare)
      DNS_PLUGINS+=("cloudflare")
      ;;
    --porkbun)
      DNS_PLUGINS+=("porkbun")
      ;;
    --all)
      DNS_PLUGINS+=("cloudflare" "porkbun")
      ;;
    --done)
      break
      ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
  esac
done

# === Install via CLI flags ===
if [ ${#DNS_PLUGINS[@]} -gt 0 ]; then
  for plugin in "${DNS_PLUGINS[@]}"; do
    case "$plugin" in
      cloudflare)
        bash "$PLUGIN_DIR/install_certbot_dns_cloudflare.sh"
        ;;
      porkbun)
        bash "$PLUGIN_DIR/install_certbot_dns_porkbun.sh"
        ;;
    esac
  done
else
  # === Interactive mode ===
  echo "To enable DNS-01 certificate support, select your registrar(s):"
  while true; do
    echo
    echo "Choose DNS plugin to install:"
    echo "1) Cloudflare"
    echo "2) Porkbun"
    echo "3) Done"
    read -p "Enter choice [1-3]: " choice

    case "$choice" in
      1)
        bash "$PLUGIN_DIR/install_certbot_dns_cloudflare.sh"
        DNS_PLUGINS+=("cloudflare")
        ;;
      2)
        bash "$PLUGIN_DIR/install_certbot_dns_porkbun.sh"
        DNS_PLUGINS+=("porkbun")
        ;;
      3)
        echo "Plugin installation finished."
        break
        ;;
      *)
        echo "Invalid option, please choose 1, 2, or 3."
        ;;
    esac
  done
fi

echo
echo "Installed DNS plugins: ${DNS_PLUGINS[*]}"
