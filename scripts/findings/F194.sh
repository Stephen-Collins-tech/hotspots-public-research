#!/usr/bin/env bash
# F194: file_risk_score's repo-wide ranking as a candidate filter.
# Ranks every file by file_risk_score at a snapshot commit, takes the top K,
# and checks what fraction of files touched by a fix-shaped commit in the
# following WINDOW_DAYS land inside that top-K set, vs. a random-K floor.
set -euo pipefail
REPO_PATH="${1:?Usage: F194.sh <path-to-a-local-clone> [snapshot-sha] [window-days] [K]}"
SNAPSHOT="${2:-$(git -C "$REPO_PATH" log --before="180 days ago" -1 --format=%H)}"
WINDOW_DAYS="${3:-180}"
# Default K = min(20, top-decile) -- matches the updated 8-repo methodology (see the finding doc):
# a fixed K=20 swallows most of a small repo, so K shrinks for repos under ~200 files unless
# explicitly overridden by the 4th argument.
K_ARG="${4:-}"

if [[ -z "$SNAPSHOT" ]]; then
  echo "Could not find a commit old enough to leave a ${WINDOW_DAYS}-day forward window. Pick one explicitly." >&2
  exit 1
fi

echo "== snapshot: $SNAPSHOT =="
git -C "$REPO_PATH" show -s --format='%cI %s' "$SNAPSHOT"

# --- file_risk_score ranking at the snapshot (same rollup as aggregates.rs: 0.4*max_cc + 0.3*avg_cc + 0.2*log2(fn_count+1)) ---
WORKTREE="$(mktemp -d)"
trap 'git -C "$REPO_PATH" worktree remove --force "$WORKTREE" 2>/dev/null || true' EXIT
git -C "$REPO_PATH" worktree add --detach "$WORKTREE" "$SNAPSHOT" >/dev/null

RANKED_FILES="$(hotspots analyze "$WORKTREE" --mode snapshot --format json --all-functions --skip-touch-metrics --no-persist \
  | jq -r '
      [.functions[] | {file, cc: .metrics.cc}]
      | group_by(.file)
      | map({
          file: .[0].file,
          max_cc: (map(.cc) | max),
          avg_cc: (map(.cc) | add / length),
          fn_count: length
        })
      | map(. + {score: (0.4*.max_cc + 0.3*.avg_cc + 0.2*((.fn_count+1) | log/(2|log)))})
      | sort_by(-.score)
      | .[].file
    ')"

N_FILES="$(echo "$RANKED_FILES" | wc -l | tr -d ' ')"
if [[ -z "$K_ARG" ]]; then
  DECILE_K=$(( (N_FILES + 9) / 10 ))  # ceil(n/10)
  K=$(( DECILE_K < 20 ? DECILE_K : 20 ))
else
  K="$K_ARG"
fi
TOP_K="$(echo "$RANKED_FILES" | head -n "$K")"
K_USED="$(echo "$TOP_K" | wc -l | tr -d ' ')"

echo "== repo-wide file_risk_score ranking: $N_FILES files, taking top $K_USED =="

# --- forward-looking fix label: a two-tier fix-keyword heuristic over commit subjects, matching the
#     tier-1 (Conventional-Commit fix:/hotfix:/revert) + tier-2 (plain-English fix wording) approach used
#     to produce the numbers in docs/findings/F194-risk-score-candidate-recall.md. Tier 2 is lower
#     precision (it'll catch some non-defect commits that merely mention "fix"/"broken"/"handle", and miss
#     some real fixes phrased unusually) -- this is a public approximation of that heuristic, not a
#     byte-for-byte port, so recall@K numbers here will differ somewhat from the doc's figures. ---
UNTIL="$(date -u -d "@$(( $(git -C "$REPO_PATH" show -s --format=%ct "$SNAPSHOT") + WINDOW_DAYS*86400 ))" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
  || date -u -r "$(( $(git -C "$REPO_PATH" show -s --format=%ct "$SNAPSHOT") + WINDOW_DAYS*86400 ))" +%Y-%m-%dT%H:%M:%SZ)"
SINCE="$(git -C "$REPO_PATH" show -s --format=%cI "$SNAPSHOT")"

FIX_KEYWORD_RE='^(fix|hotfix)(\([^)]*\))?!?:|^revert\b|\b(fix(es|ed)?|bugs?|crash(es|ed)?|panic(s|ked)?|regression|broken|incorrect(ly)?|wrong|fail(s|ed|ure)?)\b'
NON_FIX_RE='\b(typos?|docs?|docstrings?|documentation|readme|changelog|lint\w*|clippy|rustfmt|prettier|eslint|formatting)\b'

FIXED_FILES="$(git -C "$REPO_PATH" log --since="$SINCE" --until="$UNTIL" \
    --perl-regexp --grep="$FIX_KEYWORD_RE" -i \
    --name-only --format='%x02%x01%s' \
  | awk -v nonfix="$NON_FIX_RE" '
      BEGIN { RS="\x02" }
      {
        n = split($0, lines, "\n")
        subject = lines[1]
        sub(/^\x01/, "", subject)
        if (subject ~ nonfix) next
        for (i = 2; i <= n; i++) if (lines[i] != "") print lines[i]
      }' \
  | sort -u)"

N_FIXED="$(echo "$FIXED_FILES" | sed '/^$/d' | wc -l | tr -d ' ')"
echo "== fix-shaped commits in the next ${WINDOW_DAYS}d touched $N_FIXED distinct files =="

HITS_IN_TOPK="$(comm -12 <(echo "$TOP_K" | sort -u) <(echo "$FIXED_FILES" | sort -u) | wc -l | tr -d ' ')"

python3 - "$N_FILES" "$K_USED" "$N_FIXED" "$HITS_IN_TOPK" <<'PY'
import sys
n_files, k, n_fixed, hits = (int(x) for x in sys.argv[1:5])
if n_fixed == 0:
    print("No fix-shaped commits found in this window -- try a larger --window-days or an older snapshot.")
    sys.exit(0)
recall_at_k = hits / n_fixed
random_floor = k / n_files
print(f"recall@{k}: {hits}/{n_fixed} = {recall_at_k:.3f}")
print(f"random-K floor (K/n): {k}/{n_files} = {random_floor:.3f}")
if random_floor > 0:
    print(f"ranking vs. random floor: {recall_at_k / random_floor:.2f}x")
PY
