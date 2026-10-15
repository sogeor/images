#!/usr/bin/env bash
# TALOS_IMPORT_STORAGE, TALOS_DISK_STORAGE, TALOS_BRIDGE
set -euo pipefail

build="${1:?usage: $0 <build_version>}"
[[ "$build" =~ ^[0-9A-Za-z-]+$ ]] || {
  echo "invalid build version: ${build}" >&2
  exit 2
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=talos/talos.env
. "$root/talos/talos.env"
# shellcheck source=tools/pve-api.sh
. "$root/tools/pve-api.sh"

: "${TALOS_VERSION:?}" "${TALOS_SCHEMATIC:?}" "${TALOS_NOCLOUD_SHA256:?}"
import_storage="${TALOS_IMPORT_STORAGE:-local}"
disk_storage="${TALOS_DISK_STORAGE:-local-lvm}"
bridge="${TALOS_BRIDGE:-vmbr0}"

schematic_short="${TALOS_SCHEMATIC:0:12}"
version_tag="talos-${TALOS_VERSION//./-}"
schematic_tag="schematic-${schematic_short}"
name="talos-base-v${build}"
file="talos-v${TALOS_VERSION}-${schematic_short}-nocloud-amd64.qcow2"
volid="${import_storage}:import/${file}"
url="https://factory.talos.dev/image/${TALOS_SCHEMATIC}/v${TALOS_VERSION}/nocloud-amd64.qcow2"

output() {
  echo "template: $1"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "template=$1" >>"$GITHUB_OUTPUT"
  fi
}

existing="$(pve_api GET "/nodes/${PROXMOX_NODE}/qemu" |
  jq -r --arg v "$version_tag" --arg s "$schematic_tag" '
    .data[]
    | select(.template == 1)
    | select(((.tags // "") | split(";")) as $t
             | ($t | index("packer")) and ($t | index("talos")) and ($t | index($v)) and ($t | index($s)))
    | .name' | head -n 1)"
if [[ -n "$existing" ]]; then
  echo "template for Talos ${TALOS_VERSION} and schematic ${schematic_short} already exists"
  output "$existing"
  exit 0
fi

if ! pve_api GET "/nodes/${PROXMOX_NODE}/storage/${import_storage}/content?content=import" |
  jq -e --arg v "$volid" '.data[] | select(.volid == $v)' >/dev/null; then
  echo "download-url ${url}"
  upid="$(pve_api POST "/nodes/${PROXMOX_NODE}/storage/${import_storage}/download-url" \
    --data-urlencode "url=${url}" \
    --data-urlencode "content=import" \
    --data-urlencode "filename=${file}" \
    --data-urlencode "checksum=${TALOS_NOCLOUD_SHA256}" \
    --data-urlencode "checksum-algorithm=sha256" | jq -r '.data')"
  if ! pve_wait_task "$upid"; then
    pve_api DELETE "/nodes/${PROXMOX_NODE}/tasks/$(jq -rn --arg u "$upid" '$u | @uri')" >/dev/null 2>&1 || true
    echo "download-url failed or timed out" >&2
    exit 1
  fi
fi

vmid="$(pve_api GET /cluster/nextid | jq -r '.data')"
created=""
cleanup() {
  if [[ -n "$created" ]]; then
    echo "remove unfinished VM ${vmid}" >&2
    pve_api DELETE "/nodes/${PROXMOX_NODE}/qemu/${vmid}?purge=1&destroy-unreferenced-disks=1" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

echo "create ${name} (${vmid})"
upid="$(pve_api POST "/nodes/${PROXMOX_NODE}/qemu" \
  --data-urlencode "vmid=${vmid}" \
  --data-urlencode "name=${name}" \
  --data-urlencode "description=Talos v${TALOS_VERSION} nocloud, schematic ${TALOS_SCHEMATIC}, build ${build}, git ${GITHUB_SHA:-local}" \
  --data-urlencode "tags=packer;talos;base;${version_tag};${schematic_tag};v${build}" \
  --data-urlencode "ostype=l26" \
  --data-urlencode "machine=q35" \
  --data-urlencode "bios=ovmf" \
  --data-urlencode "cpu=host" \
  --data-urlencode "cores=2" \
  --data-urlencode "memory=2048" \
  --data-urlencode "scsihw=virtio-scsi-single" \
  --data-urlencode "efidisk0=${disk_storage}:1,efitype=4m,pre-enrolled-keys=0" \
  --data-urlencode "scsi0=${disk_storage}:0,import-from=${volid},iothread=1,discard=on" \
  --data-urlencode "ide2=${disk_storage}:cloudinit" \
  --data-urlencode "boot=order=scsi0" \
  --data-urlencode "net0=virtio,bridge=${bridge}" \
  --data-urlencode "agent=enabled=1" \
  --data-urlencode "serial0=socket" | jq -r '.data')"
created=1
pve_wait_task "$upid"

upid="$(pve_api POST "/nodes/${PROXMOX_NODE}/qemu/${vmid}/template" | jq -r '.data')"
if [[ "$upid" == UPID:* ]]; then
  pve_wait_task "$upid"
fi
created=""
output "$name"
