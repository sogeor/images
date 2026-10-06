#!/usr/bin/env bash
set -euo pipefail

: "${K8S_VERSION:?}"
: "${K8S_PACKAGE_REVISION:?}"

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
APT_OPTS=(
  -y
  -o DPkg::Lock::Timeout=600
  -o Dpkg::Options::=--force-confdef
  -o Dpkg::Options::=--force-confold
)

K8S_MINOR="${K8S_VERSION%.*}"
PKG_VERSION="${K8S_VERSION}-${K8S_PACKAGE_REVISION}"
# expires 2026-12-29
K8S_KEY_FPR="DE15B14486CD377B9E876E1A234654DA9A296436" # gitleaks:allow

cat >/etc/modules-load.d/k8s.conf <<'CONF'
overlay
br_netfilter
CONF
modprobe overlay
modprobe br_netfilter

cat >/etc/sysctl.d/90-k8s.conf <<'CONF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
CONF
sysctl --system >/dev/null

swapoff -a
sed -i -E '/[[:space:]]swap[[:space:]]/d' /etc/fstab
rm -f /swap.img

apt-get "${APT_OPTS[@]}" update
apt-get "${APT_OPTS[@]}" install --no-install-recommends containerd gpg
if ! dpkg --compare-versions "$(dpkg-query -W -f='${Version}' containerd)" ge 2.0; then
  echo "containerd >= 2.0 required" >&2
  exit 1
fi
mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
grep -q 'SystemdCgroup = true' /etc/containerd/config.toml
systemctl enable containerd
systemctl restart containerd

tmp_key="$(mktemp)"
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR}/deb/Release.key" -o "$tmp_key"
actual_fpr="$(gpg --show-keys --with-colons "$tmp_key" | awk -F: '/^fpr:/ {print $10; exit}')"
if [[ "$actual_fpr" != "$K8S_KEY_FPR" ]]; then
  echo "unexpected pkgs.k8s.io key: ${actual_fpr}" >&2
  exit 1
fi
install -d -m 0755 /etc/apt/keyrings
gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg "$tmp_key"
rm -f "$tmp_key"
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR}/deb/ /" \
  >/etc/apt/sources.list.d/kubernetes.list

apt-get "${APT_OPTS[@]}" update
apt-get "${APT_OPTS[@]}" install --no-install-recommends \
  "kubelet=${PKG_VERSION}" "kubeadm=${PKG_VERSION}" "kubectl=${PKG_VERSION}"
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

kubeadm config images pull \
  --kubernetes-version "v${K8S_VERSION}" \
  --cri-socket unix:///run/containerd/containerd.sock

apt-get clean
