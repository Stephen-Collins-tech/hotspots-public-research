#!/usr/bin/env bash
# F206-F208-F209: file_risk_score vs. a 50/50 percentile blend of file_risk_score and true churn.
# Ranks files at a snapshot, takes the top K by (a) static score and (b) the blend, and reports
# recall@K against files touched by fix-shaped commits in the following WINDOW_DAYS.
set -euo pipefail
REPO_PATH="${1:?Usage: F206-F208-F209.sh <path-to-a-local-clone> [snapshot-sha] [window-days] [K]}"
SNAPSHOT="${2:-$(git -C "$REPO_PATH" log --before="360 days ago" -1 --format=%H)}"
WINDOW_DAYS="${3:-180}"
K_ARG="${4:-}"
CHURN_DAYS=180

if [[ -z "$SNAPSHOT" ]]; then
  echo "No commit old enough for a ${CHURN_DAYS}d churn window plus ${WINDOW_DAYS}d forward window. Pick one explicitly." >&2
  exit 1
fi

echo "== snapshot: $SNAPSHOT =="
git -C "$REPO_PATH" show -s --format='%cI %s' "$SNAPSHOT"

SNAP_EPOCH="$(git -C "$REPO_PATH" show -s --format=%ct "$SNAPSHOT")"
iso() { date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ; }
SINCE="$(git -C "$REPO_PATH" show -s --format=%cI "$SNAPSHOT")"
UNTIL="$(iso $(( SNAP_EPOCH + WINDOW_DAYS*86400 )))"
CHURN_SINCE="$(iso $(( SNAP_EPOCH - CHURN_DAYS*86400 )))"

TMP="$(mktemp -d)"
WORKTREE="$TMP/wt"
trap 'git -C "$REPO_PATH" worktree remove --force "$WORKTREE" 2>/dev/null || true; rm -rf "$TMP"' EXIT
git -C "$REPO_PATH" worktree add --detach "$WORKTREE" "$SNAPSHOT" >/dev/null
WORKTREE="$(cd "$WORKTREE" && pwd -P)"  # resolve symlinks so we can strip it from reported paths

# --- static file_risk_score per file (same rollup as aggregates.rs): "score<TAB>file" ---
hotspots analyze "$WORKTREE" --mode snapshot --format json --all-functions --skip-touch-metrics --no-persist \
  | jq -r --arg wt "$WORKTREE/" '
      [.functions[] | {file: (.file | ltrimstr($wt)), cc: .metrics.cc}]
      | group_by(.file)
      | map({file: .[0].file, max_cc: (map(.cc)|max), avg_cc: (map(.cc)|add/length), fn_count: length})
      | .[] | [(0.4*.max_cc + 0.3*.avg_cc + 0.2*((.fn_count+1)|log/(2|log))), .file] | @tsv
    ' > "$TMP/static.tsv"

# --- true churn: lines added + deleted per file in the CHURN_DAYS before the snapshot ---
git -C "$REPO_PATH" log "$SNAPSHOT" --since="$CHURN_SINCE" --until="$SINCE" --numstat --format='%x02' \
  | awk -F'\t' 'NF==3 && $1!="-" && $2!="-" { c[$3]+=$1+$2 } END { for (f in c) print c[f] "\t" f }' > "$TMP/churn.tsv"

# --- forward fix label (public approximation of the F194 heuristic) ---
FIX_KEYWORD_RE='^(fix|hotfix)(\([^)]*\))?!?:|^revert\b|\b(fix(es|ed)?|bugs?|crash(es|ed)?|panic(s|ked)?|regression|broken|incorrect(ly)?|wrong|fail(s|ed|ure)?)\b'
NON_FIX_RE='\b(typos?|docs?|docstrings?|documentation|readme|changelog|lint\w*|clippy|rustfmt|prettier|eslint|formatting)\b'
git -C "$REPO_PATH" log --since="$SINCE" --until="$UNTIL" --perl-regexp --grep="$FIX_KEYWORD_RE" -i \
    --name-only --format='%x02%x01%s' \
  | awk -v nonfix="$NON_FIX_RE" '
      BEGIN { RS="\x02" }
      { n = split($0, lines, "\n"); subject = lines[1]; sub(/^\x01/, "", subject)
        if (subject ~ nonfix) next
        for (i = 2; i <= n; i++) if (lines[i] != "") print lines[i] }' \
  | sort -u > "$TMP/fixed.txt"

python3 - "$TMP" "$K_ARG" <<'PY'
import sys, math
tmp, k_arg = sys.argv[1], sys.argv[2]
static = {}
for line in open(f"{tmp}/static.tsv"):
    s, f = line.rstrip("\n").split("\t", 1); static[f] = float(s)
churn = {}
for line in open(f"{tmp}/churn.tsv"):
    c, f = line.rstrip("\n").split("\t", 1); churn[f] = float(c)
fixed = {l.strip() for l in open(f"{tmp}/fixed.txt") if l.strip()}
files = sorted(static)
n = len(files)
k = int(k_arg) if k_arg else min(20, math.ceil(n / 10))
k = max(1, min(k, n))

def pct(values):
    # descending sort, ties by path; highest value -> 1.0, lowest -> 0.0
    order = sorted(files, key=lambda f: (-values.get(f, 0.0), f))
    d = max(n - 1, 1)
    return {f: 1.0 - i / d for i, f in enumerate(order)}

ps, pc = pct(static), pct(churn)
blend = {f: (ps[f] + pc[f]) / 2 for f in files}
def topk(score):
    return set(sorted(files, key=lambda f: (-score[f], f))[:k])

pos = fixed & set(files)
print(f"== {n} files, K={k}, {len(pos)} files touched by fix-shaped commits in the forward window ==")
if not pos:
    print("No positives in this window -- try a longer window or an older snapshot."); sys.exit(0)
floor = k / n
for name, score in (("static", static), ("blend", blend)):
    hits = len(topk(score) & pos)
    r = hits / len(pos)
    print(f"{name:7s} recall@{k}: {hits}/{len(pos)} = {r:.3f}  ({r/floor:.2f}x random floor {floor:.3f})")
PY
