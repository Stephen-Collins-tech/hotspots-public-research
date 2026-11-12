# F08, F13, F24, F27, F38 — Making the trained ranker fail safely instead of failing silently

**Shipped as:** `hotspots train --screen` (repo-level screener, PR [#91](https://github.com/Stephen-Collins-tech/hotspots/pull/91));
`hotspots train --eval` P@K table (branch `feat/train-eval-pak`); suppression gate in
`hotspots analyze` (PR [#79](https://github.com/Stephen-Collins-tech/hotspots/pull/79));
directed-coupling reliability screener, PR [#85](https://github.com/Stephen-Collins-tech/hotspots/pull/85) / v1.23.0;
and a feature that was correctly kept *out* of the trained ranker's input set

## Claim

Five related findings, each about the same underlying problem: a tabular ranker that looks
fine on average can still fail completely at the top of its own ranking — exactly where
engineers actually look — and the fix isn't a better formula, it's detecting the failure and
falling back safely.

- **A cheap pre-training screener can predict whether per-repo model training is even worth
  running**, filtering out repos where it would waste compute or (if run anyway) actively
  mislead. A label-density heuristic looked clean at first but broke on one repo for a subtle
  reason (high density ≠ meaningful signal); switching to mean ranker score fixed it with 7/7
  verified accuracy on the original calibration set.
- **Precision-at-top-K can collapse to zero even when the overall rank correlation looks
  fine.** On one repo, every ranker tested — the formula, a trained model, all of them — put
  zero real future bugs in its top 10 predictions, while the bug rate in that top bucket was
  *lower* than the repo's base rate. Spearman correlation alone would never have caught this.
- **A calibration-based gate, checked on the top of a ranker's own output (not a random
  sample), reliably detects this failure mode and triggers a fallback** — validated with zero
  false positives across the repos where it was tested.
- **A coupling feature (`co_change_partners`) was correctly never added to the trained
  ranker's feature set** in the first place, because its signal direction flips depending on
  how densely a repo's commits touch many files at once — a feature that predicts risk on one
  repo and anti-predicts it on another isn't safe to include without per-repo validation,
  which doesn't exist.
- **The directed-coupling feature needs the same kind of pre-flight check**: a cheap "does the
  set of historically risky files stay stable over time in this repo" screener correctly
  separates repos where coupling data transfers from train to holdout from repos where it
  doesn't, on 4 of 5 tested repos (the fifth needed a different gate entirely — see below).

## Method

Each of these used precision-at-K (not just Spearman correlation) against real future-fix
outcomes on public repo histories, specifically because rank correlation is known to mask
top-of-list failures. The screener and suppression-gate work calibrated thresholds against a
small known-outcome set (repos where the researchers already knew, from direct evaluation,
whether a given technique worked), then checked whether the cheap pre-check would have
predicted the same verdict without running the expensive thing first.

## Results

**Repo screener (mean ranker score as the signal, not label density):**

| Repo | Verdict | Beats baseline activity ranker? |
|---|---|---|
| django/django | proceed | yes |
| facebook/react | proceed | yes |
| vuejs/core | proceed | yes |
| scikit-learn/scikit-learn | proceed | yes |
| microsoft/vscode | skip | no |
| golang/go | skip | no |
| vercel/next.js | skip | no |

7 of 7 verdicts matched the ground-truth outcome from actually running both approaches. The
threshold that separates "proceed" from "skip" self-calibrates to the midpoint between the
weakest proceed-repo and the strongest skip-repo in the known set, rather than using a fixed
cutoff.

**Precision@K collapse on a hard repo:** on the hardest tested public repo, the top-10
ranked functions from every ranker contained **zero** real future bugs — a 0% precision rate
against a roughly-20% base rate (i.e., worse than guessing at random). The root cause: the
functions with the highest churn, complexity, and recency on this repo are core, heavily-
exercised, rarely-regressing APIs, while the actual bugs cluster in quieter, peripheral code.
Every signal this project's rankers rely on (churn, complexity, recency) points the wrong
way on this specific repo shape.

**Suppression gate:** scoring the top-50 of a ranker's own output (not a random sample) and
checking precision there catches this failure directly and triggers a lightweight fallback
classifier. Across the repos tested, the gate fired exactly on the repo with the top-K
collapse and stayed quiet on the two repos where the ranker worked — no false positives.

**`co_change_partners` exclusion:** across 13 public repos, the sign of this coupling
feature's correlation with risk flips depending on how many files typically co-change in a
single commit (statistically significant relationship, r=−0.68). In repos where large,
sweeping commits are common, a file with many co-change partners is just "touched by big
commits," not specifically risky; in repos with sparse, targeted commits, the same feature
correctly flags genuinely central, risk-prone files. No clean universal threshold separates
the two regimes. Keeping this feature out of the trained ranker's default input set avoided
baking in a feature with no stable sign.

**Directed-coupling reliability screener:** on 5 public repos, whether "label stability"
(do the same files stay risky over time, or does that set rotate) correctly predicted
whether directed coupling would generalize from training data to held-out data:

| Repo | Label stability | Directed coupling held on holdout? |
|---|---:|---|
| gin-gonic/gin | high | yes |
| django/django | high | yes |
| svelte | low | no |
| facebook/react | low | no |
| scikit-learn/scikit-learn | high | **no** |

4 of 5 matched the screener's prediction. scikit-learn is the one exception, and it's not a
screener failure — it's the same repo, and the same underlying cause, as the top-K collapse
above: the screener correctly measures label stability, but can't rescue a repo where the
baseline activity signal itself is already anti-predictive. The practical rule that emerged
is a two-gate check, not one: screen for baseline signal quality first, then for label
stability.

## Caveats

- The repo screener's calibration set is 7 repos — promising, not yet a proven generalization
  as more repo types are added.
- The hardest-case repo's result is repo-shape-specific (mature, heavily-exercised core APIs
  vs. peripheral bugs); it is presented as a pattern likely to recur on similarly-shaped
  mature libraries, not a universal failure mode.
- `co_change_partners`'s sign-flip threshold is not sharp — the 13-repo sample is enough to
  show the effect is real and significant, not enough to fit a precise per-repo cutoff.

**Reproducibility:** Partial — the screener logic, the suppression gate's mechanics, and the
`co_change_partners` sign-flip are all measurable on public repo git history with no private
data; the specific precision numbers above were measured against this project's own labeled
fix-commit data, which isn't published.
