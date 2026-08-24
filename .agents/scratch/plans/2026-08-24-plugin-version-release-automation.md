# Bump the plugin version from the published GitHub Release

## Goal

`.claude-plugin/plugin.json:4` is the only place this repo's version lives, and
nothing keeps it in step with what gets released — `v0.1.1` shipped with the
manifest still reading `0.1.0`, so the marketplace kept advertising `0.1.0` and
installed users stayed pinned there. Done looks like: publishing a GitHub
Release by hand is the only manual step, and a workflow reads that release's tag
and pushes the matching version to `.claude-plugin/plugin.json` on `main` on its
own. A second CI job guards the manifests on every PR, closing the gap that let
the drift ship in the first place.

## Non-goals

- **No release on merge to `main`.** Releases batch several merged PRs; when to
  cut one is a human call.
- **No `release-please`, `semantic-release`, or CHANGELOG.** One version field
  and a solo maintainer don't justify a bot-PR flow.
- **No deriving the version from commit messages.** The tag typed when
  publishing is the input; nothing guesses.
- **No PR-time version-bump guard.** With the bump automated at release time, a
  PR that changes skills without touching the version is correct, not a mistake.
- **Existing `v0.1.0` / `v0.1.1` tags and releases stay.** Deleting published
  releases breaks links for no gain.

## Acceptance criteria

- **AC-1** — `scripts/version.sh` prints the version in `plugin.json`, and
  `scripts/version.sh --parse-tag <tag>` maps `v0.2.0`, `0.2.0`, and
  `agent-skills--v0.2.0` all to `0.2.0` while rejecting anything else.
- **AC-2** — Publishing a GitHub Release tagged `v0.2.0` pushes one commit to
  `main` setting `.claude-plugin/plugin.json` to `0.2.0`, with no manual step.
- **AC-3** — Re-running that workflow when `main` already carries the release's
  version exits 0 and pushes nothing.
- **AC-4** — A release tagged at or below the current version fails the run and
  leaves `main` untouched.
- **AC-5** — A release with a non-semver tag fails the run and leaves `main`
  untouched.
- **AC-6** — `claude plugin validate . --strict` exits 0.
- **AC-7** — A PR carrying a malformed or incoherent `.claude-plugin/*.json`
  fails CI.

## Approach

