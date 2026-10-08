#!/usr/bin/env bash
set -euo pipefail

if ! command -v xorriso >/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq --no-install-recommends xorriso
fi

python3 -m pip install --user --quiet --require-hashes -r "$(dirname "${BASH_SOURCE[0]}")/requirements-ci.txt"

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$HOME/.local/bin" >>"$GITHUB_PATH"
fi
