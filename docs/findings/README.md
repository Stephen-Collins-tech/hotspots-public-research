# Findings index

Every row here corresponds to a `promoted` row in the private research repo's promotion
tracker. See [`../promotion-policy.md`](../promotion-policy.md) for what makes a finding
eligible to appear here at all.

| ID | Title | Shipped as | hotspots PR | Reproducible |
|---|---|---|---|---|
| [F05](F05-independence-hypothesis.md) | Independence hypothesis | `hotspots analyze --axes` | [#162](https://github.com/Stephen-Collins-tech/hotspots/pull/162) | Yes |
| [F37-F39](F37-F39-directed-coupling.md) | Directed, recency-windowed coupling | `directed_coupling` trainer feature | [#85](https://github.com/Stephen-Collins-tech/hotspots/pull/85) | Yes |
| [F41](F41-c-language-support.md) | C language validation | tree-sitter-c parser | [#86](https://github.com/Stephen-Collins-tech/hotspots/pull/86) | Yes |
| [F54](F54-bug-commits-temporal-holdout.md) | Bug-commits temporal holdout | shipped at model_version 3, **removed** at model_version 6 (F168, ratchet effect) | REQ-002 / [#182](https://github.com/Stephen-Collins-tech/hotspots/pull/182) | No — feature no longer exists |
| [F55-explain](F55-explain-ranker.md) | Ranker score + explanation layer | `hotspots analyze --explain` | [#115](https://github.com/Stephen-Collins-tech/hotspots/pull/115) | Yes |
| [F07-F19-F22-F28](F07-F19-F22-F28-trained-ranker.md) | Trained tabular ranker (RandomForest) | `hotspots train` | [#79](https://github.com/Stephen-Collins-tech/hotspots/pull/79) | Partial |
| [F93](F93-osv-formula-refit.md) | OSV/CVE ground-truth formula refit | burst term weighting in `scoring.rs` | — | No |
| [F98](F98-cold-start-anomaly-score.md) | Low-label-density cold-start screener | IsolationForest screener | — | No |
| [F170](F170-risk-score-calibration.md) | File/module risk score calibration | `aggregates.rs` weights | [#213](https://github.com/Stephen-Collins-tech/hotspots/pull/213) | No |
| [F194](F194-risk-score-candidate-recall.md) | Risk-score ranking as a candidate filter | `file_risk_score` ranking, `aggregates.rs` | [#213](https://github.com/Stephen-Collins-tech/hotspots/pull/213) | Yes |
| [F206-F208-F209](F206-F208-F209-churn-blend.md) | Blending `file_risk_score` with true churn | opt-in `hotspots analyze --blend-churn`, 180-day churn window | [#295](https://github.com/Stephen-Collins-tech/hotspots/pull/295) | Yes |

More promoted findings exist in the private tracker (F08, F13, F24, F27, F31, F38, F61-F63,
F122, F136, F146, F155, F167, F168) and will be added here as they're rewritten. This index
only lists findings that have been written up so far — absence from this table doesn't mean
a finding was rejected, just that it hasn't been promoted to this public repo yet.
