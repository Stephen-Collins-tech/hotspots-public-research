# F170 — File/module risk score calibration

**Shipped as:** `aggregates.rs` weight calibration | **PR:** [hotspots#213](https://github.com/Stephen-Collins-tech/hotspots/pull/213)

## Claim

`file_risk_score` and `module_risk` (the aggregated, file/module-level rollups of
per-function risk, in `hotspots-core/src/aggregates.rs`) had their weighting and cutoff
thresholds calibrated via a 16-repo weight sweep plus a 4-repo module-cutoff grid search.

## What shipped

Updated weights/cutoffs in `aggregates.rs` for how per-function scores roll up to a
file-level and module-level risk score.

## Reproducibility: no

The calibration itself was a sweep over a 16-repo private corpus searching for the
weight/cutoff combination that best matched that corpus's labels — there's no single
"run this command" reproduction for a grid search's output. The *result* (the specific
weights now in `aggregates.rs`) is visible in the public source, and you can run
`hotspots analyze` on any repo to see the file/module rollups those weights produce — but
confirming they're the *optimal* weights requires rerunning the original 16-repo sweep,
which needs the private labeled corpus.
