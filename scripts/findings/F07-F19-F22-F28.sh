#!/usr/bin/env bash
set -euo pipefail
REPO_PATH="${1:?Usage: F07-F19-F22-F28.sh <path-to-a-git-repo>}"

echo "== hotspots train --eval (trains a RandomForest ranker on this repo, then prints P@K) =="
hotspots train "$REPO_PATH" --eval --yes
