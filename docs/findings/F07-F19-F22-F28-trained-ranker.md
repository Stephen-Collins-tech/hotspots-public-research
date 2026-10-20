# F07/F19/F22/F28 — Trained tabular ranker

**Shipped as:** `hotspots train` (RandomForest, Rust via `linfa`) | **PR:** [hotspots#79](https://github.com/Stephen-Collins-tech/hotspots/pull/79)

## Claim

A trained tabular ranker (originally validated against XGBoost in Python) beats the
hand-written `hotspots_score` formula on 7 of 9 repos tested. A Rust reimplementation
using `linfa`'s RandomForest matches the Python/XGBoost prototype's ranking quality
(no fidelity loss from the production reimplementation).

## What shipped

`hotspots train` fits a 9-feature RandomForest (200 trees, depth 6) per-repo on your own
git history and bug-fix-commit labels, producing `model_version=6` artifacts. Feature set:
`lrs, cc, nd, loc, fo, fan_in, total_churn, authors_90d, directed_coupling`
(`hotspots-core/src/trainer.rs::FEATURE_NAMES` — see [F54](F54-bug-commits-temporal-holdout.md)
for a feature that was in this list and later removed).

## Reproducibility: partial

You can run the full training pipeline yourself — `hotspots train` requires nothing private,
just your own repo's git history. What you **cannot** reproduce is the original "beats
`hotspots_score` on 7/9 repos" comparison: that required labeled bug-commit ground truth
across a specific 9+ repo corpus assembled and labeled in the private research repo, which
isn't published (labeling methodology itself has its own findings — F31 and its sequence —
about leakage and label quality that are not simple to redo correctly).

## Reproduce (pipeline only)

```bash
scripts/findings/F07-F19-F22-F28.sh /path/to/a/git/repo
```

which runs:

```bash
hotspots train /path/to/a/git/repo --eval --yes   # trains, then prints the repo's own P@K table (F24)
```

This confirms the ranker trains and evaluates on your repo — not that it beats the formula
on the original corpus, which you'd need your own labeled holdout to check honestly.
