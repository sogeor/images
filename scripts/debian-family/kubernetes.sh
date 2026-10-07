#!/usr/bin/env bash
set -euo pipefail

: "${K8S_VERSION:?}"
: "${K8S_PACKAGE_REVISION:?}"

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
APT_OPTS=(
  -y
  -o DPkg::Lock::Timeout=600
  -o Acquire::Retries=5
  -o Dpkg::Options::=--force-confdef
  -o Dpkg::Options::=--force-confold
)

PKG_VERSION="${K8S_VERSION}-${K8S_PACKAGE_REVISION}"

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
apt-get "${APT_OPTS[@]}" install --no-install-recommends containerd
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

DEBS="/tmp/k8s-debs"
(cd "$DEBS" && sha256sum -c SHA256SUMS)
for p in kubelet kubeadm kubectl; do
  [[ "$(dpkg-deb -f "$DEBS"/${p}_*.deb Version)" == "$PKG_VERSION" ]]
done
apt-get "${APT_OPTS[@]}" install --no-install-recommends "$DEBS"/*.deb
rm -rf "$DEBS"
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

kubeadm config images pull \
  --kubernetes-version "v${K8S_VERSION}" \
  --cri-socket unix:///run/containerd/containerd.sock

apt-get clean
