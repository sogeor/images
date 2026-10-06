#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

APT_OPTS=(
  -y
  -o DPkg::Lock::Timeout=600
  -o Dpkg::Options::=--force-confdef
  -o Dpkg::Options::=--force-confold
)

apt-get "${APT_OPTS[@]}" update
apt-get "${APT_OPTS[@]}" dist-upgrade
apt-get "${APT_OPTS[@]}" autoremove --purge
apt-get clean
