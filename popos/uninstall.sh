#!/usr/bin/env bash
set -euo pipefail

if (( EUID != 0 )); then
  echo "Use: sudo ./popos/uninstall.sh" >&2
  exit 1
fi

systemctl disable --now discord-golive-bypass.service 2>/dev/null || true
rm -f /etc/systemd/system/discord-golive-bypass.service
rm -f /usr/local/libexec/discord-golive-bypass
rm -rf /etc/discord-golive-bypass
systemctl daemon-reload
systemctl reset-failed discord-golive-bypass.service 2>/dev/null || true

echo "Discord Go Live Bypass removido do Pop!_OS."
