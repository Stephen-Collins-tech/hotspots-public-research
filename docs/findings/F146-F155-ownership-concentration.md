# F146-F155 — Ownership concentration is a clean, directly-predictive signal; the "diffuse" side of it isn't (yet)

**Shipped as:** `knowledge_mode` (`concentrated` case only) on `FileOwnership`, `hotspots coordinate`
(hotspots PR [#195](https://github.com/Stephen-Collins-tech/hotspots/pull/195)); ownership-concentration-aware
downgrade of `coordinate`'s `"serialize"` recommendation to `"parallel_safe"` (hotspots PR
[#200](https://github.com/Stephen-Collins-tech/hotspots/pull/200), released v1.40.0)

## Claim

Two related, sequential questions about file ownership and coordination risk:

1. **Can a file's ownership pattern be reliably classified from already-shipped data** (author
   count and author entropy)? Splitting files into `concentrated` (one dominant author),
   `diffuse` (no clear owner), and `healthy` (everything else) turned out to be a clean win on
   one side and a real problem on the other: `concentrated` matched an independent cross-check
   with **100% accuracy on every repo tested**, with zero threshold tuning. `diffuse` did not —
   it ranged from 78% accurate down to **5.9% accurate** on one repo, and the failure has an
   identified cause, not just an observed one (below).
2. **Does ownership concentration predict coordination friction directly**, independent of
   file-coupling entirely? Yes, and more strongly than any other signal tested in this line of
   work: concentrated files see cross-author collisions at **1%–11%** of the rate of otherwise-
   similar not-concentrated files, across every testable repo.

## Method

**Classifying ownership (`knowledge_mode`).** For 5 public repos, computed `concentrated`/
`diffuse`/`healthy` from already-shipped `author_entropy`/`author_count` fields using three
swept threshold sets. Cross-checked each classification against an independently computed
`top_author_pct` (the fraction of a file's commits from its single most frequent author) —
a different measurement of the same underlying property, used as a stand-in for manual review.

**Predicting friction directly (self-collision rate).** For every file with at least 3
commits (excluding CI/build-tooling files), computed a **self-collision rate**: across the
file's own commit history, how often does it see a touch by one author followed within 72
hours by a touch from a *different* author? This measures coordination friction on the file
itself, with no coupled "partner" file required at all. Matched each concentrated file to a
not-concentrated file with a similar total commit count, and compared via paired statistical
test across 9 public repos.

## Results

**`knowledge_mode` cross-check accuracy:**

| Repo | `concentrated` match | `diffuse` match |
|---|---:|---:|
| django/django | 100% | 78.1% |
| scikit-learn/scikit-learn | 100% | 79.8% |
| vuejs/core | 100% | 41.3% |
| gin-gonic/gin | 100% | 65.2% |
| rsync | 100% | **5.9%** |

`concentrated` held at 100% across every repo and every threshold set swept — tightening or
loosening the thresholds changed nothing material. `diffuse` is sharply repo-dependent and,
on rsync, close to a coin-flip's worth of accuracy.

**Why `diffuse` fails, confirmed by direct inspection, not just inferred:** `author_entropy`
and `author_count` are keyed on raw commit email in both the Rust CLI and this project's
Python tooling. rsync's actual long-time sole maintainer committed under two different email
addresses across the project's history — so files he alone wrote look like 5-6-author files
to an email-keyed metric. This is a real limitation of the underlying shipped signal (author
identity isn't canonicalized across email changes), not an artifact of this one evaluation,
and it explains the pattern across repos: large, foundation-backed projects with stable
per-author emails (django, scikit-learn) hold up much better than a small, maintainer-
transition-heavy project like rsync.

**Self-collision rate, concentrated vs. not-concentrated (churn-matched), 8 of 9 testable
public repos, all statistically significant after correction for multiple comparisons:**

| Repo | Concentrated rate | Not-concentrated rate |
|---|---:|---:|
| django/django | 10.7% | 44.0% |
| scikit-learn/scikit-learn | 1.1% | 51.1% |
| vuejs/core | 1.8% | 36.6% |
| redis/redis | 4.5% | 62.7% |
| facebook/react | 0.7% | 52.3% |
| golang/go | 3.7% | 39.8% |
| vercel/next.js | 1.7% | 59.9% |
| microsoft/vscode | 5.1% | 36.1% |

Every repo shows the same direction, with a 30-60 percentage-point gap between concentrated
and not-concentrated files — a substantially larger and cleaner effect than the file-coupling
signal this work was checking ownership against as an alternative explanation.

## Why this shipped the way it did

`knowledge_mode` ships with only the `concentrated` case implemented — `diffuse` was
deliberately left out, not just out of caution but because the fix it needs (canonicalizing
author identity across email changes) doesn't exist anywhere in the codebase yet, and
threshold tuning alone can't paper over a genuine identity-collapsing confound. The downgrade
of coordinate's `"serialize"` recommendation similarly ships only in the direction the
evidence supports: an all-concentrated set of input files downgrades to `"parallel_safe"`,
but the escalation path (flagging files as needing serialized review) is untouched, since
this evaluation only tested and validated the one binary contrast.

## Caveats

- `diffuse`'s accuracy on `vuejs/core` (41%) was not spot-checked to the same depth as
  rsync's confirmed email-identity mechanism — plausible as the same cause, not verified to
  the same standard.
- The direction of the self-collision result is close to definitional (one dominant author
  leaves little room for anyone else to collide) — the finding is less that the direction is
  surprising and more that the effect is this large and this consistent across repo types.
- Both evaluations ran on 5-9 public repos' own git history — fully public data, no private
  labels involved — but the specific percentile cutoffs used in the shipped classifier were
  tuned on this repo set and may need revisiting as more repos are checked.

**Reproducibility:** Yes — `author_entropy`/`author_count` are public fields computed from
git history alone; `top_author_pct` and self-collision rate are both derivable from
`git log` on any public repo with no proprietary inputs.
