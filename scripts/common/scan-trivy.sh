#!/usr/bin/env bash
set -euo pipefail

REPORT_DIR="/tmp/reports"
: "${REPORT_PREFIX:?}"

# trivy: tools/packer.sh
mkdir -p "$REPORT_DIR"
paths=(etc/os-release etc/lsb-release etc/debian_version usr/lib/os-release var/lib/dpkg/status var/lib/dpkg/info)
for p in usr/lib/python3/dist-packages usr/local/lib; do
  [[ -e "/$p" ]] && paths+=("$p")
done
tar -C / --ignore-failed-read -czf "${REPORT_DIR}/${REPORT_PREFIX}-rootfs.tar.gz" "${paths[@]}"

rm -rf /tmp/artifacts
