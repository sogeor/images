#!/usr/bin/env bash
set -euo pipefail

ART="/tmp/artifacts"
REPORT_DIR="/tmp/reports"
: "${REPORT_PREFIX:?}"

mkdir -p "$REPORT_DIR"
(cd "$ART" && sha256sum -c --ignore-missing SHA256SUMS)
install -m 0755 "$ART/goss" /tmp/goss

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
