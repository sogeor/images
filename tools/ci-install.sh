#!/usr/bin/env bash
set -euo pipefail

: "${ANSIBLE_CORE_VERSION:?}"

if ! command -v xorriso >/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq --no-install-recommends xorriso
fi

python3 -m pip install --user --quiet "ansible-core==${ANSIBLE_CORE_VERSION}"

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$HOME/.local/bin" >>"$GITHUB_PATH"
fi
