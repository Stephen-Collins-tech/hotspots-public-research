# F105 — The `rapid-growth` policy was removed

**Shipped as:** `rapid-growth` removed from the policy engine in hotspots 3.0 | **PR:**
[hotspots#323](https://github.com/Stephen-Collins-tech/hotspots/pull/323)

## What changed

`hotspots diff --policy` used to warn when a function's structural score grew by 50% or more.
That policy is removed. The two remaining policies are `critical-introduction` (a new function lands
in the critical band) and `excessive-risk-regression` (a function's score rises by 1.0 or more).

## What the evidence showed

F105 asked whether the flat 1.0 threshold in `excessive-risk-regression` was miscalibrated relative
to the 50% relative threshold `rapid-growth` used. On 1,200 sampled function modifications across
four repos, the two checks disagreed on only four of them. The pre-registered bar to test the
question was 20 disagreements, so the question could not be answered either way.

The useful part is the other direction. If two checks agree on 1,196 of 1,200 cases, one of them is
redundant. `rapid-growth` also fired as noise on small baselines: a one-line function that gains
one line grows by far more than 50% while changing almost nothing. In a run of 3.0 on its own
pull request it flagged a one-line method that gained one line.

## Limits

- This is a redundancy result, not evidence that either threshold is correctly calibrated. Neither
  threshold is validated, and `excessive-risk-regression` remains an uncalibrated gate.
- Four repos and a sample of modifications, not a full census.

## Reproducibility: Partial

Both thresholds are in the public source history, and `hotspots diff --policy` on 2.6.3 reports both
policies for any pair of commits, so you can count how often one fires without the other. The sampled
modification set used for the result above is not public.
