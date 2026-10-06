#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
tools/packer.sh fmt
tools/packer.sh init     <image>
tools/packer.sh validate <image> [--syntax-only]
tools/packer.sh build    <image> [packer build args]
USAGE
  exit 2
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cmd="${1:-}"
[[ -n "$cmd" ]] || usage

if [[ "$cmd" == "fmt" ]]; then
  packer fmt -check -diff -recursive "$repo_root/common" "$repo_root/images"
  exit 0
fi

image="${2:-}"
[[ -n "$image" && -d "$repo_root/images/$image" ]] || usage
shift 2

build_dir="$repo_root/.build/$image"
rm -rf "$build_dir"
mkdir -p "$build_dir"
for f in "$repo_root"/common/*.pkr.hcl; do
  cp "$f" "$build_dir/common-$(basename "$f")"
done
cp -R "$repo_root/images/$image/." "$build_dir/"

var_files=()
if [[ -f "$build_dir/$image.pkrvars.hcl" ]]; then
  var_files=(-var-file "$build_dir/$image.pkrvars.hcl")
fi

export PKR_VAR_repo_root="$repo_root"
export PKR_VAR_git_sha="${PKR_VAR_git_sha:-$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || echo local)}"

case "$cmd" in
  init)
    packer init "$build_dir"
    ;;
  validate)
    if [[ "${1:-}" == "--syntax-only" ]]; then
      packer validate -syntax-only "${var_files[@]}" "$build_dir"
    else
      packer validate "${var_files[@]}" "$build_dir"
    fi
    ;;
  build)
    : "${PKR_VAR_build_version:?}"
    if [[ "${GITHUB_ACTIONS:-}" == "true" && -z "${PACKER_SSH_HOSTNAME:-}" ]]; then
      echo "PACKER_SSH_HOSTNAME is not set" >&2
      exit 1
    fi
    # shellcheck source=tools/ssh-tunnel.sh
    . "$repo_root/tools/ssh-tunnel.sh"
    key_dir="$(mktemp -d)"
    trap 'ssh_tunnel_stop; rm -rf "$key_dir"' EXIT
    ssh_tunnel_start
    if [[ -n "$BUILD_SSH_HOST" ]]; then
      export PKR_VAR_ssh_host="$BUILD_SSH_HOST" PKR_VAR_ssh_port="$BUILD_SSH_PORT"
    fi
    if [[ "$image" == *-base && -z "${PKR_VAR_ssh_public_key:-}" ]]; then
      ssh-keygen -q -t ed25519 -N '' -C "packer-${PKR_VAR_build_version}" -f "$key_dir/id_ed25519"
      PKR_VAR_ssh_public_key="$(cat "$key_dir/id_ed25519.pub")"
      export PKR_VAR_ssh_public_key
      export PKR_VAR_ssh_private_key_file="$key_dir/id_ed25519"
    fi
    mkdir -p "$repo_root/reports" "$repo_root/manifest"
    packer init "$build_dir"
    packer build -color=false "${var_files[@]}" "$@" "$build_dir"
    ;;
  *)
    usage
    ;;
esac
