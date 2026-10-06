#!/usr/bin/env bash
set -euo pipefail

os="${1:?usage: $0 <os> <kind>}"
kind="${2:?usage: $0 <os> <kind>}"

# shellcheck source=tools/pve-api.sh
. "$(dirname "${BASH_SOURCE[0]}")/pve-api.sh"

name="$(pve_templates "$os" "$kind" | head -n 1 | cut -d' ' -f1)"
[[ -n "$name" ]] || {
  echo "template packer;${os};${kind} not found" >&2
  exit 1
}
echo "$name"
