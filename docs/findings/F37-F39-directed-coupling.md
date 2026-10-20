# F37/F39 — Directed, recency-windowed coupling

**Shipped as:** `directed_coupling` trainer feature | **PR:** [hotspots#85](https://github.com/Stephen-Collins-tech/hotspots/pull/85) (v1.23.0)

## Claim

An earlier coupling signal (undirected NMI between co-changing files) showed sign-flips
across repos — sometimes predictive, sometimes anti-predictive, with no clear moderator.
F37 found that making coupling **directed** (does file A's change tend to *precede* file
B's, not just co-occur) eliminates the sign-flip. F39 found windowing the coupling
calculation to a recent period (rather than full repo history) further improves holdout
performance.

## What shipped

`directed_coupling` is the trainer's 9th feature (`hotspots-core/src/trainer.rs`
`FEATURE_NAMES`), computed by `coupling::compute_directed_coupling_for_repo` and populated
per-function via `Snapshot::populate_directed_coupling`. A companion reliability screener
(F38) excludes it below a Jaccard label-stability threshold — implemented, but a further
exclusion refinement (F127) was tried, measured to make P@K worse, and explicitly
**not merged** (documented directly in the research tracker as a do-not-recreate branch).

## Reproduce

```bash
scripts/findings/F37-F39.sh /path/to/a/git/repo
```

which runs:

```bash
hotspots analyze /path/to/a/git/repo --mode snapshot --format json --all-functions --no-persist \
  | jq '[.functions[] | select(.directed_coupling != null)] | sort_by(-.directed_coupling)[0:10]'
```

Confirms the field is populated and non-trivial on a repo with real co-change history —
this reproduces that the feature computes, not the original cross-repo rho/sign-flip
comparison (that required the private labeled corpus across multiple repos).
