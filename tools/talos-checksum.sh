#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="$root/talos/talos.env"
# shellcheck source=talos/talos.env
. "$env_file"
: "${TALOS_VERSION:?}" "${TALOS_SCHEMATIC:?}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

image_sum() {
  local platform="$1"
  curl -fsSL --retry 5 -o "$tmp/${platform}.qcow2" \
    "https://factory.talos.dev/image/${TALOS_SCHEMATIC}/v${TALOS_VERSION}/${platform}-amd64.qcow2"
  sha256sum "$tmp/${platform}.qcow2" | cut -d' ' -f1
}

set_value() {
  sed -i "s|^$1=.*|$1=$2|" "$env_file"
}

curl -fsSL --retry 5 -o "$tmp/sha256sum.txt" \
  "https://github.com/siderolabs/talos/releases/download/v${TALOS_VERSION}/sha256sum.txt"
talosctl_sum="$(awk '$2 == "talosctl-linux-amd64" { print $1 }' "$tmp/sha256sum.txt")"
[[ "$talosctl_sum" =~ ^[0-9a-f]{64}$ ]] || {
  echo "talosctl-linux-amd64 not found in sha256sum.txt" >&2
  exit 1
}

set_value TALOS_NOCLOUD_SHA256 "$(image_sum nocloud)"
set_value TALOS_OPENSTACK_SHA256 "$(image_sum openstack)"
set_value TALOSCTL_SHA256 "$talosctl_sum"
grep -E '^TALOS' "$env_file"
