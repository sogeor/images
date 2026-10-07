#!/usr/bin/env bash
set -euo pipefail

GOSS_VERSION="v0.4.9"
GOSS_SHA256="87dd36cfa1b8b50554e6e2ca29168272e26755b19ba5438341f7c66b36decc19"
TRIVY_VERSION="0.75.0"
TRIVY_SHA256="c6e65abddb348e25f10549df887045629cf28cc72453cd1c63acb717316b3f3f"
SSG_VERSION="0.1.82"
SSG_SHA512="1caea418f0a5aaef7025e1655ca45a80942ea87ee832b943644ba6f9991b14a6ac5b35dddcd04b754e1fc8fbdee7b7f394507d24b123e821cca0354dc4e03cfd"

cache="${1:?usage: $0 <cache-dir>}"
art="$cache/artifacts"
mkdir -p "$art" "$cache/bin"

fetch() {
  local url="$1" file="$2"
  [[ -s "$file" ]] || curl -fsSL --retry 5 --retry-all-errors -o "$file" "$url"
}

fetch "https://github.com/goss-org/goss/releases/download/${GOSS_VERSION}/goss-linux-amd64" "$art/goss"
fetch "https://github.com/ComplianceAsCode/content/releases/download/v${SSG_VERSION}/scap-security-guide-${SSG_VERSION}.zip" "$art/ssg.zip"
fetch "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" "$cache/trivy.tar.gz"

printf '%s  goss\n' "$GOSS_SHA256" >"$art/SHA256SUMS"
printf '%s  ssg.zip\n' "$SSG_SHA512" >"$art/SHA512SUMS"
echo "SSG_VERSION=${SSG_VERSION}" >"$art/versions.env"
(cd "$art" && sha256sum -c SHA256SUMS && sha512sum -c SHA512SUMS)
echo "${TRIVY_SHA256}  $cache/trivy.tar.gz" | sha256sum -c -

if [[ "$(uname -s)" == "Linux" && ! -x "$cache/bin/trivy" ]]; then
  tar -xzf "$cache/trivy.tar.gz" -C "$cache/bin" trivy
fi
