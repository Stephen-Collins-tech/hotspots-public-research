# F61-F63 — Picking the right model, and a fallback ranker, for repos with little or no history

**Shipped as:** `hotspots train` model-class selection (PR [#114](https://github.com/Stephen-Collins-tech/hotspots/pull/114));
Gini-gated cold-start ranking and a from-scratch `IsolationForest` cold-start screener
(both PR [#123](https://github.com/Stephen-Collins-tech/hotspots/pull/123), released v1.33.0)

## Claim

Three findings about repos where the usual trained-ranker approach either can't run (too
little history) or is likely to pick the wrong model class:

- **A cheap, 3-fold cross-validated check — comparing a shallow gradient-boosted model
  against a plain linear model, before writing any repo-specific training code — correctly
  predicts which model class is worth using**, across every repo in a 13-repo set with known
  ground truth. This avoids wasted effort tuning a complex model class on a repo where a
  simple linear one would do just as well, or under-investing where the complex model class
  would meaningfully help.
- **A single, cheaply-computed property of a repo's commit history — the Gini coefficient of
  how concentrated its commits are across files — tracks how hard that repo is for a
  pooled, history-light model to rank well**, with a strong correlation (ρ=0.73) across 11
  public repos.
- **On exactly the repos where that pooled model struggles (low Gini — commits spread evenly
  across many files), label-free anomaly detection on cheap activity features still produces
  a useful ranking**, with perfect or near-perfect precision@10 on most tested low-Gini
  repos, while the same technique adds no value on repos where the pooled model already
  works well.

## Method

**Model-class screener:** a depth-2 gradient-boosted model and a plain Ridge regression were
each cross-validated against the same label set on 33 public repos, and the gap between their
rank-correlation scores was bucketed into verdict tiers (linear-sufficient, weak-benefit,
strong-benefit, or unreliable when the positive-label rate was too thin to trust the
cross-validation at all). Verdicts were then checked against the actual outcome of training
both model classes on the 13 repos where that had already been done.

**Gini-difficulty correlation:** for 11 public repos, computed the Gini coefficient of the
commit-count distribution across files (0 = every file touched equally, 1 = one file has all
the commits) and correlated it against how well a pooled, cross-repo model (trained with zero
repo-specific history) ranked that repo's files.

**Low-Gini fallback:** for repos below the Gini threshold where the pooled model struggles,
ran an `IsolationForest` — unsupervised anomaly detection — on label-free activity features
(commit count, author count, author entropy, burst score, isolation rate, age, recency),
using only a repo-level contamination parameter derived from the label set, never a per-file
label. Compared precision@10 against the pooled model's own precision@10 on the same repos,
plus a set of high-Gini control repos to confirm the technique doesn't help where it isn't
needed.

## Results

**Model-class screener, 13 repos with known ground truth:** verdicts matched the actual
outcome of running both model classes on all 13 — repos flagged "strong benefit" showed a
real, measured lift from the more complex model class; repos flagged "linear sufficient"
showed the simple model winning or tying; repos flagged "unreliable" (positive rate under 5%)
were correctly quarantined as too thin to trust, after an early version without that guard
showed spuriously huge deltas (an artifact of the complex model memorizing a handful of
positive examples during cross-validation, not a real signal).

**Gini vs. cold-start difficulty, 11 public repos:**

| Repo | Gini | Pooled-model rank quality |
|---|---:|---:|
| vuejs/core | 0.746 | strong |
| scikit-learn/scikit-learn | 0.703 | strong |
| django/django | 0.652 | strong |
| microsoft/vscode | 0.633 | moderate |
| react | 0.499 | weak |
| google/guava | 0.503 | weak |
| elastic/elasticsearch | 0.343 | weakest |

Spearman correlation between Gini and pooled-model rank quality across all 11 repos: **+0.73**
— a repo where commits concentrate on a small set of files is one where a history-light
pooled model can find the risky files; a repo where commits spread evenly across many files
is one where it can't.

**Low-Gini fallback (IsolationForest), compared against high-Gini controls:**

| Repo | Gini | Precision@10 | Base rate |
|---|---:|---:|---:|
| elastic/elasticsearch | 0.343 (low) | **1.000** | 0.053 |
| n8n-io/n8n | 0.463 (low) | **1.000** | 0.455 |
| facebook/react | 0.499 (low) | 0.800 | 0.079 |
| angular/angular | 0.553 (low) | 0.900 | 0.495 |
| django/django | 0.652 (high, control) | 1.000 | 0.256 |
| scikit-learn/scikit-learn | 0.703 (high, control) | 1.000 | 0.184 |

On the low-Gini repos — exactly where the pooled model is weakest — the label-free anomaly
detector still achieves strong precision in the top 10, up to a 19x lift over the repo's own
base rate. The high-Gini control repos confirm the gate's direction: those repos already
have a strong signal available (the pooled model itself), so the fallback isn't needed there
but doesn't hurt either.

## Caveats

- The model-class screener's 13-repo validation set is retrospective — it checks whether the
  screener would have predicted outcomes already known, not a held-out prospective test.
- The Gini correlation (ρ=0.73) is a repo-level correlation across 11 repos, not a
  per-file guarantee — some individual low-Gini repos still rank moderately well, and one
  high-commit-count repo (guava) showed a near-null anomaly-detector correlation despite
  its precision@10 looking fine, because its base rate was already high enough to inflate
  precision without real ranking skill.
- All of this measures against this project's own fix-commit labels, which aren't public.

**Reproducibility:** Partial — the Gini coefficient and the IsolationForest features are all
computable from public git history with no proprietary inputs; the precision numbers above
were measured against this project's private fix-commit labels.
