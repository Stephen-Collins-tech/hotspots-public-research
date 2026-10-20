# F54 — Bug-commits temporal holdout (shipped, then later removed)

**Shipped as:** `convention_bug_fix_count` trainer feature, added via REQ-002 at model_version 3
**Later removed:** model_version 6, per F168 ([hotspots#182](https://github.com/Stephen-Collins-tech/hotspots/pull/182)) — see below

## Claim (original)

A feature counting how often a function's file has been touched by commits whose message
matches a "fix"/"bug" convention survived temporal holdout testing (3 of 5 repos showed
signal) and was added as the trainer's 10th feature.

## What actually happened (read this before citing F54 as current)

Checking current `main` (as of this writeup) rather than trusting the promotion tracker's
`promoted` status alone: `convention_bug_fix_count` **is no longer in the trained ranker's
feature set.** `hotspots-core/src/trainer.rs` documents it was removed at model_version 6,
per a later finding (F168) that found it **ratchets** — a file that was ever fixed keeps
contributing to the feature indefinitely, pushing the trained ranker to over-rank files
with any historical bug-fix commit regardless of current risk. There's an explicit
regression test (`trainer.rs`) asserting `FEATURE_NAMES` does *not* contain
`convention_bug_fix_count`.

This is the right outcome of the project's own promotion discipline working as intended —
a confirmed finding that was promoted, then caught and reverted by a later confirmatory
finding — not a case of an exploratory result being mistakenly shipped. It's included here
specifically so a reader checking "is F54 still true" gets the current answer, not the
original one.

## Reproduce

Not reproducible as a live feature — the field was removed. You can confirm its absence
yourself:

```bash
scripts/findings/F54.sh
```

which just greps the public `hotspots-core/src/trainer.rs` source for the removal note and
the `FEATURE_NAMES` constant, so you can see both model_version 6's feature list and the
explicit "does not contain convention_bug_fix_count" test.
