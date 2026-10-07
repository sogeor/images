#!/usr/bin/env bash
set -euo pipefail

ART="/tmp/artifacts"
REPORT_DIR="/tmp/reports"
WORK="/tmp/trivy"
: "${REPORT_PREFIX:?}"

mkdir -p "$REPORT_DIR" "$WORK"
(cd "$ART" && sha256sum -c --ignore-missing SHA256SUMS)
tar -xzf "$ART/trivy.tar.gz" -C "$WORK" trivy

# vuln scan: tools/packer.sh (trivy sbom)
"$WORK/trivy" rootfs --cache-dir "$WORK/cache" --skip-db-update --skip-java-db-update --offline-scan \
  --skip-dirs /proc --skip-dirs /sys --skip-dirs /dev --skip-dirs /tmp \
  --format cyclonedx --output "${REPORT_DIR}/${REPORT_PREFIX}-sbom.cdx.json" /

rm -rf "$WORK" "$ART"
