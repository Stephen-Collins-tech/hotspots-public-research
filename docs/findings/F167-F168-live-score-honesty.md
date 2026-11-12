# F167-F168 — Two terms removed from the live risk score because they weren't earning their weight

**Shipped as:** `depth_score` zeroed out of `compute_activity_risk` (`hotspots-core/src/scoring.rs`);
`convention_bug_fix_count` dropped from the trained ranker's feature set, `model_version` bumped 5→6
**Commits:** `be7d5f2` (depth_score), `43dd62c` (ratchet-wiring fix), both on `main`

## Claim

Two components of the live scoring formula were tested directly against measurable ranking
quality and found not to be worth keeping, for two different reasons — one a dead weight
with no signal, the other a hidden correctness bug:

- **`depth_score`** (a call-graph-depth term, `min(dependency_depth/3, 5.0) * weight`) is
  non-null for only 0.5%–20% of functions across 6 tested repos, has a *negative* average
  Shapley contribution to the activity-risk formula's rank correlation, and its leave-one-out
  effect isn't even sign-consistent across repos. Dropping it is statistically non-inferior
  to keeping it. This extends an earlier, higher-powered result (fan-in and strongly-connected-
  component terms were already zeroed for the same reason) to a third structurally sparse
  term — the pattern looks systemic, not a one-off.
- **`convention_bug_fix_count`** (a feature counting a function's history of "fix:"-style
  commits) turned out to **ratchet monotonically** in the trained ranker: in both model
  classes the CLI actually trains (RandomForest and Ridge), increasing this feature's value
  essentially never decreases the predicted score. For a feature meant to flag risk going
  forward, that's a correctness defect — a function that was once touched by a fix commit
  stays flagged as risk-elevated forever, regardless of how the rest of its profile changes.
  Removed from the feature set entirely rather than reweighted.

## Method

**`depth_score`:** Built a 4-term reconstruction of the current production `activity_risk`
formula (`lrs + touch + recency + depth`) on 6 public repos spanning Java, Python, TypeScript,
and Go. One repo was excluded by a pre-registered "outcome-blind" gate (positive rate outside
[0.05, 0.95]) before any `depth_score` number was computed, leaving 5 gate-passing repos.
For each repo, computed each term's Shapley share of the formula's overall rank correlation
and a leave-one-out effect (does removing the term raise or lower rank correlation), then
ran a bootstrap non-inferiority test (pre-registered margins) comparing the formula with and
without the term.

**`convention_bug_fix_count`:** Built a one-time diagnostic that, for 5 public repos already
trained with `hotspots train`, swept each feature across an 8-point grid built from that
repo's own observed values (not extrapolated) while holding all other features fixed, and
scored each point with the trained model. This directly measures whether the trained model's
output is monotonic in the feature — the practical definition of a ratchet.

## Results

**`depth_score` sparsity and contribution, across the 5 gate-passing repos:**

| Repo | Language | `dependency_depth` non-null | Verdict |
|---|---|---:|---|
| google/guava | Java | 0.53% | inert |
| django/django | Python | 2.28% | near-inert |
| facebook/react | TS/JS | 19.73% | low coverage |
| pocketbase/pocketbase | Go | 3.63% | near-inert |
| n8n-io/n8n | TypeScript | 16.92% | low coverage |

Mean Shapley share of rank correlation: **−2.1%** (negative — a net drag, not a contributor).
Leave-one-out effect was sign-inconsistent across repos (helped in 2 of 5, hurt in 3 of 5),
well short of the pre-registered "helps" bar. The root cause traces to the call-graph walk
itself: a single breadth-first search runs from a small, name-heuristic set of "entry points"
(functions named `main`/`start`/`run`, or matching patterns like `handler`/`controller`), so
most functions in most repos are simply unreachable from that root set and get `None`
("unreached"), not a real zero depth. This is a property of the algorithm, expected to recur
on any repo, not a quirk of these 5.

**`convention_bug_fix_count` ratchet, across 5 repos (2 RandomForest, 3 Ridge):**

| Repo | Model class | Monotonic non-decrease |
|---|---|---:|
| curl/curl | RandomForest | 100% (300/300 sweep points) |
| git/git | RandomForest | 99.3% (298/300) |
| redis/redis | Ridge | 100% (coefficient +0.169, strictly positive) |
| django/django | Ridge | 100% (coefficient +0.147) |
| microsoft/vscode | Ridge | 100% (coefficient +0.172) |

Both model classes clear the pre-registered ">90% non-decreasing" bar for "this feature
ratchets." Ridge's positive coefficient guarantees non-decrease by construction, given the
trainer's linear-combination-then-clamp scoring; RandomForest reaches the same conclusion
empirically via the sweep. A separate feature tested in the same pass, `total_churn`,
carried almost no training signal at all (a different, unrelated wiring gap, not a ratchet)
and is not affected by this change.

## Why this is a public-facing honesty finding, not just a changelog line

Both removals follow a pattern worth stating plainly: the live score is periodically
re-measured against real ranking outcomes, and terms that don't pull their weight get cut,
even after they shipped. `depth_score` joins two earlier terms (fan-in, strongly-connected
components) removed for the identical reason — a structurally sparse call-graph signal with
no measurable ranking contribution. `convention_bug_fix_count`'s removal is different in
kind: it wasn't just weak, it was quietly wrong in a way that would make the trained ranker
*more* confident about old, possibly-fixed problems over time, never less.

## Caveats

- The `depth_score` result is lower-powered than its own precedent (n=5 repos vs. 17 for
  the fan-in/SCC removal) — read it as directional confirmation of the same pattern, not an
  independently dispositive result at the same confidence level.
- Both evaluations necessarily measure against this project's own labeled fix-commit data,
  which isn't published. The *mechanism* (sparse call-graph reachability; ratchet-by-sweep)
  is fully reproducible on any public repo; the specific rank-correlation numbers above are
  not independently rerunnable without that labeling pipeline.

**Reproducibility:** Partial — the call-graph sparsity and the monotonicity sweep can both
be reproduced directly against `hotspots-core`'s source and any public repo's git history;
the rank-correlation/Shapley numbers depend on this project's private fix-commit labeling.
