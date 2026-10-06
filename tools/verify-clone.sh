#!/usr/bin/env bash
set -euo pipefail

template="${1:?usage: $0 <template> [ip/cidr] [gateway]}"
ip_cidr="${2:-192.168.100.250/24}"
gateway="${3:-192.168.100.1}"
ip="${ip_cidr%/*}"
user="verify"

# shellcheck source=tools/pve-api.sh
. "$(dirname "${BASH_SOURCE[0]}")/pve-api.sh"
# shellcheck source=tools/ssh-tunnel.sh
. "$(dirname "${BASH_SOURCE[0]}")/ssh-tunnel.sh"

src_vmid="$(pve_api GET "/nodes/${PROXMOX_NODE}/qemu" |
  jq -r --arg n "$template" '.data[] | select(.template == 1 and .name == $n) | .vmid')"
[[ -n "$src_vmid" ]] || {
  echo "template ${template} not found" >&2
  exit 1
}
new_vmid="$(pve_api GET /cluster/nextid | jq -r '.data')"
work="$(mktemp -d)"

cleanup() {
  echo "destroy ${new_vmid}"
  pve_api POST "/nodes/${PROXMOX_NODE}/qemu/${new_vmid}/status/stop" >/dev/null 2>&1 || true
  sleep 5
  pve_api DELETE "/nodes/${PROXMOX_NODE}/qemu/${new_vmid}?purge=1&destroy-unreferenced-disks=1" >/dev/null 2>&1 || true
  ssh_tunnel_stop
  rm -rf "$work"
}
trap cleanup EXIT

ssh-keygen -q -t ed25519 -N '' -C "verify-clone" -f "$work/id"

echo "clone ${template} (${src_vmid}) -> ${new_vmid}"
upid="$(pve_api POST "/nodes/${PROXMOX_NODE}/qemu/${src_vmid}/clone" \
  --data-urlencode "newid=${new_vmid}" \
  --data-urlencode "name=verify-${new_vmid}" \
  --data-urlencode "full=0" | jq -r '.data')"
pve_wait_task "$upid"

sshkeys="$(jq -rn --rawfile k "$work/id.pub" '$k | @uri')"
pve_api POST "/nodes/${PROXMOX_NODE}/qemu/${new_vmid}/config" \
  --data-urlencode "ciuser=${user}" \
  --data-urlencode "sshkeys=${sshkeys}" \
  --data-urlencode "ipconfig0=ip=${ip_cidr},gw=${gateway}" >/dev/null
pve_api POST "/nodes/${PROXMOX_NODE}/qemu/${new_vmid}/status/start" >/dev/null

ssh_tunnel_start
ssh_host="${BUILD_SSH_HOST:-$ip}"
ssh_opts=(-i "$work/id" -p "$BUILD_SSH_PORT" -o BatchMode=yes -o ConnectTimeout=5
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)
echo "wait for ssh ${ssh_host}:${BUILD_SSH_PORT}"
for _ in $(seq 1 60); do
  if ssh "${ssh_opts[@]}" "${user}@${ssh_host}" true 2>/dev/null; then
    break
  fi
  sleep 5
done
ssh "${ssh_opts[@]}" "${user}@${ssh_host}" 'bash -s' <<'CHECKS'
set -euo pipefail
sudo cloud-init status --wait
test -s /etc/machine-id
ls /etc/ssh/ssh_host_ed25519_key >/dev/null
systemctl is-active qemu-guest-agent
if id packer >/dev/null 2>&1; then echo "build user still exists" >&2; exit 1; fi
if command -v kubeadm >/dev/null; then
  systemctl is-active containerd
  kubeadm version -o short
fi
echo "ok: $(hostname) $(cat /etc/machine-id)"
CHECKS
