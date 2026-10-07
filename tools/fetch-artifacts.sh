#!/usr/bin/env bash
set -euo pipefail

GOSS_VERSION="v0.4.9"
GOSS_SHA256="87dd36cfa1b8b50554e6e2ca29168272e26755b19ba5438341f7c66b36decc19"
TRIVY_VERSION="0.75.0"
TRIVY_SHA256="c6e65abddb348e25f10549df887045629cf28cc72453cd1c63acb717316b3f3f"
SSG_VERSION="0.1.82"
SSG_SHA512="1caea418f0a5aaef7025e1655ca45a80942ea87ee832b943644ba6f9991b14a6ac5b35dddcd04b754e1fc8fbdee7b7f394507d24b123e821cca0354dc4e03cfd"

out="${1:?usage: $0 <dir>}"
mkdir -p "$out"
cd "$out"

fetch() {
  local url="$1" file="$2"
  [[ -s "$file" ]] || curl -fsSL --retry 5 --retry-all-errors -o "$file" "$url"
}

fetch "https://github.com/goss-org/goss/releases/download/${GOSS_VERSION}/goss-linux-amd64" goss
fetch "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" trivy.tar.gz
fetch "https://github.com/ComplianceAsCode/content/releases/download/v${SSG_VERSION}/scap-security-guide-${SSG_VERSION}.zip" ssg.zip

printf '%s  goss\n%s  trivy.tar.gz\n' "$GOSS_SHA256" "$TRIVY_SHA256" >SHA256SUMS
printf '%s  ssg.zip\n' "$SSG_SHA512" >SHA512SUMS
sha256sum -c SHA256SUMS
sha512sum -c SHA512SUMS
echo "SSG_VERSION=${SSG_VERSION}" >versions.env

if [[ "$(uname -s)" == "Linux" && ! -x ../bin/trivy ]]; then
  mkdir -p ../bin
  tar -xzf trivy.tar.gz -C ../bin trivy
fi
