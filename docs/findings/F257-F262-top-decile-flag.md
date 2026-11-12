# F257-F262 — `file_risk_score`'s top decile within a diff is a real signal, the raw score is not

**Shipped as:** `file_risk_score`/`file_risk_diff_percentile`/`file_risk_top_decile` on
`hotspots diff`'s per-file output, `hotspots-core/src/aggregates.rs` |
**PR:** [hotspots#353](https://github.com/Stephen-Collins-tech/hotspots/pull/353)

## Claim

`file_risk_score` (the existing complexity-based composite — `max_cc`, `avg_cc`, and
function-count, already live in `hotspots analyze`) does not calibrate as an absolute
probability: its raw value doesn't map cleanly onto "this file's chance of needing a
later fix" (pooled correlation ρ=0.515 against a pre-registered ρ≥0.8 bar — a clear
fail). But a narrower, better-evidenced claim held up everywhere it was tested: **a
file in the top 10% of `file_risk_score` among only the other files changed in the same
diff** (not ranked against the whole repo) has a real, meaningfully elevated chance of
later needing a fix. The effect:

- strengthens monotonically as the cutoff tightens (odds ratio 3.56x at top-20% up to
  7.08x at top-5%, on the original pool),
- is not driven by any single formula term (removing `max_cc`, `avg_cc`, or the
  function-count term one at a time each independently weakens the signal — none is
  redundant),
- beats a plain lines-changed baseline head-to-head at every cutoff tested, and
- **replicates on 5 repos never touched during the original discovery work** (pooled
  odds ratio 6.68, same cutoff-robust shape, 3.94x–10.02x across the same cutoff range).

So `hotspots diff` now flags, per file, whether it lands in the top decile of
`file_risk_score` *within that diff* — a relative, diff-scoped signal, not a repo-wide
absolute score.

## Method

Public GitHub repos, fresh clones, no proprietary data. For each repo: mine commits
whose subject/body match a fix-shaped heuristic (Conventional-Commit `fix:`/`revert`
plus common fix wording — the same style of fix-commit heuristic used in
[F194](F194-risk-score-candidate-recall.md)), walk back to each one's precursor commit,
and score every file touched in that precursor diff with `file_risk_score` (the
uncapped, locally recomputed composite). Rank the diff's own changed files by score and
test whether files in the top percentile band have an elevated rate of being touched by
the later fix, against a plain lines-changed baseline as a control.

The original work (25-repo pool) tested four cutoffs — top 20%, 15%, 10%, 5% — against a
pre-registered bar of Fisher's-exact p < 0.001 **and** odds ratio ≥ 3.0, on both the full
instance pool and a subset excluding trivial two-file diffs. A follow-up repeated the
identical test, same bar, on 5 repos chosen specifically because they were outside the
original discovery pool (Rust, Go, TypeScript, Java, and Python projects, for language
spread): `sharkdp/fd`, `pocketbase/pocketbase`, `mikro-orm/mikro-orm`,
`redisson/redisson`, `paperless-ngx/paperless-ngx`.

## Results

**Cutoff sweep, original pool (n=1,513 file-pairs):**

| Cutoff | Flagged fix-rate | Base rate | Odds ratio | p |
|---|---:|---:|---:|---:|
| top 20% | 0.221 | 0.109 | 3.56 | 2.9e-13 |
| top 15% | 0.255 | 0.109 | 4.37 | 1.2e-16 |
| top 10% | 0.303 | 0.109 | 5.57 | 1.5e-20 |
| top 5% | 0.363 | 0.109 | 7.08 | 2.6e-23 |

All four cutoffs clear the bar, strengthening — not weakening — as the cutoff tightens.

**Out-of-sample replication, 5 new repos (n=1,173 file-pairs, 65 mined fix instances):**

| Cutoff | `file_risk_score` odds (p) | Size-baseline odds (p) |
|---|---|---|
| top 20% | 3.94 (5.6e-6) | 1.21 (0.54) |
| top 15% | 5.04 (9.7e-8) | 1.54 (0.17) |
| top 10% | 6.68 (2.5e-9) | 2.35 (8.9e-3) |
| top 5% | 10.02 (1.8e-11) | 4.22 (4.3e-5) |

`file_risk_score` clears the bar at all 4 cutoffs out-of-sample, with the same
monotonically-strengthening shape as the original pool. It also wins the direct
head-to-head comparison against the size baseline at every cutoff. **One honest nuance:**
at the single tightest cutoff (top 5%), the size baseline *also* clears the bar on this
out-of-sample data (odds 4.22, p=4.3e-5) — something it never did in the original pool.
The durable claim is "`file_risk_score` beats size head-to-head at every tested cutoff,
in-pool and out-of-sample" — not "size always fails outright."

Per-repo, out-of-sample: every one of the 5 repos points the same direction (odds
3.81–6.53x individually), though none clears the strict significance bar alone — expected
at these per-repo sample sizes (45–848 file-pairs each, with correspondingly few
top-decile-flagged files per repo), not a contradiction of the pooled result.

## Limits

- The raw `file_risk_score` value still does not calibrate as a probability (ρ=0.515,
  below the pre-registered ρ≥0.8 bar) — this finding is specifically about the relative,
  top-decile-within-a-diff signal, not a rehabilitation of the absolute score. `hotspots
  diff` only exposes the relative flag; it does not present the raw score as a calibrated
  probability anywhere.
- The fix-commit label is a keyword/convention heuristic over commit messages, not ground
  truth — the same caveat as [F194](F194-risk-score-candidate-recall.md) and other
  findings in this repo that use it.
- The out-of-sample repos were chosen for being already available and fast to analyze
  (to avoid a known `hotspots analyze` performance edge case on a few large repos), not
  drawn by a fully random sampling procedure.
- "Top decile within a diff" needs at least 2 scoreable changed files to mean anything —
  a single-file diff has no relative ranking, and files `hotspots` can't score (deleted
  files, unsupported file types — roughly a third of files in a typical diff) are excluded
  from the ranking population rather than treated as low-risk.

## Reproducibility: Yes

```bash
scripts/reproduce.sh F257-F262 ~/code/some-repo
```

The feature is fully public and runnable today: `hotspots diff <base> <head> --format
json` prints `file_risk_score`, `file_risk_diff_percentile`, and `file_risk_top_decile`
on every scoreable changed file. The measurement needs only a public git clone and a
commit-message fix-keyword heuristic (no private corpus, no trained model) — rank a
diff's changed files by `file_risk_score`, compare the top-decile group's later-fix rate
against the rest. `scripts/findings/F257-F262.sh` runs `hotspots diff` between two
recent commits of a repo you point it at and prints the flagged files, so you can see the
diff-relative ranking behave the same way on a repo and commit range of your choosing —
it doesn't try to reproduce the specific odds ratios above, which depend on the fix-label
window and repo mix chosen.
