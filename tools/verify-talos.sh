#!/usr/bin/env bash
set -euo pipefail

template="${1:?usage: $0 <template> [ip/cidr] [gateway]}"
ip_cidr="${2:-192.168.100.250/24}"
gateway="${3:-192.168.100.1}"
ip="${ip_cidr%/*}"

# shellcheck source=tools/pve-api.sh
. "$(dirname "${BASH_SOURCE[0]}")/pve-api.sh"

command -v talosctl >/dev/null || {
  echo "talosctl not found; run tools/talos-install-cli.sh" >&2
  exit 1
}

src_vmid="$(pve_api GET "/nodes/${PROXMOX_NODE}/qemu" |
  jq -r --arg n "$template" '.data[] | select(.template == 1 and .name == $n) | .vmid')"
[[ -n "$src_vmid" ]] || {
  echo "template ${template} not found" >&2
  exit 1
}
new_vmid="$(pve_api GET /cluster/nextid | jq -r '.data')"

# shellcheck disable=SC2317,SC2329
cleanup() {
  echo "destroy ${new_vmid}"
  pve_api POST "/nodes/${PROXMOX_NODE}/qemu/${new_vmid}/status/stop" >/dev/null 2>&1 || true
  sleep 5
  pve_api DELETE "/nodes/${PROXMOX_NODE}/qemu/${new_vmid}?purge=1&destroy-unreferenced-disks=1" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "clone ${template} (${src_vmid}) -> ${new_vmid}"
upid="$(pve_api POST "/nodes/${PROXMOX_NODE}/qemu/${src_vmid}/clone" \
  --data-urlencode "newid=${new_vmid}" \
  --data-urlencode "name=verify-${new_vmid}" \
  --data-urlencode "full=0" | jq -r '.data')"
pve_wait_task "$upid"

pve_api POST "/nodes/${PROXMOX_NODE}/qemu/${new_vmid}/config" \
  --data-urlencode "ipconfig0=ip=${ip_cidr},gw=${gateway}" >/dev/null
pve_api POST "/nodes/${PROXMOX_NODE}/qemu/${new_vmid}/status/start" >/dev/null

echo "wait for Talos API ${ip}:50000"
up=""
for _ in $(seq 1 60); do
  if timeout 3 bash -c "</dev/tcp/${ip}/50000" 2>/dev/null; then
    up=1
    break
  fi
  sleep 5
done
[[ -n "$up" ]] || {
  echo "Talos API ${ip}:50000 not reachable" >&2
  exit 1
}

talosctl get disks --insecure --nodes "$ip" --endpoints "$ip"

echo "wait for qemu-guest-agent"
for _ in $(seq 1 24); do
  if pve_api POST "/nodes/${PROXMOX_NODE}/qemu/${new_vmid}/agent/ping" >/dev/null 2>&1; then
    echo "ok: ${template} boots to maintenance mode, guest agent answers"
    exit 0
  fi
  sleep 5
done
echo "qemu-guest-agent does not answer" >&2
exit 1
