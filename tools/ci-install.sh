#!/usr/bin/env bash
set -euo pipefail

: "${CLOUDFLARED_VERSION:?}"
: "${CLOUDFLARED_SHA256:?}"
: "${ANSIBLE_CORE_VERSION:?}"

bin="${RUNNER_TEMP:-/tmp}/bin"
mkdir -p "$bin"
curl -fsSL -o "$bin/cloudflared" \
  "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-amd64"
echo "${CLOUDFLARED_SHA256}  $bin/cloudflared" | sha256sum -c -
chmod +x "$bin/cloudflared"

python3 -m pip install --user --quiet "ansible-core==${ANSIBLE_CORE_VERSION}"

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$bin" >>"$GITHUB_PATH"
  echo "$HOME/.local/bin" >>"$GITHUB_PATH"
fi
