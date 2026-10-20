# F55-explain — Ranker score + explanation layer

**Shipped as:** `hotspots analyze --explain` | **PR:** [hotspots#115](https://github.com/Stephen-Collins-tech/hotspots/pull/115)

## Claim

A trained-ranker risk score (a RandomForest probability, see
[F07/F19/F22/F28](F07-F19-F22-F28-trained-ranker.md)) is not self-explanatory — a developer
looking at "this function scored 0.82" has no way to act on it. The finding proposed
surfacing *which* features drove a given function's score as human-readable text.

## What shipped

`--explain` (snapshot mode, text format only — incompatible with `--mode delta`/`--mode
models` and with `--level`) prints a short natural-language explanation per flagged
function alongside its score, derived from the trained model's feature contributions.

## Reproduce

```bash
scripts/findings/F55-explain.sh /path/to/a/git/repo
```

which runs:

```bash
hotspots analyze /path/to/a/git/repo --mode snapshot --explain --top 10
```

Look for the explanation text attached to each of the top-ranked functions.
