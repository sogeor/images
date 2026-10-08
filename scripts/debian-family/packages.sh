#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

APT_OPTS=(
  -y
  -o DPkg::Lock::Timeout=600
  -o Acquire::Retries=5
  -o Dpkg::Options::=--force-confdef
  -o Dpkg::Options::=--force-confold
)

apt-get "${APT_OPTS[@]}" update
apt-get "${APT_OPTS[@]}" install --no-install-recommends \
  qemu-guest-agent cloud-init cloud-guest-utils \
  chrony curl ca-certificates gnupg python3 \
  nftables auditd openscap-scanner

to_purge=()
for pkg in snapd ubuntu-pro-client ubuntu-advantage-tools popularity-contest; do
  if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'; then
    to_purge+=("$pkg")
  fi
done
if ((${#to_purge[@]})); then
  apt-get "${APT_OPTS[@]}" purge "${to_purge[@]}"
fi

cat >/etc/apt/preferences.d/no-snapd.pref <<'PREF'
Package: snapd
Pin: release *
Pin-Priority: -10
PREF
rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd /root/snap

if [[ -f /etc/default/motd-news ]]; then
  sed -i 's/^ENABLED=.*/ENABLED=0/' /etc/default/motd-news
fi
systemctl disable --now motd-news.timer 2>/dev/null || true

systemctl enable qemu-guest-agent nftables auditd chrony

apt-get "${APT_OPTS[@]}" autoremove --purge
apt-get clean

sed -i 's/[[:space:]]nullok\b//' /usr/share/pam-configs/unix
DEBIAN_FRONTEND=noninteractive pam-auth-update --package
