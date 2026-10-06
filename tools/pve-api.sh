#!/usr/bin/env bash

: "${PROXMOX_URL:?}"
: "${PROXMOX_USERNAME:?}"
: "${PROXMOX_TOKEN:?}"
PROXMOX_NODE="${PROXMOX_NODE:-pve}"

pve_api() {
  local method="$1" path="$2"
  shift 2
  local ca=()
  if [[ -n "${PROXMOX_CA_FILE:-}" ]]; then
    ca=(--cacert "$PROXMOX_CA_FILE")
  fi
  curl -fsS "${ca[@]}" -X "$method" --config - "$@" "${PROXMOX_URL%/}${path}" \
    <<<"header = \"Authorization: PVEAPIToken=${PROXMOX_USERNAME}=${PROXMOX_TOKEN}\""
}

pve_wait_task() {
  local upid="$1" status
  for _ in $(seq 1 120); do
    status="$(pve_api GET "/nodes/${PROXMOX_NODE}/tasks/${upid}/status" | jq -r '.data.status')"
    if [[ "$status" == "stopped" ]]; then
      pve_api GET "/nodes/${PROXMOX_NODE}/tasks/${upid}/status" | jq -e '.data.exitstatus == "OK"' >/dev/null
      return
    fi
    sleep 5
  done
  echo "task ${upid} timed out" >&2
  return 1
}

pve_templates() {
  local os="$1" kind="$2"
  pve_api GET "/nodes/${PROXMOX_NODE}/qemu" |
    jq -r --arg os "$os" --arg kind "$kind" '
      .data[]
      | select(.template == 1)
      | select(((.tags // "") | split(";")) as $t
               | ($t | index("packer")) and ($t | index($os)) and ($t | index($kind)))
      | "\(.name) \(.vmid)"' |
    sort -r -V
}
