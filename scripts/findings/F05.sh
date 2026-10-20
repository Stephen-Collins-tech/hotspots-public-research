#!/usr/bin/env bash
set -euo pipefail
REPO_PATH="${1:?Usage: F05.sh <path-to-a-git-repo>}"

echo "== hotspots analyze --axes (Risk / Coupling / Ownership, top 15 each) =="
hotspots analyze "$REPO_PATH" --axes --top 15
