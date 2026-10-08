#!/usr/bin/env bash
# WG_PRIVATE_KEY, WG_SERVER_PUBLIC_KEY, WG_ENDPOINT, WG_ADDRESS, WG_ALLOWED_IPS, PROXMOX_URL, PROXMOX_CA_PEM
set -euo pipefail

: "${WG_PRIVATE_KEY:?}"
: "${WG_SERVER_PUBLIC_KEY:?}"
: "${WG_ENDPOINT:?}"
: "${PROXMOX_URL:?}"
: "${PROXMOX_CA_PEM:?}"

PROXMOX_URL="$(printf '%s' "$PROXMOX_URL" | tr -d '[:space:]')"
WG_ENDPOINT="$(printf '%s' "$WG_ENDPOINT" | tr -d '[:space:]')"
WG_SERVER_PUBLIC_KEY="$(printf '%s' "$WG_SERVER_PUBLIC_KEY" | tr -d '[:space:]')"
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "PROXMOX_URL=${PROXMOX_URL}" >>"$GITHUB_ENV"
fi

address="${WG_ADDRESS:-10.99.0.3/24}"
allowed="${WG_ALLOWED_IPS:-10.99.0.0/24, 192.168.100.0/24}"
dir="${RUNNER_TEMP:-/tmp}/wg"

if ! command -v wg-quick >/dev/null; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq --no-install-recommends wireguard-tools
fi

mkdir -p "$dir"
chmod 700 "$dir"
printf '%s\n' "$WG_PRIVATE_KEY" >"$dir/private.key"
chmod 600 "$dir/private.key"
cat >"$dir/wg0.conf" <<EOF
[Interface]
Address = ${address}
PostUp = wg set %i private-key ${dir}/private.key

[Peer]
PublicKey = ${WG_SERVER_PUBLIC_KEY}
Endpoint = ${WG_ENDPOINT}
AllowedIPs = ${allowed}
PersistentKeepalive = 25
EOF
chmod 600 "$dir/wg0.conf"
sudo wg-quick up "$dir/wg0.conf"

printf '%s\n' "$PROXMOX_CA_PEM" | sudo tee /usr/local/share/ca-certificates/pve-root-ca.crt >/dev/null
sudo update-ca-certificates >/dev/null

url="${PROXMOX_URL%/}/version"
for _ in $(seq 1 30); do
  if [[ "$(curl -s -m 5 -o /dev/null -w '%{http_code}' "$url")" == "401" ]]; then
    echo "wireguard up"
    sudo wg show wg0 latest-handshakes
    exit 0
  fi
  sleep 2
done

echo "Proxmox API not reachable via WireGuard" >&2
sudo wg show wg0 >&2 || true
curl -sS -m 5 -o /dev/null "$url" || true
exit 1
