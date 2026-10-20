# F41 — C language validation

**Shipped as:** tree-sitter-c parser, function-based extraction | **PR:** [hotspots#86](https://github.com/Stephen-Collins-tech/hotspots/pull/86) (same-day revert+reapply; docs follow-up [#92](https://github.com/Stephen-Collins-tech/hotspots/pull/92))

## Claim

Before this finding, hotspots only parsed TypeScript/JavaScript/Go/Java/Python/Rust. The
question was whether the activity-risk composite generalizes to a structurally different,
non-OO language with manual memory management — validated against Redis (C), where the
activity term alone reached rho +0.878, P@10 = 1.000 against the research corpus's labels.

## What shipped

`Language::C` / `Language::CHeader` in `hotspots-core`, using `tree-sitter-c` for parsing
and function-based (not class-based) extraction in `metrics.rs`. Import resolution and
struct/typedef model detection are explicitly not implemented for C (see
`hotspots-core/src/imports.rs`, `hotspots-core/src/models.rs`) — only function-level
complexity/activity scoring is supported.

## Reproduce

```bash
scripts/findings/F41.sh /path/to/a/local/clone/of/redis
```

which runs:

```bash
hotspots analyze /path/to/redis --mode snapshot --format json --all-functions --no-persist \
  | jq '[.functions[] | select(.language == "C")][0:5]'
```

Confirms the CLI parses `.c`/`.h` files and produces per-function LRS/activity scores —
this reproduces that the *feature* works, not the original rho/P@10 numbers (those were
measured against the private labeled corpus's bug-commit history for Redis specifically).
