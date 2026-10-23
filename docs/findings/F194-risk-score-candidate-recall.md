# F194 — `file_risk_score`'s repo-wide ranking as a candidate filter

**Shipped as:** `file_risk_score` ranking, `hotspots-core/src/aggregates.rs` (ranked/sorted file
table in `hotspots analyze`) | **PR:** [hotspots#213](https://github.com/Stephen-Collins-tech/hotspots/pull/213)

## Claim

Ranking every file in a repo by its existing `file_risk_score` and taking the top 20 (or the
repo's own top-decile, whichever is smaller) catches real bug-fix files at 2.1x-3.2x the rate a
same-size random sample would, on all three repos tested. The absolute recall is still modest
(0.06-0.25 at K=20) — most fix-files fall outside the top 20 — but the ranking is a meaningfully
better-than-chance candidate set, not noise.

## Method

Three public open-source repos (`django/django`, `scikit-learn/scikit-learn`, `iced-rs/iced`),
each cloned fresh. For each repo: take a snapshot commit, compute `file_risk_score` for every
file from its function-level complexity metrics (`hotspots analyze --all-functions` output,
rolled up the same way `aggregates.rs` does), and label a file "positive" if a bug-fix-shaped
commit (subject/body matched against a fix-keyword heuristic, the same SZZ-style approach used
elsewhere in this repo's findings) touched it within the following 180 days.

Per repo, files were ranked by `file_risk_score` descending (ties broken by path) and recall@K
was computed for K in {5, 10, 20, top-decile}: the fraction of all positively-labeled files that
land inside the top K. That was compared against the recall a uniform-random K-file sample would
get in expectation — K/n, where n is the repo's file count — as the no-signal floor.

The pre-registered bar: at K=20 (or top-decile if smaller), recall@K had to beat the K/n floor by
at least 2x on 2 of 3 repos for the ranking to count as a usable candidate filter.

## Results

| Repo | Files (n) | Positives | K=20 recall | vs. random floor |
|---|---|---|---|---|
| django | 753 | 177 (23.5%) | 0.056 | 2.13x |
| scikit-learn | 370 | 76 (20.5%) | 0.171 | 3.16x |
| iced | 214 | 40 (18.7%) | 0.250 | 2.68x |

All three repos cleared the pre-registered 2x bar — stronger than the 2-of-3 threshold required.
Precision@K is separately high (0.40-0.90) only because each repo's base fix-rate is already
~20%; recall-vs-random-floor is the number that isolates the ranking's actual signal from that
base rate.

## Reproducibility: Yes

Both the feature and the measurement are public. `file_risk_score` is live in `hotspots analyze`
today — run it on any repo to get the same ranked file table. The recall@K comparison needs
only a public git clone, `hotspots analyze --all-functions` output, and a fix-commit heuristic
over commit messages (no private data, no trained model, no proprietary corpus): rank files by
`file_risk_score`, pick a forward-looking window, label files touched by a fix-shaped commit in
that window, and compare recall@K against K/n. Anyone can rerun this against a repo and time
window of their choosing; the specific percentages will vary with the label window and repo
chosen, but the comparison method is fully public.
