# Reproduction scripts

Each script under `scripts/findings/<id>.sh` runs the `hotspots` commands a finding's doc
describes against a public repo you point it at. They don't assert pass/fail against the
original research numbers (those were measured on a specific 17-repo corpus) — they print
`hotspots` output so you can confirm the *feature* behaves as described.

## Requirements

- `hotspots` CLI installed and on `PATH`: `curl -fsSL https://raw.githubusercontent.com/Stephen-Collins-tech/hotspots/main/install.sh | sh`
- A local clone of any public git repo to point the script at

## Usage

```bash
scripts/reproduce.sh <finding-id> <path-to-a-git-repo>
# e.g.
scripts/reproduce.sh F41 ~/code/redis
```
