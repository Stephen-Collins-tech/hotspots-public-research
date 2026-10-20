#!/usr/bin/env bash
# Dispatches to scripts/findings/<FINDING_ID>.sh <REPO_PATH>.
set -euo pipefail

FINDING_ID="${1:-}"
REPO_PATH="${2:-}"

if [[ -z "$FINDING_ID" || -z "$REPO_PATH" ]]; then
  echo "Usage: $0 <finding-id> <path-to-a-git-repo>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/findings/${FINDING_ID}.sh"

if [[ ! -f "$TARGET" ]]; then
  echo "No reproduction script for '$FINDING_ID'." >&2
  echo "See docs/findings/README.md for which findings are reproducible." >&2
  exit 1
fi

if ! command -v hotspots >/dev/null 2>&1; then
  echo "hotspots CLI not found on PATH. Install it first:" >&2
  echo "  curl -fsSL https://raw.githubusercontent.com/Stephen-Collins-tech/hotspots/main/install.sh | sh" >&2
  exit 1
fi

exec "$TARGET" "$REPO_PATH"
