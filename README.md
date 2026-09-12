# AnyDesk IPC Watchdog

`systemd` watchdog for Linux hosts where incoming AnyDesk sessions intermittently fail with `IPC timeout` or related local IPC/backend failures.

## What It Does

- Watches `/var/log/anydesk.trace` for new IPC failure signatures.
- Ignores historical log noise on first start.
- Applies a cooldown to avoid restart loops.
- Stops AnyDesk, kills stale `tray` and `backend` processes, removes stale IPC artifacts from `/tmp`, starts AnyDesk again, and ensures the user `--tray` is present in an active `X11` session.

## Why This Exists

On some Linux systems, incoming AnyDesk connections reach the host, but the local AnyDesk stack fails when the service tries to hand the session to the backend/tray process. In our case, the trace included:

- `app.session - IPC timeout`
- `hub_ipc_socket - IPC packet deserialization failed`
- `Service connection lost`

The official AnyDesk guidance says `desk_rt_ipc_error` on Linux is commonly related to:

- unsupported display server setups
- DNS resolver issues

This watchdog is aimed at the local AnyDesk stack getting stuck after strong IPC/backend failures or after long uptime.

## Requirements

- Linux system using `systemd`
- AnyDesk installed as a system service
- Incoming sessions expected to run through **Xorg/X11**
- root privileges for installation

## Project Layout

```text
anydesk-ipc-watchdog/
  bin/
    anydesk-ipc-watchdog
  systemd/
    anydesk-ipc-watchdog.service
    anydesk-ipc-watchdog.timer
  scripts/
    install.sh
    uninstall.sh
  docs/
    incident-notes.md
  README.md
```

## Install

Run as root:

```bash
cd anydesk-ipc-watchdog
./scripts/install.sh
```

Then verify:

```bash
systemctl status anydesk-ipc-watchdog.timer anydesk-ipc-watchdog.service --no-pager
journalctl -t anydesk-ipc-watchdog -n 50 --no-pager
```

## Manual Test

To force the remediation path:

```bash
/usr/local/sbin/anydesk-ipc-watchdog --force-remediate
```

To reset the internal cursor/cooldown state:

```bash
/usr/local/sbin/anydesk-ipc-watchdog --reset-state
```

## Detection Patterns

The watchdog reacts to new log lines matching stronger IPC/backend failure signals:

- `IPC timeout`
- `IPC packet deserialization failed`
- `Service connection lost`

It intentionally does not restart AnyDesk on ordinary `desk_rt_ipc_error` or AnyDesk's own `Zombie process detected` cleanup messages, because those events can happen during reconnects and may make incoming sessions less stable if handled with an immediate restart.

## Default Behavior

- Timer interval: `1 minute`
- Boot delay: `2 minutes`
- Remediation cooldown: `600 seconds`
- Trace file: `/var/log/anydesk.trace`
- State directory: `/var/lib/anydesk-ipc-watchdog`

## Known Limitations

- This is a pragmatic recovery layer, not a fix for AnyDesk internals.
- It assumes the target desktop session is an active local `X11` session.
- It does not solve unsupported Linux distributions.
- It does not repair upstream DNS, firewall, proxy, or vendor bugs.

## Recommended Companion Checks

If `desk_rt_ipc_error` keeps returning, verify:

1. The session is really using `X11`, not Wayland.
2. AnyDesk is current (tested on `8.0.2`).
3. DNS can resolve AnyDesk infrastructure used by your client.
4. Network security tools are not interfering with AnyDesk traffic.
5. You are not relying on an unsupported distribution if reproducibility matters.

## Sources

- AnyDesk status: `desk_rt_ipc_error`  
  <https://support.anydesk.com/docs/status-desk-rt-ipc-error>
- AnyDesk for Linux / Raspberry Pi  
  <https://support.anydesk.com/anydesk-for-linux-raspberry-pi>
- AnyDesk update guide  
  <https://support.anydesk.com/docs/update-anydesk>
- AnyDesk Linux downloads  
  <https://anydesk.com/en-gb/downloads/linux?dv=linux_64>
