# F159 / F161 — The PR risk score was removed; changed lines in touched functions replaces it

**Shipped as:** `pr_risk_score` and `size_band` removed from `hotspots diff`; the diff header reports
`fn_changed_lines` and the highest risk band instead | **PR:**
[hotspots#323](https://github.com/Stephen-Collins-tech/hotspots/pull/323)

## What changed

`hotspots diff` used to attach a composite `pr_risk_score` and a size band to the change. They are
gone. The diff now reports **`fn_changed_lines`**, the number of diff-changed lines that fall inside
functions the change touches, together with the highest risk band reached.

## What the evidence showed

F159 tested whether any change-level score beats plain change size at predicting which pull requests
later need a defect fix. Three pre-registered arms covered a history-based composite, a burst signal,
and several complexity-delta scores. None beat size. A burst signal that looked strong in an
exploratory first pass did not replicate on fresh repos.

F161 then tested every candidate against a size baseline matched to what can be attributed to
authors (`fn_changed_lines`) on four repos with roughly 400 to 1,000 pull requests each:

- `fn_changed_lines` discriminated well, with an AUC of 0.82 to 0.86 across the four repos.
- **No candidate beat it.** Of 16 (score, repo) comparisons, none had an interval above zero. Two
  complexity-delta scores were significantly worse on one repo.
- The score that was shipping, a net change in structural score, was the weakest: lower than the
  baseline on all four repos, by 0.022 to 0.112 AUC.
- Counting changed functions or changed files was consistently weaker than `fn_changed_lines`.
- Weighting changed lines by structural score added nothing measurable.

So a composite score that is worse than the size measure it is built on is worse than reporting the
size measure. The 3.0 diff reports `fn_changed_lines` for "is this change risky" and `band` for "what
is the worst code in this diff", and no composite.

## Limits

- Four repos in the head-to-head, labelled by blame attribution, which rewards authored volume. The
  attribution was checked and was right about two thirds of the time.
- A size measure predicts defects partly because bigger changes touch more code. This is a ranking
  result, not a causal one.

## Reproducibility: Partial

`hotspots diff <base> <head>` prints `fn_changed_lines` in 3.0. The pull-request outcome labels and
the comparison harness are not public, so the AUC table cannot be rerun from this repo.
