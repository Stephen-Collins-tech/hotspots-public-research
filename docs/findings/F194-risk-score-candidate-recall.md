# F194 — `file_risk_score`'s repo-wide ranking as a candidate filter

**Shipped as:** `file_risk_score` ranking, `hotspots-core/src/aggregates.rs` (ranked/sorted file
table in `hotspots analyze`) | **PR:** [hotspots#213](https://github.com/Stephen-Collins-tech/hotspots/pull/213)

## Claim

Ranking every file in a repo by its existing `file_risk_score` and taking the top 20 (or the
repo's own top-decile, whichever is smaller) catches real bug-fix files at a meaningfully
better-than-chance rate. Originally measured on 3 repos (2.1x-3.2x the random-sample rate);
**since stress-tested on 5 additional, structurally different repos (smaller, different
languages) and held up on 4 of the 5** — 7 of 8 repos tested beat the random floor by at least
2x. The absolute recall is still modest (0.00-0.50 at K=20 depending on repo size) — most
fix-files fall outside the top-K set — but the ranking is a real, reproducible signal, not noise,
and the result is no longer resting on just 3 repos.

## Method

Eight public open-source repos across 4 languages (`django/django`, `scikit-learn/scikit-learn`,
`iced-rs/iced`, `pallets/flask`, `sharkdp/fd`, `gin-gonic/gin`, `axios/axios`, `spf13/cobra`),
each cloned fresh. For each repo: take a snapshot commit, compute `file_risk_score` for every
file from its function-level complexity metrics (`hotspots analyze --all-functions` output,
rolled up the same way `aggregates.rs` does), and label a file "positive" if a bug-fix-shaped
commit (subject/body matched against a fix-keyword heuristic, the same SZZ-style approach used
elsewhere in this repo's findings) touched it within the following 180 days.

Per repo, files were ranked by `file_risk_score` descending (ties broken by path) and recall@K
was computed at K = min(20, the repo's own top-decile) — a smaller K than 20 for the 5 smaller
repos, so "top 20" doesn't swallow most of a 20-file repo. That was compared against the recall a
uniform-random K-file sample would get in expectation — K/n, where n is the repo's file count —
as the no-signal floor.

The pre-registered bar (original 3-repo run): recall@K had to beat the K/n floor by at least 2x on
2 of 3 repos. The follow-up 8-repo run raised the bar to a majority (5/8) passing individually,
*and* a majority of the 5 new repos (3/5) passing on their own — guarding against the original
3/3 being favorable noise that wouldn't generalize.

## Results

| Repo | Files (n) | K | Positives | Recall@K | vs. random floor |
|---|---|---|---|---|---|
| django | 753 | 20 | 177 (23.5%) | 0.056 | 2.13x |
| scikit-learn | 370 | 20 | 76 (20.5%) | 0.171 | 3.16x |
| iced | 214 | 20 | 40 (18.7%) | 0.250 | 2.68x |
| axios | 73 | 8 | 14 (19.2%) | 0.429 | 3.91x |
| gin | 46 | 5 | 4 (8.7%) | 0.250 | 2.30x |
| flask | 32 | 4 | 4 (12.5%) | 0.500 | 4.00x |
| fd | 22 | 3 | 2 (9.1%) | 0.500 | 3.67x |
| cobra | 18 | 2 | 3 (16.7%) | 0.000 | 0.00x |

**7 of 8 repos cleared the 2x bar.** The one miss, `cobra`, is a small-repo edge case: at 18 files
its own top-decile is just 2 files, and with only 3 positively-labeled files total, missing all 3
in a 2-file slice isn't surprising at that sample size — `flask` and `fd`, only modestly larger,
both passed cleanly. Precision@K is separately high on several repos only because each repo's own
base fix-rate is already elevated (9-24%); recall-vs-random-floor is the number that isolates the
ranking's actual signal from that base rate.

## Reproducibility: Yes

```bash
scripts/reproduce.sh F194 ~/code/some-repo
```

Both the feature and the measurement are public. `file_risk_score` is live in `hotspots analyze`
today — run it on any repo to get the same ranked file table. The recall@K comparison needs
only a public git clone, `hotspots analyze --all-functions` output, and a fix-commit heuristic
over commit messages (no private data, no trained model, no proprietary corpus): rank files by
`file_risk_score`, pick a forward-looking window, label files touched by a fix-shaped commit in
that window, and compare recall@K against K/n. `scripts/findings/F194.sh` runs exactly that —
a public approximation of the fix-keyword heuristic (Conventional-Commit `fix:`/`revert` plus
plain-English fix wording, minus the private corpus's blame-based defect-attribution machinery
used elsewhere in this research, which this finding never needed). Anyone can rerun this against
a repo and time window of their choosing; the specific percentages will vary with the label
window and repo chosen — the script doesn't assert pass/fail against the numbers above, it prints
the same recall@K-vs-random-floor comparison so you can see the ranking behave the same way.
