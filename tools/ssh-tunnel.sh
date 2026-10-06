#!/usr/bin/env bash
# PACKER_SSH_HOSTNAME, PACKER_SSH_LOCAL_PORT
# shellcheck disable=SC2034

ssh_tunnel_start() {
  BUILD_SSH_HOST=""
  BUILD_SSH_PORT="22"
  [[ -n "${PACKER_SSH_HOSTNAME:-}" ]] || return 0

  local port="${PACKER_SSH_LOCAL_PORT:-2222}"
  cloudflared access tcp --hostname "$PACKER_SSH_HOSTNAME" --url "127.0.0.1:${port}" \
    --loglevel warn >"${TMPDIR:-/tmp}/cloudflared-ssh.log" 2>&1 &
  SSH_TUNNEL_PID=$!
  for _ in $(seq 1 30); do
    if (exec 3<>"/dev/tcp/127.0.0.1/${port}") 2>/dev/null; then
      BUILD_SSH_HOST="127.0.0.1"
      BUILD_SSH_PORT="$port"
      return 0
    fi
    sleep 1
  done
  echo "cloudflared tunnel to ${PACKER_SSH_HOSTNAME} failed" >&2
  cat "${TMPDIR:-/tmp}/cloudflared-ssh.log" >&2
  return 1
}

ssh_tunnel_stop() {
  if [[ -n "${SSH_TUNNEL_PID:-}" ]]; then
    kill "$SSH_TUNNEL_PID" 2>/dev/null || true
    wait "$SSH_TUNNEL_PID" 2>/dev/null || true
  fi
}
