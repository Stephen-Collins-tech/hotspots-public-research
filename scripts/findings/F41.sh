#!/usr/bin/env bash
set -euo pipefail
REPO_PATH="${1:?Usage: F41.sh <path-to-a-local-clone-of-redis-or-any-C-repo>}"

echo "== hotspots analyze: C-language function snapshots (first 5) =="
hotspots analyze "$REPO_PATH" --mode snapshot --format json --all-functions --no-persist \
  | jq '[.functions[] | select(.language == "C")][0:5]'
