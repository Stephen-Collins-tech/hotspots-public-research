#!/usr/bin/env bash
set -euo pipefail
REPO_PATH="${1:?Usage: F37-F39.sh <path-to-a-git-repo>}"

echo "== hotspots analyze: top 10 functions by directed_coupling =="
hotspots analyze "$REPO_PATH" --mode snapshot --format json --all-functions --no-persist \
  | jq '[.functions[] | select(.directed_coupling != null)] | sort_by(-.directed_coupling)[0:10]'
