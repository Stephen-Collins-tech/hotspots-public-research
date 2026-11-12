#!/usr/bin/env bash
set -euo pipefail
REPO_PATH="${1:?Usage: F257-F262.sh <path-to-a-git-repo>}"

HEAD_SHA="$(git -C "$REPO_PATH" rev-parse HEAD)"
BASE_SHA="$(git -C "$REPO_PATH" rev-parse HEAD~5 2>/dev/null || git -C "$REPO_PATH" rev-parse --root HEAD)"

echo "== hotspots diff ${BASE_SHA:0:12} ${HEAD_SHA:0:12} (file_risk_top_decile) =="
(
  cd "$REPO_PATH"
  hotspots diff "$BASE_SHA" "$HEAD_SHA" --format json --auto-analyze
) | python3 -c '
import json, sys
data = json.load(sys.stdin)
delta = data.get("delta") or data
files = (delta.get("aggregates") or {}).get("files") or []
if not files:
    print("No scoreable file-risk data in this diff range.")
    sys.exit(0)
for f in sorted(files, key=lambda f: f.get("file_risk_diff_percentile") or 0, reverse=True):
    pct = f.get("file_risk_diff_percentile")
    score = f.get("file_risk_score")
    if pct is None or score is None:
        continue
    flag = "[top 10%]" if f.get("file_risk_top_decile") else ""
    print(f"{f[\"file\"]:<50} score={score:>6.2f}  percentile={pct:.2f}  {flag}")
'
