#!/usr/bin/env bash
set -euo pipefail

apt-get -y autoremove --purge
apt-get clean
rm -rf /var/lib/apt/lists/*

truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
ln -sf /etc/machine-id /var/lib/dbus/machine-id

rm -f /etc/ssh/ssh_host_*

journalctl --rotate >/dev/null 2>&1 || true
journalctl --vacuum-time=1s >/dev/null 2>&1 || true
find /var/log -type f -exec truncate -s 0 {} \;
rm -rf /tmp/* /var/tmp/*
rm -f /root/.bash_history /home/*/.bash_history

fstrim -av || true
