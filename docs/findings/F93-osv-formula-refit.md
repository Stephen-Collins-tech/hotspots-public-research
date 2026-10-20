# F93 — OSV/CVE ground-truth formula refit

**Shipped as:** commit-timing burstiness term (`burst`) in `ScoringWeights` / `scoring.rs` | **Status:** shipped, no public PR link available

## Claim

A 5-signal logistic regression refit against real OSV/CVE vulnerability ground truth (not
the corpus's proxy bug-fix labels) beat `hotspots_score` with mean ΔAUC +0.116 (9/10 wins)
on the subset of repos where `hotspots_score` was actually populated. It also found
`author_count` redundant once `burst_score` + `commit_count` were included.

## What shipped

`ScoringWeights::burst` — a weight for commit-timing burstiness ("a burst of frantic
commit activity rather than steady, spread-out changes") in the activity-weighted risk
score. The raw `burst_score` is still computed (`history_signals.rs`/`snapshot.rs`) even
though, per a later finding, it was removed from the *live* composite score for a
different, structural reason (it's monotonic non-decreasing over a file's full history,
so including it directly made `activity_risk` a one-way ratchet).

## Reproducibility: no

This finding was validated against real-world OSV/CVE vulnerability records mapped to
specific commits in a private corpus. That ground truth (which commits fixed which CVE,
across which repos) isn't published, and reconstructing it accurately is itself a
nontrivial research task — not something a reproduction script can approximate. The
*shipped* artifact (the `burst` weight field) is visible in the public
`hotspots-core/src/scoring.rs` source if you want to inspect the mechanism, but there is
no public way to re-run the original AUC comparison.
