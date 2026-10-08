#!/usr/bin/env bash
set -euo pipefail

os="${1:?usage: $0 <os> <kind>}"
kind="${2:?usage: $0 <os> <kind>}"
keep="${3:-3}"
apply="${4:-}"

[[ "$keep" =~ ^[1-9][0-9]*$ ]] || {
  echo "KEEP must be >= 1" >&2
  exit 2
}

# shellcheck source=tools/pve-api.sh
. "$(dirname "${BASH_SOURCE[0]}")/pve-api.sh"

pve_templates "$os" "$kind" | tail -n +"$((keep + 1))" |
  while read -r name vmid; do
    if [[ "$apply" == "--apply" ]]; then
      echo "delete ${name} (${vmid})"
      upid="$(pve_api DELETE "/nodes/${PROXMOX_NODE}/qemu/${vmid}?purge=1" | jq -r '.data')" &&
        pve_wait_task "$upid" ||
        echo "::warning::skip ${name} (${vmid}): delete failed (linked clones?)"
    else
      echo "[dry-run] delete ${name} (${vmid})"
    fi
  done
