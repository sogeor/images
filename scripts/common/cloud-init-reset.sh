#!/usr/bin/env bash
set -euo pipefail

cloud-init clean --logs --seed

rm -f /etc/netplan/*.yaml
rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg
rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg

cat >/etc/cloud/cloud.cfg.d/99-pve.cfg <<'CFG'
datasource_list: [NoCloud, ConfigDrive]
CFG
