#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this uninstaller as root" >&2
  exit 1
fi

systemctl disable --now anydesk-ipc-watchdog.timer || true
rm -f /etc/systemd/system/anydesk-ipc-watchdog.timer
rm -f /etc/systemd/system/anydesk-ipc-watchdog.service
rm -f /usr/local/sbin/anydesk-ipc-watchdog
systemctl daemon-reload

echo "Removed anydesk-ipc-watchdog files"