One script owns every version string; one workflow calls it. `scripts/version.sh`
reads, parses, and writes the version — the same one-reader trick
`scripts/validate.sh:18` already uses for frontmatter ("so the two can never
disagree"). Keeping the write in a shellcheck'd, bats-tested script rather than
inline YAML means the tricky part is testable on a laptop instead of only
observable after a bad release.

Three properties worth stating up front. **The workflow checks out `main`, not
the release tag** — on a `release` event the default checkout ref is the tag, and
committing there would go nowhere, so the bump always lands on `main`'s tip,
which is what the marketplace resolves from. **The release tag points at the
commit before the bump**, because the tag exists the moment Publish is clicked;
this costs nothing here since the plugin entry is `"source": "./"` and Claude
Code reads the version from `plugin.json` on the default branch, never from a
tag. **The bump commit will not trigger `ci.yml`**: GitHub suppresses workflow
runs for pushes made with `GITHUB_TOKEN`, which is what stops a release workflow
from re-triggering itself.

That last property was checked rather than worked around. Nothing in the current
CI reads the plugin manifests — `scripts/validate.sh` operates on `SKILLS_DIR`
(line 13, default `skills`), and neither it nor `install.sh` nor `tests/*.bats`
mentions `plugin.json` or `marketplace.json`. So a full CI run on a one-line
manifest edit is structurally incapable of failing, and a PAT to force one would
buy nothing for the cost of a secret to hold and rotate. The check that actually
covers the change is `claude plugin validate --strict`, which needs no
authentication (verified under `env -i` with an empty `HOME`: exit 0 with
warnings, exit 1 under `--strict`). It runs inline in the release workflow before
the push, and in a new CI job on every PR.

The tag format is parsed permissively — `v0.2.0`, `0.2.0`, and
`agent-skills--v0.2.0` all yield `0.2.0` — so the workflow doesn't break the day
the convention changes, and typing the wrong prefix isn't a failed release.

**C-1 — marketplace has no description**

```
.claude-plugin/marketplace.json:1-15
```
**Now** — the marketplace object has `name`, `owner`, and `plugins`, but no
top-level `description`. `claude plugin validate . --strict` exits 1 on it
today: "No marketplace description provided." Plain `validate` exits 0.

**Change** — add a top-level `"description"` key after `"name"` on line 2,
echoing the plugin entry's wording on line 11. Makes `--strict` usable as the
release workflow's pre-push gate and as the new CI job's check.

**C-2 — no version reader or writer**

```
scripts/version.sh  (new)
```
**Change** — new bash script in the style of `scripts/validate.sh`:
`set -euo pipefail`, a header comment giving the usage and the why, bash 3.2 only
(no associative arrays, no `mapfile`), and no `jq` — the repo's scripts carry
zero JSON tooling and shouldn't gain a dependency for a flat hand-written file.
Extract with `grep`/`sed` on the `"version": "..."` line and fail loudly unless
exactly one line matches, so a reformatted manifest is an error rather than a
silent empty string.

Three modes:

- `scripts/version.sh` — prints `0.1.2`
- `scripts/version.sh --parse-tag <tag>` — strips a leading `agent-skills--v` or
  `v`, prints the rest, exits 1 unless it matches
  `^[0-9]+\.[0-9]+\.[0-9]+([-+].*)?$`
- `scripts/version.sh --set <version>` — rewrites `.claude-plugin/plugin.json`
  in place

`--set` carries the ordering rules, so all version logic sits in one tested
place:

- equal to the current version — print a no-op note, exit 0 (this is what makes
  a re-run harmless)
- lower than current — exit 1 naming both versions
- higher — rewrite the line, print old and new

Ordering uses `sort -V`, which is why `--set` is documented as CI-only; the read
and parse modes stay portable to stock macOS.

**C-3 — nothing reacts to a published release**

```
.github/workflows/release.yml  (new)
```
**Change** — `on: release: types: [published]`, so it fires on the manual
Publish and not on drafts. `permissions: contents: write` — the repo default is
`read`, and the job pushes a commit.

Steps, in order: checkout with `ref: main` and `fetch-depth: 0`;
`VERSION=$(scripts/version.sh --parse-tag "${{ github.event.release.tag_name }}")`;
`scripts/version.sh --set "$VERSION"`; exit 0 early if `git diff --quiet` shows
no change (AC-3); install Claude Code with `npm i -g @anthropic-ai/claude-code`
and run `claude plugin validate . --strict` as the check this commit's skipped
CI run would not have provided anyway; then commit as
`chore: set plugin version to <version>` and push to `main`.

**C-4 — manifests unguarded in CI**

```
.github/workflows/ci.yml:10-17
```
**Now** — one `check` job over an ubuntu + macOS matrix. Nothing it runs reads
`.claude-plugin/plugin.json` or `marketplace.json`, so a malformed or incoherent
manifest reaches `main` unchallenged. This is the same gap that let the version
drift ship.

**Change** — add a second job `manifest`, single `ubuntu-latest` runner (not a
step in the matrix — no reason to validate twice). Installs Claude Code, then
runs `claude plugin validate . --strict`.

**C-5 — the release flow is undocumented**

```
CLAUDE.md
```
**Now** — CLAUDE.md documents adding a skill and the check commands, with no
mention of versioning or releasing.

**Change** — add a short `## Releasing` section after `## Checks`: merge what
you want to ship, then publish a GitHub Release with a `vX.Y.Z` tag; the version
commit appears on `main` within a minute. Name the two silent failures — a
version that never moves leaves installed users pinned to the old one, and the
bump commit deliberately skips `ci.yml`, so anything the release workflow
doesn't check isn't checked.

## Phased rollout

1. **[x] Phase 1 — give the marketplace a description** (AC-6)
   **Files:** `.claude-plugin/marketplace.json:1-15`
   **Does:** apply C-1 — add a top-level `"description"` after `"name"` on line 2.
   **Don't touch:** the `plugins[0]` entry — its `description` on line 11 is a
   separate field, and `claude plugin tag` reads that entry when checking version
   agreement.
   **Gate:** `claude plugin validate . --strict; echo $?` → `0` (it is `1` before this phase)

2. **[x] Phase 2 — add the version reader and writer** (AC-1, AC-4, AC-5)
   **Files:** `scripts/version.sh` (new), `tests/version.bats` (new)
   **Does:** apply C-2. Tests must prove each failure fires, per the repo rule in
   CLAUDE.md that a check without a test that breaks it is indistinguishable from
   a dead check: a manifest with no `version` line exits non-zero,
   `--parse-tag release-2024` exits 1, `--set` with a lower version exits 1 and
   leaves the file byte-identical, `--set` with the same version exits 0 and
   writes nothing, `--set` with a higher version rewrites only line 4.
   **Don't touch:** `scripts/validate.sh` and `scripts/frontmatter.sh` —
   `version.sh` is standalone and nothing sources it.
   **Gate:** `shellcheck -x scripts/version.sh && bats tests/version.bats && scripts/version.sh` → lint clean, tests pass, prints `0.1.2`

3. **[x] Phase 3 — bump on published release** (AC-2, AC-3)
   **Files:** `.github/workflows/release.yml` (new)
   **Does:** apply C-3.
   **Don't touch:** `.github/workflows/ci.yml` — release stays a separate
   workflow so a red release run never masks a red test run.
   **Gate:** `python3 -c "import yaml,sys; d=yaml.safe_load(open('.github/workflows/release.yml')); assert d[True]['release']['types']==['published']; assert d['permissions']['contents']=='write'; print('ok')"` → prints `ok`

4. **[x] Phase 4 — guard the manifests on every PR** (AC-7)
   **Files:** `.github/workflows/ci.yml:10-17`
   **Does:** apply C-4 — add the `manifest` job.
   **Don't touch:** the `check` job, including the macOS bash 3.2 step at lines
   44-58 — manifest validation is Linux-only and must not join the matrix.
   **Gate:** `python3 -c "import yaml; d=yaml.safe_load(open('.github/workflows/ci.yml')); assert set(d['jobs'])=={'check','manifest'}; assert d['jobs']['manifest']['runs-on']=='ubuntu-latest'; print('ok')"` → prints `ok`

5. **[x] Phase 5 — document the release flow** (AC-2)
   **Files:** `CLAUDE.md`
   **Does:** apply C-5 — add the `## Releasing` section after `## Checks`.
   **Gate:** `scripts/validate.sh` → exits 0 (CLAUDE.md sits outside `skills/`,
   so this confirms the edit broke nothing)

## Verification

- `claude plugin validate . --strict; echo $?` → `0` (AC-6, AC-7)
- `scripts/version.sh` → `0.1.2` (AC-1)
- `for t in v0.2.0 0.2.0 agent-skills--v0.2.0; do scripts/version.sh --parse-tag "$t"; done` → `0.2.0` three times (AC-1)
- `scripts/version.sh --parse-tag nightly; echo $?` → `1` (AC-1, AC-5)
- `bats tests/` → all pass, including `tests/version.bats` (AC-1, AC-3, AC-4, AC-5)
- `shellcheck -x install.sh scripts/*.sh tests/helpers.bash` → clean (AC-1)
- `scripts/validate.sh` → exits 0
- `grep -rn '"version"' .github/workflows/ scripts/ | grep -v version.sh` → no hits; only `version.sh` reads or writes the field (AC-1)
- (manual) Publish a pre-release tagged `v0.1.3-test`, wait for the run, then `git fetch && git show origin/main:.claude-plugin/plugin.json` → version reads `0.1.3-test` (AC-2)
- (manual) Re-run that workflow from the Actions tab → succeeds, and `git rev-parse origin/main` is unchanged from before the re-run (AC-3)
- (manual) Publish a pre-release tagged `v0.0.1` → the run fails naming both versions, and `git rev-parse origin/main` is unchanged (AC-4)
