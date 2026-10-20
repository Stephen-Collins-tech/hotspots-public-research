#!/usr/bin/env bash
set -euo pipefail
REPO_PATH="${1:?Usage: F55-explain.sh <path-to-a-git-repo>}"

echo "== hotspots analyze --explain (top 10) =="
hotspots analyze "$REPO_PATH" --mode snapshot --explain --top 10
