#!/usr/bin/env bash
# F54's feature was removed from the trained ranker (see docs/findings/F54-*.md).
# This confirms the removal against the public hotspots-core source rather than
# running anything, since there's no live feature left to exercise.
set -euo pipefail
REPO_PATH="${1:?Usage: F54.sh <path-to-a-local-clone-of-hotspots>}"

TRAINER="$REPO_PATH/hotspots-core/src/trainer.rs"
if [[ ! -f "$TRAINER" ]]; then
  echo "Expected to find hotspots-core/src/trainer.rs under $REPO_PATH — point this at a clone of Stephen-Collins-tech/hotspots." >&2
  exit 1
fi

echo "== FEATURE_NAMES (current) =="
sed -n '/pub const FEATURE_NAMES/,/\];/p' "$TRAINER"

echo
echo "== Removal note =="
grep -n "convention_bug_fix_count.*removed\|ratchets the trained ranker" "$TRAINER"
