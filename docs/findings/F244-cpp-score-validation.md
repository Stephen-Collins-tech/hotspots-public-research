# F244 — Does the activity risk score work on C++?

**Shipped as:** C++ support (tree-sitter-cpp parser, per-function CFG) in hotspots 3.3 | **PRs:**
[hotspots#335](https://github.com/Stephen-Collins-tech/hotspots/pull/335) (C++ support),
[hotspots#340](https://github.com/Stephen-Collins-tech/hotspots/pull/340) (docs now state the checked result),
[hotspots#339](https://github.com/Stephen-Collins-tech/hotspots/pull/339) (a crash this check found)

## Claim

On eight C++ repositories, the shipped `activity_risk` score ranks files that later receive a bug fix
**well above chance** and **slightly better than structural complexity alone**. Almost all of that comes from the
git-activity terms: a ranking built only from churn, touch and recency does about as well. Absolute recall is low,
so treat the ranking as an ordering to read first, not a detector.

Before this check, the docs said the score had not been validated on C++. Support for C++ shipped in 3.3.0 with that
caveat, and the caveat was removed only after this result.

## Method

The design, repository list, labels, filters and decision rule were written down and merged before any C++ repository
was cloned for the study.

- **Snapshot.** For each repository, the last commit on the default branch on or before 2023-03-31.
- **Label.** A file is positive if a commit in the following 180 days that looks like a bug fix touched it. "Looks like a
  bug fix" is a commit-message rule (fix-style subjects and bodies, excluding plain refactors and reverts).
- **Candidates.** C and C++ source and header files the tool analyses, with the default test-file excludes.
- **Arms**, each scoring a file by the maximum over its functions: **B** the shipped `activity_risk`; **A** `lrs`
  alone (structure only); **C** the churn, touch and recency terms without structure; **R** a random ordering.
- **Metric.** recall@K with K = min(20, ⌈10% of files⌉); ties at the cutoff share credit.
- **Statistic.** Mean over repositories of the recall difference, with a 95% bootstrap interval over repositories
  (2,000 resamples).
- **Filter, applied before looking at scores.** A repository needed at least 50 candidate files, at least 10 positive
  files and at most 2% of functions skipped. Repositories that failed were dropped, not replaced; fewer than eight
  passing repositories would have made the study inconclusive.
- **Decision rule.** *Validated* only if B beats random (interval lower bound above 0) **and** B is non-inferior to
  A (lower bound above −0.03).

Sixteen well-known C++ projects were listed in advance. Ten passed the file and positive-file checks; of those, one
(Catch2) fell below ten positives after analysis. One (opencv) was dropped because the tool crashed on it (below).

## Result

| Repository | files | positives | K | B (score) | A (LRS) | C (activity only) | R (random) |
|---|---|---|---|---|---|---|---|
| abseil/abseil-cpp | 527 | 36 | 20 | 0.222 | 0.222 | 0.194 | 0.038 |
| facebook/rocksdb | 1,227 | 85 | 20 | 0.141 | 0.106 | 0.176 | 0.016 |
| bitcoin/bitcoin | 1,121 | 77 | 20 | 0.156 | 0.104 | 0.156 | 0.018 |
| duckdb/duckdb | 2,125 | 926 | 20 | 0.021 | 0.014 | 0.022 | 0.009 |
| grpc/grpc | 2,374 | 264 | 20 | 0.053 | 0.049 | 0.049 | 0.008 |
| protocolbuffers/protobuf | 952 | 89 | 20 | 0.146 | 0.101 | 0.135 | 0.021 |
| gabime/spdlog | 101 | 26 | 11 | 0.346 | 0.308 | 0.269 | 0.109 |
| ocornut/imgui | 52 | 17 | 6 | 0.353 | 0.294 | 0.353 | 0.115 |
| **mean (8)** | | | | **0.180** | 0.150 | 0.169 | 0.042 |

| Comparison | mean difference | 95% interval | wins / ties / losses |
|---|---|---|---|
| B − R (score vs random) | +0.138 | +0.084 … +0.189 | 8 / 0 / 0 |
| B − A (score vs structure only) | +0.030 | +0.016 … +0.044 | 7 / 1 / 0 |
| B − C (score vs activity only) | +0.010 | −0.008 … +0.033 | 4 / 2 / 2 |

**Verdict under the rule fixed in advance: validated.**

### Sensitivity: including opencv

The tool crashed on opencv at the snapshot (stack overflow on a generated 16,384-entry lookup table; fixed in
hotspots#339, released in 3.3.4), so the rule dropped it. Re-running with the fixed build and including it gives nine
repositories, the same verdict and the same ordering of arms (B − R +0.132, B − A +0.032). This is reported only to
show the crash did not decide the outcome.

## What this does and does not show

- **The activity terms carry the signal.** The score beats structure alone mainly because it includes git activity.
  The comparison with activity-only (+0.010, interval crossing zero) says complexity adds little on top of it for C++.
  This matches the pattern seen on other languages in
  [What the activity risk score is built from](activity-risk-formula.md). That comparison was reported but not a
  pre-registered test.
- **Absolute recall is low.** At K = 20, recall is 2% on duckdb (926 positive files) and 5% on grpc, 9–22% on most
  other repositories; only the two smallest repositories reach about 35%. It is a useful ordering, not a detector.
- **Eight repositories chosen by popularity.** Projects with a "fix" commit convention are over-represented, and
  the formula's constants were not tuned on these labels but these repositories are not a fresh sample of C++.
- **Noisy labels.** Commit-message bug-fix labels are a known-imperfect proxy for defects; noise affects every arm alike.
- **File-level only.** The test cannot see function-level ranking quality.
- **Macros and header-only code.** Skipped-function rates were at or below 0.05% on every included repository, but
  macro-heavy code that the parser mis-reads can still produce plausible functions that were not measured here.

## Reproducibility: Partial

Everything needed except one piece is public: the repositories, the snapshot commits, the released CLI (3.3.3 for
the registered run) and the invocation `hotspots analyze . --mode snapshot --format json --all-functions --no-persist`
at each snapshot. The commit-message bug-fix rule is described above in words but lives in a private script, so an
independent rerun would need to reimplement it; small differences in that rule will move individual numbers, not the
ordering of the arms.
