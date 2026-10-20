# Promotion policy: private research → this repo

## The boundary

A finding is eligible for this repo once **both** are true:

1. It has a merged PR in the public `hotspots` CLI repo (or `hotspots-content`) — i.e. it's
   actually shipped, not pending or in-progress.
2. Its methodology can be described, and its CLI-facing behavior demonstrated, without any of:
   - the private labeled training/bug-commit corpus (`hotspots-research/data/`)
   - unpublished or rejected findings
   - enterprise-only signals (cloud pipeline internals, customer data, anything living only in
     `hotspots-cloud`/`hotspots-analytics`)
   - raw research scripts (per the research repo's own rule: rewrite cleanly, never copy-paste)

A finding can satisfy (1) without fully satisfying (2) — e.g. a trained-ranker finding whose
*feature* (`hotspots train`) is public and runnable, but whose original reported correlation
numbers were measured against a private corpus nobody outside can rerun. Those get a finding
page here too, but marked **"Partial"** or **"No"** under Reproducible, with the honest reason
stated rather than a fabricated reproduction script.

## What never moves here

- `hotspots-research`'s private corpus, raw `data/`, or any script under `scripts/eval/`
- Findings that were rejected, `n/a`, or still `pending`/`in-progress` in the promotion tracker
- Anything that would require describing an enterprise/cloud-only pipeline to explain

## Process

1. A finding ships in `hotspots` (tracker row flips to `promoted`).
2. Someone (human or agent) rewrites it as a finding page in `docs/findings/` here — summary,
   methodology, what shipped (with PR link), and a reproduction script if the claim doesn't
   depend on private data.
3. Add a row to `docs/findings/README.md`.
4. Never copy the private finding doc's prose verbatim — rewrite it. The private doc may
   reference internal script paths, other unpublished findings, or corpus specifics that
   don't belong in a public repo even if the headline claim is fine to share.
