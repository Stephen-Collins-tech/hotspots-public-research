# F206-F208-F209 — Blending `file_risk_score` with true churn (`--blend-churn`)

**Shipped as:** opt-in `hotspots analyze --blend-churn` (file-level re-ranking), plus a 180-day churn
window fix | **PR:** [hotspots#295](https://github.com/Stephen-Collins-tech/hotspots/pull/295),
released in [v2.4.0](https://github.com/Stephen-Collins-tech/hotspots/releases/tag/v2.4.0)

## Claim

Ranking files by the average of two percentile ranks, `file_risk_score` and true churn (lines
added plus deleted over the preceding 180 days), recovers more future bug-fix files in the top-K
than `file_risk_score` alone on most repos tested. Across 13 public repos the blend beat or tied
the static ranking on 12. It is not uniformly better: it regressed clearly on one repo, and there
is currently no way to tell in advance which repos it will hurt. For that reason it ships
opt-in rather than as the default ranking.

## Method

Same setup as [F194](F194-risk-score-candidate-recall.md): for each repo, take a snapshot commit,
compute `file_risk_score` per file from `hotspots analyze --all-functions` output, and label a file
positive if a fix-shaped commit touched it in the following 180 days. Metric is recall@K with
K = min(20, the repo's top decile), compared against the Static (F194) ranking.

The blend adds one feature: **true churn**, the sum of lines added plus lines deleted per file over
the 180 days before the snapshot (`git log --numstat`). Both signals are converted to percentile
ranks across the repo's files (descending sort, ties broken by path, position mapped to [0, 1]),
and the blended score is the plain 50/50 average. Nothing is tuned: no weights, no per-repo
parameters.

Evaluation had two stages. The blend was first tested on the 8 repos from the F194 work (django,
scikit-learn, iced, flask, fd, gin, axios, cobra). It was then stress-tested on 5 repos that had not
been used before, chosen across languages and sizes in advance: psf/black, redis, rails, vuejs/core,
labstack/echo. The bar for the second stage was that the blend must beat static on at least 3 of the
5 new repos and on at least 7 of 13 combined.

An important prerequisite: the `churn` value that `hotspots` computed before v2.4.0 came from a
single commit's diff, which carries almost no defect-risk signal. The 180-day windowed version is
what the results below measure, so shipping the blend required fixing the window first. That fix
applies to every `analyze` run, not only `--blend-churn` (see below).

## Results

recall@K, Static vs. Blend:

| Repo | Files (n) | K | Positives | Static | Blend |
|---|---|---|---|---|---|
| django | 753 | 20 | 177 | 0.056 | 0.096 |
| scikit-learn | 370 | 20 | 76 | 0.171 | 0.184 |
| iced | 214 | 20 | 40 | 0.250 | 0.325 |
| axios | 73 | 8 | 14 | 0.429 | 0.429 |
| gin | 46 | 5 | 4 | 0.250 | 0.500 |
| flask | 32 | 4 | 4 | 0.500 | 0.500 |
| fd | 22 | 3 | 2 | 0.500 | 1.000 |
| cobra | 18 | 2 | 3 | 0.000 | 0.000 |
| vuejs/core (new) | 218 | 20 | 39 | 0.231 | 0.256 |
| redis (new) | 154 | 16 | 42 | 0.262 | 0.310 |
| psf/black (new) | 102 | 11 | 12 | 0.417 | 0.500 |
| labstack/echo (new) | 37 | 4 | 8 | 0.375 | **0.125** |
| rails (new) | 66 | 7 | 3 | 0.000 | 0.000 |

- Blend strictly better on 8 of 13, tied on 4, worse on 1.
- Two of the 4 ties (rails, cobra) are 0.000 on both rankings, a small-sample floor rather than
  evidence either way; axios and flask tie at non-zero recall.
- On the 5 new repos: 3 strict wins, 1 trivial 0-0 tie, 1 regression. This clears the pre-set bar
  (at least 3 of 5 new, at least 7 of 13 combined).
- The headline wins (fd 0.500 to 1.000, gin 0.250 to 0.500) are on very small repos with a handful
  of positives; treat their magnitude cautiously. The larger repos (django, scikit-learn, redis,
  vuejs/core) improve only modestly, by 0.013 to 0.048 recall.

## Known limitation: the blend can regress, and this is not predictable in advance

On `labstack/echo` the blend falls from 0.375 to 0.125, the only regression in the 13 repos.
Earlier reads of these results attributed such cases to the two signals "disagreeing", but on
re-checking, the other candidates (axios, cobra) were ties, not losses, and a gate based on how
strongly the two rankings correlate would have blocked the best result (fd) as readily as the
failure. What does separate echo is that churn there has essentially no correlation with the
forward fix label (Spearman about 0.04, versus about 0.28 to 0.48 on every other repo that had
positives). Averaging in a signal that carries no information naturally degrades a ranking that
otherwise works.

That statistic needs the future label, so it cannot be used as a gate when ranking files. With a
single failure in the sample, no observable-at-ranking-time proxy could be validated either. So the
limitation stands as stated: expect an improvement on most repos, with a real chance of a worse
ranking on some, and no reliable way to know beforehand.

## What shipped

[hotspots#295](https://github.com/Stephen-Collins-tech/hotspots/pull/295), released in v2.4.0:

- **Churn window fix (affects all users).** `churn` is now computed over a 180-day trailing window
  instead of a single commit's diff. `FORMULA_VERSION` went from 1 to 2, so scores derived from churn
  (for example `activity_risk`) shift on upgrade, and snapshots from before and after cannot be
  diffed against each other.
- **`--blend-churn` (opt-in).** `hotspots analyze --blend-churn` re-ranks file-level output by the
  50/50 percentile blend described above. It adds `churn_percentile` and `file_risk_score_blended`
  to file views and prints a "Blended Score" line. Without the flag, output is unchanged.

### Why `--blend-churn` is opt-in

The blend improves most repos but has a confirmed regression case and no way to predict it. Making
it the default would silently worsen the ranking for some users with no warning signal. Keeping it
opt-in lets users compare both rankings on their own repo. The window fix, by contrast, corrects an
already-shipped signal that had little predictive value, so it is not opt-in.

## Reproducibility: Yes

```bash
scripts/reproduce.sh F206-F208-F209 ~/code/some-repo
```

Everything needed is public: a git clone, `hotspots analyze --all-functions` output, `git log
--numstat`, and the same public fix-keyword heuristic as F194. `scripts/findings/F206-F208-F209.sh`
(run it directly to pass an optional snapshot SHA, window length, or K as further arguments)
computes the Static and Blend recall@K for a repo and window of your choosing and prints them next
to the random-K floor. It reimplements the blend independently (the shipped `--blend-churn` flag
computes the same thing at file level), so you can also compare it to the CLI's own ranking. As with
F194, the fix-label heuristic is an approximation of the one behind the table above, and results
depend on the snapshot and window, so exact figures will differ. Do not expect it to reproduce
echo's drop exactly; it is a way to test the blend on your own repos.
