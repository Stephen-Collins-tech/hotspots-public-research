# F05 — Risk, Coupling, and Ownership are independent axes

**Shipped as:** `hotspots analyze --axes` | **PR:** [hotspots#162](https://github.com/Stephen-Collins-tech/hotspots/pull/162)

## Claim

A single merged "hotspot" ranking conflates three different questions about a file:
*is it complex and heavily changed* (Risk), *is it entangled with other files that change
together* (Coupling), and *is it owned by too few/too many people* (Ownership). The research
found these three rankings surface largely different files — a file can be low-risk but
highly coupled, or high-risk but well-owned — so collapsing them into one score hides
actionable distinctions.

## What shipped

`hotspots analyze --axes` prints three independently-ranked sections instead of one merged
list:

- **Risk** — ranked by `activity_risk` (LRS + churn/touch/recency), deduped to one row per
  file (max across that file's functions)
- **Coupling** — ranked by co-change coupling strength between files
- **Ownership** — ranked by `author_entropy` / `newcomer_rate` (how concentrated or diffuse
  recent authorship is)

Files can appear in more than one section — overlap is not deduplicated across axes, since
the point is that the axes disagree.

## Reproduce

```bash
scripts/findings/F05.sh /path/to/a/git/repo
```

which runs:

```bash
hotspots analyze /path/to/a/git/repo --axes --top 15
```

Compare the three sections' file lists by eye — on most repos with real git history, the
three top-15s share only a handful of files, which is the independence claim in miniature.
