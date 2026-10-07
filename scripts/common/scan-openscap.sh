#!/usr/bin/env bash
set -euo pipefail

SSG_VERSION="0.1.82"
SSG_SHA512="1caea418f0a5aaef7025e1655ca45a80942ea87ee832b943644ba6f9991b14a6ac5b35dddcd04b754e1fc8fbdee7b7f394507d24b123e821cca0354dc4e03cfd"
BASE_PROFILE="xccdf_org.ssgproject.content_profile_cis_level1_server"
TAILORED_PROFILE="xccdf_com.sogeor_profile_cis_level1_server_image"
REPORT_DIR="/tmp/reports"
WORK="/tmp/ssg"
: "${REPORT_PREFIX:?}"

# shellcheck source=/dev/null
. /etc/os-release
product="ubuntu${VERSION_ID//./}"
out="${REPORT_DIR}/${REPORT_PREFIX}-openscap"

mkdir -p "$REPORT_DIR" "$WORK"
curl -fsSL --retry 5 --retry-all-errors -o "$WORK/ssg.zip" \
  "https://github.com/ComplianceAsCode/content/releases/download/v${SSG_VERSION}/scap-security-guide-${SSG_VERSION}.zip"
echo "${SSG_SHA512}  $WORK/ssg.zip" | sha512sum -c -
python3 -c "import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$WORK/ssg.zip" "$WORK"
ds="$WORK/scap-security-guide-${SSG_VERSION}/ssg-${product}-ds.xml"

[[ -f "$ds" ]] || { echo "no datastream for ${product}" >&2; exit 1; }
grep -q "$BASE_PROFILE" "$ds" || { echo "no ${BASE_PROFILE} for ${product}" >&2; exit 1; }

profile="$BASE_PROFILE"
tailoring=()
tailoring_file="/tmp/openscap/tailoring-${product}.xml"
if [[ -f "$tailoring_file" ]]; then
  profile="$TAILORED_PROFILE"
  tailoring=(--tailoring-file "$tailoring_file")
fi

rc=0
oscap xccdf eval \
  --profile "$profile" "${tailoring[@]}" \
  --results-arf "${out}-arf.xml" \
  --results "${out}-results.xml" \
  --report "${out}.html" \
  "$ds" || rc=$?
# 2: failed rules
[[ $rc -eq 0 || $rc -eq 2 ]] || exit "$rc"

result_id="$(grep -o 'TestResult id="[^"]*"' "${out}-results.xml" | head -n 1 | cut -d'"' -f2)"
oscap xccdf generate fix --fix-type ansible --result-id "$result_id" "${tailoring[@]}" \
  --output "${out}-remediation.yml" "${out}-results.xml" || true

python3 - "${out}-results.xml" "${out}-summary.json" <<'PY'
import collections, json, sys
import xml.etree.ElementTree as ET

ns = {"x": "http://checklists.nist.gov/xccdf/1.2"}
order = ("high", "medium", "low", "unknown")
root = ET.parse(sys.argv[1]).getroot()
counts = collections.Counter()
failed = []
for rr in root.iter("{%s}rule-result" % ns["x"]):
    result = rr.find("x:result", ns).text
    counts[result] += 1
    if result == "fail":
        failed.append({
            "rule": rr.get("idref").rsplit("content_rule_", 1)[-1],
            "severity": rr.get("severity") or "unknown",
        })
total = counts["pass"] + counts["fail"]
summary = {
    "counts": dict(counts),
    "score_pct": round(100 * counts["pass"] / total, 1) if total else None,
    "failed": sorted(failed, key=lambda f: (order.index(f["severity"]), f["rule"])),
}
with open(sys.argv[2], "w") as fh:
    json.dump(summary, fh, indent=2)
print(f"OpenSCAP: pass={counts['pass']} fail={counts['fail']} "
      f"notapplicable={counts['notapplicable']} score={summary['score_pct']}%")
PY

rm -rf "$WORK" /tmp/openscap
