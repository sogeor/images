#!/usr/bin/env bash
set -euo pipefail

cache="${1:?usage: $0 <cache-dir> <reports-dir>}"
reports="${2:?usage: $0 <cache-dir> <reports-dir>}"
trivy="$cache/bin/trivy"
[[ -x "$trivy" ]] || { echo "trivy not found, skip" >&2; exit 0; }

for archive in "$reports"/*/*-rootfs.tar.gz; do
  [[ -f "$archive" ]] || continue
  prefix="${archive%-rootfs.tar.gz}"
  root="$(mktemp -d)"
  tar -xzf "$archive" -C "$root"
  opts=(--cache-dir "$cache/trivy" --no-progress --timeout 20m)
  "$trivy" rootfs "${opts[@]}" --format cyclonedx --output "${prefix}-sbom.cdx.json" "$root"
  "$trivy" rootfs "${opts[@]}" --scanners vuln --format json --output "${prefix}-trivy.json" "$root"
  "$trivy" rootfs "${opts[@]}" --scanners vuln --format table --severity HIGH,CRITICAL "$root" || true
  rm -rf "$root" "$archive"
done
