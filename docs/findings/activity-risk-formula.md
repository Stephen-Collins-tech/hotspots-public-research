# F160 / F241 — What the activity risk score is built from

**Shipped as:** the `activity_risk` formula (formula version 3) in hotspots 3.0 | **PR:**
[hotspots#323](https://github.com/Stephen-Collins-tech/hotspots/pull/323), released in
[v3.0.0](https://github.com/Stephen-Collins-tech/hotspots/releases/tag/v3.0.0)

## Claim

Two claims, with different strength.

1. **Backed:** a function's git activity (how often and how recently its file changes) carries
   most of the predictive signal in the old score, while the call-graph and dependency-depth terms
   carry none.
2. **Weakly backed:** the 3.0 formula, a sum of four terms each scaled to a fixed range, ranks
   later bug-fix files no worse than the 2.6.3 formula and modestly better on a small set of repos.

The specific scale constants and the equal weighting of the four terms are **design choices**. They
keep the score bounded and comparable across repos. They were not tuned against labels and were not
tested against alternatives.

## The formula

```
activity_risk = lrs / 20.2
              + min(log2(1 + lines_added_and_deleted) / 14, 1)   # churn, 180-day window
              + min(touch_count / 50, 1)                          # touches, 365-day window
              + max(0, 1 - days_since_last_change / 35)           # recency
```

Churn, touch and recency are file-level and apply to every function in the file. 20.2 is the largest
structural score observed. The range is roughly zero to four, and a missing signal contributes zero.

## Evidence for claim 1 (F160, F167)

F160 decomposed the previous five-term score (structure, touch, recency, fan-in, and a cycle term)
on the 17 repos that passed a label-quality gate: at least 200 functions in the holdout and a
positive rate between 5% and 95%. Metrics were rank correlation with the bug-fix label and
precision at the top 10%, with a bootstrap interval over repos.

| Term | Share of the explained correlation (Shapley, mean over repos) |
|---|---|
| touch | 47% |
| recency | 50% |
| fan-in | 4% |
| cycle term | 1% |
| structure (LRS) | −2% |

- Dropping the call-graph terms (fan-in and cycles) was statistically non-inferior to keeping them.
- Dropping the git touch and recency terms, or using structure alone, lost about 0.03 correlation,
  with intervals that exclude zero.
- Structure dominated the sum numerically (a median of 3.8 against roughly 1.5 and 1.0 for the two
  activity terms), which muted the activity terms. That reading is exploratory, not pre-registered;
  it is the reason the 3.0 formula scales every term into the same range.

F167 did the same for the dependency-depth term on five repos that passed the gate. Its share was
−2.1%, its effect was not sign-consistent across repos, and removing it was non-inferior.

Limit: the churn-lines term was **not** tested in F160 or F167; there was no holdout data for it.

## Evidence for claim 2 (F241)

A head-to-head of the two released binaries, run the way a user would run them, on 13 repos at a
fixed pre-2023 commit each:

- Arm A: hotspots 2.6.3. Arm B: the 3.0 formula. Control C: structure alone.
- A file's score is the maximum function score in it. The label is whether a fix-shaped commit
  touched the file in the following 180 days. Metric: recall at K, with K = min(20, top decile).
- The decision rule, fixed before running: B is better if the 95% bootstrap interval (over repos) on
  the mean difference B − A is above zero; non-inferior if its lower bound is above −0.03.

| Repo | Files | Positives | A (2.6.3) | B (3.0) | C (structure) |
|---|---|---|---|---|---|
| django | 753 | 177 | 0.056 | 0.096 | 0.051 |
| scikit-learn | 370 | 76 | 0.184 | 0.171 | 0.184 |
| iced | 214 | 40 | 0.300 | 0.350 | 0.325 |
| flask | 32 | 4 | 0.000 | 0.500 | 0.250 |
| fd | 22 | 2 | 0.500 | 0.500 | 0.500 |
| gin | 46 | 4 | 0.500 | 0.750 | 0.500 |
| axios | 73 | 14 | 0.357 | 0.357 | 0.357 |
| cobra | 18 | 3 | 0.000 | 0.000 | 0.000 |
| black | 102 | 12 | 0.500 | 0.500 | 0.583 |
| redis | 154 | 42 | 0.286 | 0.262 | 0.286 |
| rails | 66 | 3 | 0.000 | 0.000 | 0.000 |
| vuejs/core | 218 | 39 | 0.154 | 0.308 | 0.154 |
| echo | 37 | 8 | 0.250 | 0.250 | 0.125 |
| **mean** | | | **0.237** | **0.311** | 0.255 |

Mean difference B − A = +0.074, 95% interval [+0.007, +0.158]: **better by the pre-set rule**, with
5 wins, 6 ties and 2 losses.

## Limits

- The interval's lower bound is barely above zero. The gains are concentrated in two small repos
  (flask has 4 positive files); the two largest repos with hundreds of positives move by +0.04 and
  −0.01.
- The same 13 repos were used by earlier work. The 3.0 constants were not tuned on their labels,
  but they are not a fresh sample.
- The fix label is a keyword and convention heuristic, not ground truth. A later audit found that
  two plausible fix detectors can disagree substantially, so absolute recall values are not
  comparable across labelling choices.
- The two binaries differ in more than the formula (the touch window changed from 30 to 365 days),
  so this validates the shipped formula as a whole, not any single change.
- File-level labels with a max-over-functions score cannot show function-level ranking quality.

## Reproducibility: Partial

Everything but the labels is public. You can check out any pre-cutoff commit of a public repo, run
`hotspots analyze . --mode snapshot --format json --all-functions` with hotspots 2.6.3 and with 3.0,
build a keyword-based fix label as in [F194](F194-risk-score-candidate-recall.md), and compare
recall at K per repo. Expect the same direction, not identical figures: the labelling pipeline behind
the table above is not public.
