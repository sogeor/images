#!/usr/bin/env bash
set -euo pipefail

TRIVY_VERSION="0.75.0"
TRIVY_SHA256="c6e65abddb348e25f10549df887045629cf28cc72453cd1c63acb717316b3f3f"
REPORT_DIR="/tmp/reports"
WORK="/tmp/trivy"
: "${REPORT_PREFIX:?}"

mkdir -p "$REPORT_DIR" "$WORK"
curl -fsSL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" \
  -o "$WORK/trivy.tar.gz"
echo "${TRIVY_SHA256}  $WORK/trivy.tar.gz" | sha256sum -c -
tar -xzf "$WORK/trivy.tar.gz" -C "$WORK" trivy

skip=(--skip-dirs /proc --skip-dirs /sys --skip-dirs /dev --skip-dirs /tmp)
"$WORK/trivy" rootfs --cache-dir "$WORK/cache" --scanners vuln "${skip[@]}" \
  --format json --output "${REPORT_DIR}/${REPORT_PREFIX}-trivy.json" /
"$WORK/trivy" rootfs --cache-dir "$WORK/cache" "${skip[@]}" \
  --format cyclonedx --output "${REPORT_DIR}/${REPORT_PREFIX}-sbom.cdx.json" /

rm -rf "$WORK"
