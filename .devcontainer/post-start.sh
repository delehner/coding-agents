#!/bin/bash
set -euo pipefail

echo "=== Post-Start Setup ==="

# Initialize firewall if running as root or sudo is available
if [ "$(id -u)" -eq 0 ]; then
  /usr/local/bin/init-firewall.sh
elif command -v sudo &> /dev/null; then
  sudo /usr/local/bin/init-firewall.sh
else
  echo "Warning: Cannot initialize firewall (no root/sudo access)"
fi

echo "=== Post-Start Setup Complete ==="
