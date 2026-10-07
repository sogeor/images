#!/usr/bin/env bash
set -euo pipefail

GOSS_VERSION="v0.4.9"
GOSS_SHA256="87dd36cfa1b8b50554e6e2ca29168272e26755b19ba5438341f7c66b36decc19"
REPORT_DIR="/tmp/reports"
: "${REPORT_PREFIX:?}"

mkdir -p "$REPORT_DIR"
curl -fsSL --retry 5 --retry-all-errors -o /tmp/goss \
  "https://github.com/goss-org/goss/releases/download/${GOSS_VERSION}/goss-linux-amd64"
echo "${GOSS_SHA256}  /tmp/goss" | sha256sum -c -
chmod +x /tmp/goss

vars_json="{"
sep=""
while IFS='=' read -r name value; do
  vars_json+="${sep}\"${name#GOSS_VARS_}\":\"${value}\""
  sep=","
done < <(env | grep '^GOSS_VARS_' || true)
vars_json+="}"

status=0
/tmp/goss -g /tmp/goss.yaml --vars-inline "$vars_json" validate --format junit \
  >"${REPORT_DIR}/${REPORT_PREFIX}-goss.xml" || status=$?
/tmp/goss -g /tmp/goss.yaml --vars-inline "$vars_json" validate --format documentation || true

rm -f /tmp/goss /tmp/goss.yaml
exit "$status"
