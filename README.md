# hotspots-public-research

Public write-ups of the [hotspots](https://github.com/Stephen-Collins-tech/hotspots) research
findings that have actually shipped as CLI features — rewritten from the private research corpus
so an outside visitor can read the methodology and, where the claim doesn't depend on a private
labeled dataset, re-run it themselves against any public repo.

This repo exists to separate **what supports the public tool** (belongs here, public) from
**proprietary research** (training corpora, unpublished findings, enterprise-only signals — stays
in the private `hotspots-research` repo). See [`docs/promotion-policy.md`](docs/promotion-policy.md)
for the exact boundary and how a finding moves from private to here.

## Index

Each row is one finding that shipped in the CLI. "Reproducible" means you can verify the claim
yourself with just the public CLI and a public git repo — see
[`docs/findings/README.md`](docs/findings/README.md) for the full table with links.

| Finding | Shipped as | Reproducible here |
|---|---|---|
| F05 — Independence hypothesis | `hotspots analyze --axes` | Yes |
| F37/F39 — Directed coupling | `directed_coupling` feature, windowed | Yes |
| F41 — C language support | tree-sitter-c parser | Yes |
| F54 — Bug-commits temporal holdout | shipped, then removed at model_version 6 (ratchet effect, see F168) | No |
| F55-explain — Ranker explanation layer | `hotspots analyze --explain` | Yes |
| F07/F19/F22/F28 — Trained tabular ranker | `hotspots train` (RandomForest) | Partial — pipeline yes, original rho numbers need the private labeled corpus |
| F93 — OSV formula refit | burst/ownership weighting in `scoring.rs` | No — needs private OSV/CVE-labeled corpus |
| F98 — Cold-start anomaly score | IsolationForest cold-start screener | No — needs private low-label-density corpus |
| F170 — file/module risk calibration | `aggregates.rs` weights | No — needs private 16-repo calibration sweep |

Full index: [`docs/findings/README.md`](docs/findings/README.md).

## Reproducing a finding

```bash
scripts/reproduce.sh <finding-id> <path-to-a-public-git-repo>
```

Each script clones nothing itself — point it at a local checkout of any public repo (your own
fork of `redis`, `vue`, whatever you have handy) and it runs the `hotspots` commands the finding's
doc describes, so you can compare the shape of the output against what's documented. See
[`scripts/README.md`](scripts/README.md).

## Relationship to the private research repo

Findings are authored and confirmed in the private `hotspots-research` repo first (pre-registered
design doc → confirmatory run → promotion brief → CLI PR). Only once a finding has **shipped** —
there's a merged PR in the public `hotspots` repo to point to — does it get rewritten and added
here. This repo is never the research repo itself: no raw experiment scripts, no unpublished
findings, no private corpus data, no enterprise-only signal methodology.
