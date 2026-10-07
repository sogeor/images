#!/usr/bin/env bash
set -euo pipefail

K8S_KEY_FPR="DE15B14486CD377B9E876E1A234654DA9A296436" # gitleaks:allow

out="${1:?usage: $0 <dir> <k8s-version> <package-revision>}"
version="${2:?}"
revision="${3:?}"
minor="${version%.*}"
pkg="${version}-${revision}"

[[ "$(uname -s)" == "Linux" ]] || { echo "skip: not Linux" >&2; exit 0; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/lists/partial" "$work/archives/partial" "$out"

curl -fsSL --retry 5 --retry-all-errors -o "$work/key.asc" "https://pkgs.k8s.io/core:/stable:/v${minor}/deb/Release.key"
fpr="$(gpg --show-keys --with-colons "$work/key.asc" | awk -F: '/^fpr:/ {print $10; exit}')"
[[ "$fpr" == "$K8S_KEY_FPR" ]] || { echo "unexpected pkgs.k8s.io key: ${fpr}" >&2; exit 1; }
gpg --dearmor -o "$work/key.gpg" "$work/key.asc"

echo "deb [signed-by=$work/key.gpg] https://pkgs.k8s.io/core:/stable:/v${minor}/deb/ /" >"$work/sources.list"
apt_opts=(
  -o Dir::Etc::SourceList="$work/sources.list"
  -o Dir::Etc::SourceParts=/dev/null
  -o Dir::State::Lists="$work/lists"
  -o Dir::Cache::Archives="$work/archives"
  -o APT::Architecture=amd64
  -o Acquire::Retries=5
)
apt-get "${apt_opts[@]}" update
cri_tools="$(apt-cache "${apt_opts[@]}" madison cri-tools | awk 'NR==1 {print $3}')"
cni="$(apt-cache "${apt_opts[@]}" madison kubernetes-cni | awk 'NR==1 {print $3}')"

rm -f "$out"/*.deb
(cd "$out" && apt-get "${apt_opts[@]}" download \
  "kubelet=${pkg}" "kubeadm=${pkg}" "kubectl=${pkg}" \
  "cri-tools=${cri_tools}" "kubernetes-cni=${cni}")
(cd "$out" && sha256sum ./*.deb >SHA256SUMS && cat SHA256SUMS)
