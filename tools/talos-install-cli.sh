#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=talos/talos.env
. "$root/talos/talos.env"
: "${TALOS_VERSION:?}" "${TALOSCTL_SHA256:?}"

bin="${HOME}/.local/bin"
mkdir -p "$bin"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -fsSL --retry 5 -o "$tmp" \
  "https://github.com/siderolabs/talos/releases/download/v${TALOS_VERSION}/talosctl-linux-amd64"
echo "${TALOSCTL_SHA256}  ${tmp}" | sha256sum -c --quiet -
install -m 0755 "$tmp" "$bin/talosctl"

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$bin" >>"$GITHUB_PATH"
fi
"$bin/talosctl" version --client --short
