#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this installer as root" >&2
  exit 1
fi

install -d /usr/local/sbin
install -d /etc/systemd/system
install -m 0755 "$ROOT_DIR/bin/anydesk-ipc-watchdog" /usr/local/sbin/anydesk-ipc-watchdog
install -m 0644 "$ROOT_DIR/systemd/anydesk-ipc-watchdog.service" /etc/systemd/system/anydesk-ipc-watchdog.service
install -m 0644 "$ROOT_DIR/systemd/anydesk-ipc-watchdog.timer" /etc/systemd/system/anydesk-ipc-watchdog.timer

systemctl daemon-reload
systemctl enable --now anydesk-ipc-watchdog.timer
systemctl start anydesk-ipc-watchdog.service

echo "Installed anydesk-ipc-watchdog and enabled timer"
