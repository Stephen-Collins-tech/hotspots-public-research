# F98 — Low-label-density cold-start screener

**Shipped as:** IsolationForest anomaly-score cold-start strategy, `hotspots analyze --cold-start`

## Claim

On repos with little or no bug-fix-commit label history (a "cold start" — can't train a
ranker, can't validate against labels), an IsolationForest anomaly score over structural
features beats the plain formula by a wide margin on 4 validated repos (`golang/go`,
`apache/spark`, `envoyproxy/envoy`, and hotspots' own codebase), P@10 >= 0.90.

## What shipped

`--cold-start` on `hotspots analyze` selects a Gini-gated strategy (formula /
IsolationForest anomaly / uniform prior) instead of the trained ranker, for repos with no
fix-commit label history yet. It reads no label data — explicit opt-in, never an automatic
fallback when `hotspots train` fails its label threshold.

## Reproducibility: no

You can run `--cold-start` yourself (it requires nothing private — that's the point of the
feature), but the original P@10 >= 0.90 claim was measured against those four repos'
*actual* bug-fix history as ground truth, pulled from the private research corpus at a
specific point in time. Re-running `--cold-start` on a fresh clone of `golang/go` today
will produce a ranking, but confirming it still beats the formula requires building your
own labeled holdout for that repo — exactly the kind of labeling-methodology work that has
its own findings (F31 and its sequence) about how easy it is to get wrong.
