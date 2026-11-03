# Quadrant replaced by an activity tier

**Shipped as:** `tier` (`active` or `quiet`) replacing `quadrant` (`fire`, `debt`, `watch`, `ok`) in
hotspots 3.0, snapshot schema 6 | **PR:**
[hotspots#323](https://github.com/Stephen-Collins-tech/hotspots/pull/323)

## What changed

A function used to be assigned one of four quadrants that combined two questions: is its code
complex (band critical or high), and is it being worked on (its file touched more often than the
repo median, or changed in the last 30 days). Triage was grouped by quadrant.

Now the two questions are separate fields. `band` says how complex the function is. `tier` says
whether it is active or quiet, using the same activity rule. Triage groups by tier. To get what
used to be "fire", select active functions in a high or critical band.

## What the evidence showed

Pre-registered, on 16 repos with enough history to measure (nine others were excluded for lacking
the history needed to count changes):

- `fire` was far above the repo base rate, in 16 of 16 repos. So the label separates well.
- But that separation is the activity rule's, not the complexity rule's. Against a selection of the
  same size made by activity alone, `fire` was **less** precise: a mean difference of −0.084
  (interval −0.163 to −0.013), with activity alone better in 14 of 16 repos. `watch` (active but not
  complex) scored almost the same as `fire`.
- High-complexity code that was not recently active still carried a higher fix rate than
  low-complexity inactive code in 13 of 15 repos, so complexity is not worthless. It is just not
  what makes the "fire" label work.

A broader replication on a larger set of repos agreed in direction.

So the complexity half of the quadrant added nothing to where later fixes landed, once activity was
accounted for. A label that implied otherwise was not supported, so it was replaced by one that
claims only what the evidence does.

## Limits

- The label follows activity mechanically, which favors the activity-only comparison. The result is
  that the complexity gate adds nothing on where fixes land, not that complexity never matters.
- Whether the high-complexity inactive group differs from the low-complexity inactive group could
  partly reflect function size, which this test did not control for.
- A trained-ranker clause that could also mark a function active was not tested, and was dropped
  from the rule in 3.0.

## Reproducibility: Partial

The rule itself is public and runnable: `hotspots analyze . --mode snapshot --format json` in 2.6.3
gives `quadrant`, and in 3.0 gives `band` and `tier`, so you can recompute either grouping. The
fix-rate comparison used a labelled set of repos that is not public.
