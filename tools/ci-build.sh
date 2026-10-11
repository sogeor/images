#!/usr/bin/env bash
# PKR_VAR_base_template (k8s images)
set -euo pipefail

image="${1:?usage: $0 <image>}"
dir="$(dirname "${BASH_SOURCE[0]}")"

if [[ "$image" == *-k8s ]]; then
  os="${image%-k8s}"
  tpl="${PKR_VAR_base_template:-}"
  if [[ -z "$tpl" ]]; then
    tpl="$("$dir/find-template.sh" "$os" base)"
  fi
  if [[ ! "$tpl" =~ ^${os}-base-v[0-9A-Za-z-]+$ ]]; then
    echo "invalid base template: ${tpl}" >&2
    exit 1
  fi
  export PKR_VAR_base_template="$tpl"
  echo "base template: ${tpl}"
fi

exec "$dir/packer.sh" build "$image"
