# Working in this repo

This repo holds agent skills that run in **both Claude Code and Cursor**. One
`skills/<name>/` folder serves both — there is no build step and no second copy.

## Adding a skill

1. Create `skills/<name>/SKILL.md`.
2. Frontmatter needs `name`, `description`, and `allowed-tools`. **`name` must exactly
   match the folder name** — Cursor rejects the skill outright if it doesn't.
3. Bundle extra files beside it: `references/`, `scripts/`, `assets/`, or plain `.md`
   files in the skill folder. A skill that bundles files needs `Read` in `allowed-tools`,
   or the agent is told to open something it may not open.
4. Keep `SKILL.md` under 150 lines and `description` under 1024 characters. Both are
   silent failures when broken: an over-long description is truncated, and the tail is
   the `NOT for X` boundary that stops two skills fighting over the same request.
5. Run `scripts/validate.sh`. It must exit 0.

Nothing else to register. Both manifests scan `skills/` by default, so a new folder is
picked up with no edit to `.claude-plugin/`.

## Rules that keep skills agent-agnostic

`scripts/validate.sh` enforces all of these, so a violation fails CI rather than shipping
quietly.

- **No host-specific paths.** Never write `~/.claude/`, `~/.cursor/`, `.claude/scratch/`,
  or `.cursor/` in a skill. The exempt files are the `AGENT-STRATEGIES.md` in
  `skills/self-improve/` and `skills/where-am-i/`, whose job is to name per-agent
  locations. Exemption is by full path, listed in `HOST_PATH_EXEMPT` in `validate.sh` —
  the filename alone buys nothing, so a new one is a deliberate edit plus a test.
- **Shared scratch lives at `.agents/scratch/`.** Project-relative, so both agents write
  there. Subdirectories in use: `plans`, `deliverables`, `issue-analysis`, `draft-prs`,
  `draft-issues`, `test-reports`, `solution-research`, `reviews`.
- **Out-of-repo state lives at `~/.agent-skills/<encoded-repo-root>/`.** Encode the root
  by replacing `/` with `-`. Used for handoffs and per-project memory.
- **A skill never hardcodes its own install path.** It may sit in `~/.claude/skills/`,
  `~/.cursor/skills/`, or `~/.agents/skills/`. Reference bundled scripts relative to the
  skill folder, never by absolute path.
- **Never reference a skill that isn't in `skills/`.** A pointer to a skill the reader
  can't install is a dead end. `remember` and `work-log` live in a separate dot-files
  repo and must not be named as handoff targets.

## When a skill genuinely differs per agent

Some behaviour can't be made neutral — Cursor has no writable user-level rules file, and
Claude Code's `~/.claude/projects/<root>/memory/` is a built-in that only it reads. In
that case keep `SKILL.md` neutral (decide *what class* of thing to do), and put the
per-agent specifics in a bundled `AGENT-STRATEGIES.md` that `SKILL.md` dispatches to
after detecting the agent. `skills/self-improve/` is the worked example.

## Checks

```sh
scripts/validate.sh                                  # skill well-formedness
claude plugin validate . --strict                    # plugin + marketplace manifests
shellcheck -x install.sh scripts/*.sh tests/helpers.bash   # shell lint
bats tests/                                          # install.sh, validate.sh, version.sh
```

`tests/validate.bats` proves every check in `validate.sh` *fires* on bad input, not just
that good input passes — a suite that only does the latter cannot tell a working check
from a dead one. When you add a check, add the test that breaks it.

`install.sh` targets bash 3.2 so it runs on stock macOS — no associative arrays, no
`mapfile`.

## Releasing

Merge everything you want to ship, then publish a GitHub Release with a `vX.Y.Z` tag. The
`release` workflow reads that tag, writes the version into `.claude-plugin/plugin.json`, and
pushes the commit to `main` on its own — that is the only place the version lives, and the
only thing that should ever write it is `scripts/version.sh`.

Two things fail silently if you work around this:

- **A version that never moves keeps installed users on the old copy.** Claude Code pins a
  plugin to the version string in `plugin.json` and only offers an update when it changes, so
  shipping new skills under an unchanged version means nobody receives them.
- **The bump commit does not run `ci.yml`.** GitHub suppresses workflow runs for pushes made
  with `GITHUB_TOKEN`, which is what keeps the release workflow from re-triggering itself. The
  workflow runs `claude plugin validate . --strict` itself to cover the change it makes.

The workflow refuses a tag that is not a version and a version below the one already there,
and does nothing at all if the manifest already matches — so a re-run is always safe.
