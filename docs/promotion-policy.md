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
- Findings that were rejected, `n/a`, or still `pending`/`in-progress` in the promotion tracker, **except** as described under "Shipped removals and negative results" below
- Anything that would require describing an enterprise/cloud-only pipeline to explain

## Shipped removals and negative results (amended 2026-11-02)

A change that shipped in `hotspots` or `hotspots-content` because of a negative or null result counts as shipped, even though
the underlying finding is negative. Examples: a field, label or command removed because the evidence did not support it; a
formula reweighted because one term was shown to add nothing. These get a page here, so that every public explanation of
*why* a feature exists, changed or was removed has a matching public research page the docs can link to.

The conditions are the same as for any other page, plus:

1. The removal or change has a merged PR (write the page after it ships, never before).
2. The page states, in plain language, what was removed or changed, what the evidence showed, how it was measured without
   private data, and its limits. It says plainly when the result is negative.
3. No private corpus data, no unpublished or still-pending findings, no enterprise-only signals, no raw scripts; mark
   Reproducible as "Partial" or "No" with the honest reason where the measurement used data nobody outside can rerun.
4. A finding that did not lead to a shipped change (still rejected, `n/a`, `pending`) still does not move here.

## Process

1. A finding ships in `hotspots` (tracker row flips to `promoted`).
2. Someone (human or agent) rewrites it as a finding page in `docs/findings/` here — summary,
   methodology, what shipped (with PR link), and a reproduction script if the claim doesn't
   depend on private data.
3. Add a row to `docs/findings/README.md`.
4. Never copy the private finding doc's prose verbatim — rewrite it. The private doc may
   reference internal script paths, other unpublished findings, or corpus specifics that
   don't belong in a public repo even if the headline claim is fine to share.
