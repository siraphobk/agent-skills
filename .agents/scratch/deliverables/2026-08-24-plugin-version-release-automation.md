# Delivered — Bump the plugin version from the published GitHub Release

Plan: `.agents/scratch/plans/2026-08-24-plugin-version-release-automation.md`
Branch: `chore/release_version_automation`

## Summary

- `.claude-plugin/plugin.json` is now the only place the version lives, and `scripts/version.sh` is the only thing that reads or writes it. Publishing a GitHub Release is the single manual step; a new `release` workflow reads the tag and pushes the matching version to `main`.
- The release workflow refuses a non-version tag and a version below the one already there, and is a no-op when the manifest already matches — so re-running it is always safe.
- A new `manifest` job in `ci.yml` runs `claude plugin validate . --strict` on every PR. Nothing in CI read `.claude-plugin/*.json` before, which is the gap that let v0.1.1 ship advertising 0.1.0.
- The version is bumped to `0.1.2` in this branch. That is the last manual bump; from the next release on, the workflow writes it.

## Acceptance criteria

- AC-1 met — `scripts/version.sh` → `0.1.2`; `--parse-tag` over `v0.2.0`, `0.2.0`, `agent-skills--v0.2.0` → `0.2.0` each; `--parse-tag nightly` → exit 1. 77/77 bats pass.
- AC-2 **script level only** — `--parse-tag v0.2.0 | --set` moved a fixture manifest `0.1.2 -> 0.2.0`. The workflow wiring (checkout `ref: main`, the `GITHUB_TOKEN` push) cannot be exercised until a Release is actually published.
- AC-3 **script level only** — a second `--set 0.2.0` printed "already at 0.2.0, nothing to write" and exited 0, so the workflow's `changed=false` branch skips the push. Same caveat as AC-2.
- AC-4 **script level only** — `--set 0.0.1` against `0.2.0` exited 1 ("refusing to move the version backwards") and left the manifest at `0.2.0`. Same caveat as AC-2.
- AC-5 met — `--parse-tag nightly` exits 1 before anything is written, so the workflow fails at its first step with the manifest untouched.
- AC-6 met — `claude plugin validate . --strict` → exit 0 (it was exit 1 before Phase 1).
- AC-7 **not yet proved** — the `manifest` job exists and is well-formed, but it has never run. The PR opened from this branch is its first execution.

## Changes by phase

### [x] Phase 1 — give the marketplace a description
Files: `.claude-plugin/marketplace.json`
Gate: `claude plugin validate . --strict` → exit 0 ("Validation passed"); exited 1 before the change.

### [x] Phase 2 — add the version reader and writer
Files: `scripts/version.sh` (new), `tests/version.bats` (new)
Gate: `shellcheck -x scripts/version.sh` clean; `bats tests/version.bats` → 15/15 ok; `scripts/version.sh` → `0.1.2`.

### [x] Phase 3 — bump on published release
Files: `.github/workflows/release.yml` (new)
Gate: parsed the workflow and asserted `on.release.types == [published]`, `permissions.contents == write`, and `checkout.with.ref == main` → `ok`.

### [x] Phase 4 — guard the manifests on every PR
Files: `.github/workflows/ci.yml`
Gate: parsed the workflow and asserted jobs are exactly `{check, manifest}`, `manifest` runs on `ubuntu-latest` with no `strategy`, and `check` keeps its ubuntu+macOS matrix → `ok`.

### [x] Phase 5 — document the release flow
Files: `CLAUDE.md`
Gate: `scripts/validate.sh` → exit 0. Also folded `claude plugin validate . --strict` into the Checks block and corrected its `bats` comment, which still named only install.sh and validate.sh.

## Deviations from the plan

- Phase 2: the plan specified `sort -V` for version ordering and documented `--set` as CI-only because of it. Implemented a pure-bash numeric compare instead (`compare_core`), so `--set` is portable to stock macOS and its ordering rules are testable there — the CI-only caveat is dropped.

## Not done / follow-ups

- **AC-2, AC-3, AC-4 need a real release to close.** They are proved at the script level only. The first real check is publishing a Release after this merges; the plan's `(manual)` verification lines describe exactly what to watch.
- **AC-7 closes when CI runs on this PR.** If the `manifest` job goes red on the `npm install -g @anthropic-ai/claude-code` step, the fallback is a plain JSON parse — that catches a mangled manifest but not a `plugin.json` / marketplace-entry version disagreement.
- **The existing `v0.1.0` and `v0.1.1` tags stay as they are**, per the plan's non-goals. They do not match the `agent-skills--v<version>` form `claude plugin tag` and Claude Code's dependency resolver use, which only matters if another plugin ever declares a version-ranged dependency on this one.

## Verification output

```
claude plugin validate . --strict            exit 0
scripts/version.sh                           0.1.2
--parse-tag v0.2.0 / 0.2.0 / agent-skills--v0.2.0   0.2.0, 0.2.0, 0.2.0
--parse-tag nightly                          exit 1
bats tests/                                  77 ok, 0 not ok
shellcheck -x install.sh scripts/*.sh tests/helpers.bash   clean
scripts/validate.sh                          exit 0
grep '"version"' .github/workflows/ scripts/ (excluding version.sh)   no hits
```

Release-workflow logic, simulated against a fixture manifest:

```
--parse-tag v0.2.0 -> --set   version.sh: 0.1.2 -> 0.2.0
re-run same version           version.sh: already at 0.2.0, nothing to write   exit 0
--set 0.0.1                   refusing to move the version backwards           exit 1, manifest 0.2.0
--parse-tag nightly           does not name a semver version                   exit 1, manifest 0.2.0
```
