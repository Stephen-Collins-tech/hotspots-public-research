# F183 — `ownership_risk` and its low / medium / high band

**Shipped as:** `ownership_risk` and `ownership_risk_band` on each file in `hotspots coordinate` output
| **PR:** [hotspots#323](https://github.com/Stephen-Collins-tech/hotspots/pull/323)

## Claim

How evenly a file's commits are spread across authors predicts how often a second author's change
collides with an earlier one on that file, and the relationship is graded, not a single cut.
`ownership_risk` (0 to 1, higher means more diffuse ownership) and a three-level band make that
usable for ranking a set of files before you split work across people or agents.

## Method

- `ownership_risk` is Shannon entropy of the author distribution on a file, divided by its maximum for
  that file's author count, so files with different numbers of authors compare fairly. It is not
  defined for files with one author.
- Band boundaries are pooled terciles of that value across the evaluation repos (0.754 and 0.907),
  fixed before looking at outcomes.
- Outcome: how often changes to the same file by different authors collided, measured from git history
  (a coordination outcome), per tercile.

## Results

Across the eight repos with enough data and a usable clone, the pooled collision rate rose
steadily with the band: **0.21 (low), 0.52 (medium), 0.71 (high)**. The ordering held on seven of the
eight repos. The eighth had known repository corruption, not a counter-example.

A leave-one-repo-out check, with boundaries learned from the other repos and the ordering checked on the
held-out one, confirmed the ordering on seven of eight again. An earlier finding on the narrow end of
the same signal (the `knowledge_mode: "concentrated"` flag) found concentrated files collided 1 to 11% of
the time against 36 to 63% for others, significant on all eight testable repos. A later noise-floor audit
found this ownership effect survives on every testable repo by a wide margin.

## Limits

- Collision is a coordination outcome, not a defect outcome. Ownership concentration has **not** been
  shown to predict bug fixes, so do not read the band that way. Use `ownership_risk` for "who will step on whom", not "where are the bugs".
- Eight repos; the boundaries are pooled, so a repo's own distribution may sit mostly in one band.

## Reproducibility: Partial

`hotspots coordinate --files <paths>` prints `ownership_risk` and the band for any repo you can clone.
The collision labels came from a git-history study whose harness is not public, so the table above
cannot be rerun here; you can compute collision rates on your own repo from `git log` and compare the
ordering across bands.
