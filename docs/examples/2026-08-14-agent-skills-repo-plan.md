# Build the agent-skills repo and migrate off stow

## Goal

`siraphobk/agent-skills` is an empty git repo. Done = it holds 16 skills that install
into Claude Code through a private plugin marketplace and into Cursor through
`./install.sh`, plus the validation and tests that keep them well-formed — and this
machine's `~/.claude/skills/` is switched over from a single folded stow symlink to
per-skill links pointing at the right repo. Implements the design at
`docs/design/2026-08-14-agent-skills-repo-design.md`.

## Non-goals

- **`remember` and `work-log`** — deliberately excluded; they stay in `dot-files`.
- **Themed bundles** — one plugin now. Splitting later changes only `marketplace.json`.
- **Migrating existing `.claude/scratch/` directories in other projects** — the rename
  applies to what the skills write from now on. A one-time `mv .claude/scratch
  .agents/scratch` per project is the user's call, outside this plan.
- **Preserving the imported skills' git history** — plain copy; history stays in `dot-files`.

## Acceptance criteria

- **AC-1** — `/plugin marketplace add siraphobk/agent-skills` then
  `/plugin install agent-skills@siraphobk` makes all 16 skills available in Claude Code.
- **AC-2** — `./install.sh --cursor` links all 16 skills into `~/.cursor/skills/`, skipping
  none.
- **AC-3** — no skill under `skills/` references a skill folder absent from `skills/`.
- **AC-4** — `scripts/validate.sh` exits non-zero when a skill's frontmatter `name` does
  not match its folder name.
- **AC-5** — `./install.sh --uninstall` removes only entries this repo created and leaves
  foreign entries in place.
- **AC-6** — `~/.claude/skills/` is a real directory holding 18 symlinks: 2 to `dot-files`,
  16 to `agent-skills`.
- **AC-7** — running `make stow-claude` in `dot-files` on a machine with no
  `~/.claude/skills` does not recreate the folded symlink.
- **AC-8** — CI runs shellcheck, `validate.sh`, and the bats suite on push and pull request.
- **AC-9** — no skill references a host-specific path (`~/.claude/`, `~/.cursor/`,
  `.claude/scratch/`, `.cursor/`) outside `skills/self-improve/AGENT-STRATEGIES.md`.
- **AC-10** — `self-improve` detects the running agent and follows that agent's section of
  `AGENT-STRATEGIES.md`; on Cursor, a user-level proposal produces paste-ready text and
  writes no file.

## Approach

The repo root doubles as the plugin, so the tree stays flat and `skills/` sits where a
human looks after cloning. The build order is deliberately validation-first:
`scripts/validate.sh` lands *before* the skill content fixes, so the known-broken
references to the dropped skills show up as a real failing check rather than a manual
to-do list. Same for `install.sh` — the bats suite goes in red first, because the
ownership rules are where a bug would delete someone's files.

The one tradeoff worth naming: the migration phases mutate a working config. They come
last, they're ordered so nothing is deleted before its replacement exists, and every one
is reversible with `rm -rf ~/.claude/skills && make stow-claude`.

**C-1 — the two manifests**

```
.claude-plugin/marketplace.json  (new)
.claude-plugin/plugin.json       (new)
```
**Change** — catalog names the marketplace `siraphobk` with one plugin entry
`agent-skills`, `source: "./"`. Identity file carries `version: "0.1.0"` and the repo URL.
No `skills` field in either — the default scan finds `skills/`, so adding a skill later
needs no manifest edit.

**C-2 — import the skills**

```
skills/<name>/  (new, 16 dirs, 31 files)
```
**Now** — all 18 skills live in
`/home/siraphob/Workspaces/dot-files/claude/.claude/skills/`.

**Change** — copy 16 of them (all but `remember` and `work-log`) into `skills/`,
preserving bundled files: `analyze-issue` (4 extra), `github-pr-review` (3),
`grill-with-docs` (2), `research-solutions` (2), `diagnose/scripts/hitl-loop.template.sh`,
`self-improve/EXAMPLES.md`, `write-handoff/TEMPLATE.md`, `write-plan/TEMPLATES.md`.

**C-3 — `scripts/validate.sh`**

```
scripts/validate.sh  (new)
```
**Change** — a malformed skill never errors, it just silently stops triggering, so each
check exits non-zero with the offending path. Checks: `SKILL.md` present; frontmatter
parses; `name` equals the folder name; `description` non-empty; relative links resolve;
**no reference to a skill folder absent from `skills/`**; **no host-specific path**
(`~/.claude/`, `~/.cursor/`, `.claude/scratch/`, `.cursor/`), which is the automated guard
for AC-9. The only exempt file is `skills/self-improve/AGENT-STRATEGIES.md`, whose whole job is
to name per-agent locations. Uses `jq` and `python3`, both present.

**C-4 — references to the dropped skills**

```
skills/self-improve/SKILL.md:3,64,78
skills/self-improve/EXAMPLES.md:20
skills/write-skill/SKILL.md:3,13,63
skills/execute-plan/SKILL.md:89
```
**Now** — `self-improve:64` hands its brain-fragment branch to `remember` ("it owns the
two-file protocol"), which is not in this repo, so the branch dead-ends. The rest are dead
pointers: `write-skill:13,63` uses `remember` as its worked example of a modes-based
skill, `execute-plan:89` names both dropped skills as next steps, and both `:3` description
lines carry "NOT for … (use `remember`)" routing clauses.

**Change** — make `self-improve:64,78` conditional (hand off if a memory skill is present,
otherwise inline the two-file protocol). Swap `write-skill`'s worked example to
`analyze-issue`, which is in the repo and also has modes. Drop the two names from
`execute-plan:89`, keeping the intent. Restate both description clauses as behaviour
without naming a skill.

**C-5 — make the state-owning skills agent-agnostic**

```
skills/write-handoff/SKILL.md:4,44,68
skills/read-handoff/SKILL.md:17,26
skills/self-improve/SKILL.md
skills/self-improve/AGENT-STRATEGIES.md  (new)
skills/research-solutions/SKILL.md
skills/write-skill/SKILL.md
```
**Now** — the handoff skills build their storage path with a live shell line,
`dir=~/.claude/projects/$(printf '%s' "$root" | sed 's#/#-#g')/handoffs`, at
`write-handoff:44` and `read-handoff:26`, with matching prose at `write-handoff:68` and
`read-handoff:17`. `self-improve` routes proposals to `~/.claude/CLAUDE.md`,
`~/.claude/rules/`, and `~/.claude/projects/<root>/memory/`.

**Change** — Cursor has no `~/.claude/projects/`, so there is nothing to remap to; the state
moves to a home neither tool owns. Swap both shell lines to
`dir=~/.agent-skills/$(printf '%s' "$root" | sed 's#/#-#g')/handoffs` and update the prose to
match, keeping handoffs outside the repo, which is why they were put there.

`self-improve` is a different shape — it does not just write to a different path per agent, it
*can do less* on Cursor. Cursor's User Rules live in the settings UI, not on disk, so there is
no writable user-level target at all; and Claude Code's `~/.claude/projects/<root>/memory/` is
a built-in that Claude Code auto-loads, so redirecting it to a neutral directory would stop it
being read. Both facts mean the branch must differ in behaviour, not only in path.

`SKILL.md` stays neutral: it ranks the lesson and picks a destination *class*. A bundled
`AGENT-STRATEGIES.md` holds one section per agent, and `SKILL.md` dispatches to it after
detecting the agent — `~/.claude` present and no `.cursor/` → Claude Code; `.cursor/` or
`~/.cursor` present → Cursor; both or neither → ask the user in one line.

| Destination class | Claude Code | Cursor |
|---|---|---|
| User-level style / workflow | write `~/.claude/CLAUDE.md` | no writable target — emit paste-ready text for `Customize → Rules` |
| Non-negotiable policy | write `~/.claude/rules/<topic>.md` | same as above |
| Repo-specific, team-shared | project `CLAUDE.md` / `AGENTS.md` | `AGENTS.md`, or `.cursor/rules/<topic>.mdc` with `alwaysApply: true` |
| Repo-specific, private | `~/.claude/projects/<root>/memory/` (built-in) | gitignored `.cursor/rules/<topic>.mdc` |
| Learned knowledge | brain fragment, conditional (see C-4) | `~/.agent-skills/<encoded-root>/memory/` |
| A repeatable procedure | `skills/<name>/SKILL.md` | `.cursor/skills/<name>/SKILL.md` |

For the two rows Cursor cannot write, the skill writes nothing and prints the exact block plus
where to paste it. It never writes a file Cursor will not read, and never silently downgrades a
global rule to a project-scoped one. `AGENT-STRATEGIES.md` is the one place host names are
allowed, and `validate.sh` exempts it by path.

`research-solutions` and `write-skill` only mention `~/.claude/CLAUDE.md` as one option in a
list — reword to "your agent's user-level instructions file" and cite `AGENT-STRATEGIES.md`.

No `metadata.agents` labels and no installer skip: with the three rewritten, every skill runs
on both agents, so the label would guard nothing.

**C-9 — move the scratch convention off a host name**

```
skills/analyze-issue/ (4)   skills/execute-plan/ (8)   skills/github-issue-write/ (7)
skills/github-pr-create/ (10)  skills/github-pr-review/ (2)  skills/research-solutions/ (2)
skills/run-and-report-tests/ (3)  skills/write-plan/ (6)  skills/write-skill/ (1)
```
**Now** — 43 occurrences of `.claude/scratch/` across 9 skills, over 8 subdirectories:
`plans`, `issue-analysis`, `draft-prs`, `draft-issues`, `deliverables`, `test-reports`,
`solution-research`, `reviews`. The path is project-relative so it *works* under Cursor, but
it names one vendor in every project it touches, and it is the convention the
`analyze-issue → write-plan → execute-plan → github-pr-create` chain hands off through.

**Change** — rename to `.agents/scratch/` throughout, keeping every subdirectory name. This
is mechanical, but the chain breaks if it is done partially, so it lands as one phase and
`validate.sh` enforces that no `.claude/scratch/` survives.

**C-6 — `install.sh`**

```
install.sh  (new)
```
**Change** — bash 3.2 compatible (no associative arrays, no `mapfile`) so macOS teammates
need no `brew install bash`. Targets `--claude` →
`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/`, `--cursor` → `$HOME/.cursor/skills/`,
`--agents` → `$HOME/.agents/skills/`; no target prints usage and exits 1. Symlinks by
default; `--copy` writes real files plus a `.installed-from` marker holding the repo path
and commit sha. Also `--list`, `--only`, `--exclude`, `--dry-run`, `--doctor`,
`--uninstall`, `--force`. Ownership: a symlink is ours if it resolves inside this repo's
`skills/`; a copy is ours if it carries the marker; anything else is reported `foreign` and
untouched. No per-agent filtering — after C-5 every skill runs on both agents, so each
target installs all 16.

**C-7 — bats suite**

```
tests/install.bats  (new)
tests/helpers.bash  (new)
```
**Change** — `install.sh` is branching logic, so it gets tests first. Each test sets `HOME`
to a `mktemp -d` so nothing touches real config. Covers: no-flag usage exit, each target,
`--only`/`--exclude`, symlink vs `--copy`, marker detection, refuse-to-clobber a foreign
dir, `--force` replacing it, all five `--doctor` states, and `--uninstall` sparing foreign
entries. `bats` is not installed — `brew install bats-core`.

**C-8 — dot-files fold guard**

```
/home/siraphob/Workspaces/dot-files/Makefile:29-30
```
**Now** — the target is `stow-claude:` / `stow -R claude -t ~`. Stow folds `skills` into one
symlink because `~/.claude/skills` doesn't exist.

**Change** — add `mkdir -p ~/.claude/skills` above the `stow` line. Stow only folds when the
target is absent, so pre-creating the real directory makes it link each skill separately —
permanently, and on a fresh machine too.

## Phased rollout

1. **[x] Phase 1 — repo scaffolding** (AC-1)
   **Files:** `.claude-plugin/marketplace.json` (new), `.claude-plugin/plugin.json` (new),
   `.gitignore` (new), `CLAUDE.md` (new)
   **Does:** apply C-1. `CLAUDE.md` documents how to add a skill to this repo: create
   `skills/<name>/SKILL.md`, `name` must equal the folder, run `scripts/validate.sh`.
   **Gate:** `jq empty .claude-plugin/marketplace.json .claude-plugin/plugin.json && echo ok`
   → prints `ok`

2. **[x] Phase 2 — import the 16 skills** (AC-1)
   **Files:** `skills/` (new — 16 directories, 31 files)
   **Does:** apply C-2, copying from
   `/home/siraphob/Workspaces/dot-files/claude/.claude/skills/`. Do not edit any content in
   this phase.
   **Don't touch:** the `dot-files` copies — they stay until Phase 11, so a failed import is
   a no-op.
   **Gate:** `ls -1 skills | wc -l` → `16`; `find skills -type f | wc -l` → `31`;
   `ls skills/remember skills/work-log 2>&1` → both "No such file"

3. **[x] Phase 3 — `validate.sh`, expected red** (AC-3, AC-4, AC-9)
   **Files:** `scripts/validate.sh` (new)
   **Does:** apply C-3.
   **Gate:** `scripts/validate.sh; echo "exit=$?"` → non-zero, reporting both failure
   classes: `skills/self-improve/SKILL.md` and `skills/write-skill/SKILL.md` reference
   `remember`, which is absent from `skills/`; and 9 skills carry `.claude/scratch/` paths.
   A pass here means the checks are not working.

4. **[x] Phase 4 — fix the dangling references** (AC-3)
   **Files:** `skills/self-improve/SKILL.md`, `skills/self-improve/EXAMPLES.md`,
   `skills/write-skill/SKILL.md`, `skills/execute-plan/SKILL.md`
   **Does:** apply C-4.
   **Don't touch:** the `.claude/scratch/` paths — Phase 7 renames them in one sweep, and
   splitting that across phases risks a partial rename.
   **Gate:** ``grep -rn '`remember`\|`work-log`' skills/`` → no matches
   (`validate.sh` still fails on host paths until Phase 7 — that is expected here)

5. **[x] Phase 5 — agent-agnostic state paths** (AC-2, AC-9)
   **Files:** `skills/write-handoff/SKILL.md:4,44,68`, `skills/read-handoff/SKILL.md:17,26`,
   `skills/research-solutions/SKILL.md`, `skills/write-skill/SKILL.md`
   **Does:** apply the path half of C-5. Both handoff shell lines become
   `dir=~/.agent-skills/$(printf '%s' "$root" | sed 's#/#-#g')/handoffs`, with the prose at
   `write-handoff:68` and `read-handoff:17` updated to match. Reword the two
   `~/.claude/CLAUDE.md` mentions to "your agent's user-level instructions file".
   **Don't touch:** `skills/self-improve/` — Phase 6 rewrites it, and it is the one skill
   whose host paths are legitimate.
   **Gate:** `grep -rln 'claude/projects' skills/` → only `skills/self-improve/SKILL.md`

6. **[x] Phase 6 — per-agent strategy for `self-improve`** (AC-9, AC-10)
   **Files:** `skills/self-improve/SKILL.md`, `skills/self-improve/EXAMPLES.md`,
   `skills/self-improve/AGENT-STRATEGIES.md` (new)
   **Does:** apply the `self-improve` half of C-5. `SKILL.md` keeps the ranking logic and the
   approval gate, drops every host path, adds the detection step (`~/.claude` present and no
   `.cursor/` → Claude Code; `.cursor/` or `~/.cursor` → Cursor; both or neither → ask), then
   dispatches to `AGENT-STRATEGIES.md`. That file carries the two agent sections and the
   six-row destination table from C-5, including the paste-ready fallback for the two rows
   Cursor cannot write. Update `EXAMPLES.md:20` so its routing column names a destination
   class, not a path.
   **Gate:** `grep -rn 'claude/projects\|~/\.claude\|~/\.cursor' skills/ | grep -v 'AGENT-STRATEGIES.md'`
   → no matches; `grep -c 'Claude Code\|Cursor' skills/self-improve/AGENT-STRATEGIES.md` →
   non-zero (both sections present)

7. **[x] Phase 7 — rename the scratch convention** (AC-9)
   **Files:** `skills/analyze-issue/`, `skills/execute-plan/`, `skills/github-issue-write/`,
   `skills/github-pr-create/`, `skills/github-pr-review/`, `skills/research-solutions/`,
   `skills/run-and-report-tests/`, `skills/write-plan/`, `skills/write-skill/`
   **Does:** apply C-9 — replace all 43 `.claude/scratch/` occurrences with
   `.agents/scratch/`, keeping every subdirectory name. Mechanical, but read each diff:
   the chain breaks if any one skill is missed.
   **Gate:** `grep -rn '\.claude/scratch' skills/ | wc -l` → `0`;
   `grep -rn '\.agents/scratch' skills/ | wc -l` → `43`;
   `scripts/validate.sh; echo "exit=$?"` → `exit=0` (first full green)

8. **[x] Phase 8 — bats suite, expected red** (AC-2, AC-5)
   **Files:** `tests/install.bats` (new), `tests/helpers.bash` (new)
   **Does:** apply C-7. Install the runner first: `brew install bats-core`.
   **Gate:** `bats tests/` → every test FAILS because `install.sh` does not exist yet (not a
   harness or syntax error)

9. **[x] Phase 9 — `install.sh`** (AC-2, AC-5)
   **Files:** `install.sh` (new)
   **Does:** apply C-6.
   **Gate:** `bats tests/` → all PASS; `shellcheck install.sh scripts/validate.sh` → no
   output

10. **[x] Phase 10 — README and CI** (AC-8)
   **Files:** `README.md` (new), `.github/workflows/ci.yml` (new)
   **Does:** README carries both install paths — the two `/plugin` lines for Claude Code,
   `./install.sh --cursor` for Cursor — plus the SSH-not-HTTPS note and
   `CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE=1`. CI installs bats and runs the three
   checks on push and pull request.
   **Gate:** `shellcheck install.sh scripts/*.sh && scripts/validate.sh && bats tests/` →
   all pass (the same three commands the workflow runs; `actionlint` is not installed, so
   YAML syntax is proven by the first CI run)

11. **[x] Phase 11 — remove the 16 from dot-files** (AC-6, AC-7)
   **Files:** `/home/siraphob/Workspaces/dot-files/claude/.claude/skills/` (16 dirs
   removed), `/home/siraphob/Workspaces/dot-files/Makefile:29-30`
   **Does:** `git rm -r` the 16 imported skill folders; apply C-8 to the `stow-claude`
   target. Commit is the user's call — stop and ask before running `git commit`.
   **Don't touch:** `remember` and `work-log` — they stay, and Phase 12 relinks them.
   **Gate:** `ls -1 ~/Workspaces/dot-files/claude/.claude/skills` → exactly `remember` and
   `work-log`; `grep -A2 '^stow-claude:' ~/Workspaces/dot-files/Makefile` → shows the
   `mkdir -p` line above `stow -R`

12. **[x] Phase 12 — unfold stow, install, adopt the new scratch path** (AC-6, AC-9)
    **Files:** `.claude/scratch/plans/2026-08-14-agent-skills-repo.md` → moved to
    `.agents/scratch/plans/2026-08-14-agent-skills-repo.md`; otherwise this phase changes
    `~/.claude/skills/` only
    **Does:** in `~/Workspaces/dot-files`: `stow -D claude -t ~`, then
    `mkdir -p ~/.claude/skills`, then `make stow-claude` — stow now descends into the real
    directory and links `remember` and `work-log` individually. Then in `agent-skills`:
    `./install.sh --claude`. **Last action, after the gate passes:** `mkdir -p
    .agents/scratch/plans && git mv` (or `mv`) this plan file into it, then
    `rmdir -p .claude/scratch/plans 2>/dev/null || true`. Until this moment the *installed*
    `execute-plan` is still the dot-files copy that reads `.claude/scratch/plans/`, which is
    why the move goes last.
    **Don't touch:** `~/.claude/CLAUDE.md`, `agents`, `brain`, `rules` — those stay folded
    symlinks; only `skills` unfolds.
    **Gate:** `ls -la ~/.claude/skills | grep -c '^l'` → `18`;
    `readlink ~/.claude/skills/remember` → a `dot-files` path;
    `readlink ~/.claude/skills/write-plan` → an `agent-skills` path;
    `./install.sh --doctor` → no `BROKEN` and no `foreign`

## Verification

- `scripts/validate.sh; echo "exit=$?"` → `exit=0` (AC-3, AC-9)
- `mkdir -p /tmp/vt/bad && printf -- '---\nname: wrong-name\ndescription: x\n---\n' > /tmp/vt/bad/SKILL.md`
  then point `validate.sh` at it → non-zero, naming the mismatch (AC-4)
- `bats tests/` → all PASS, including the foreign-entry and uninstall cases (AC-5)
- `shellcheck install.sh scripts/*.sh` → no output (AC-8)
- `./install.sh --cursor --dry-run` → plans 16 links, skips nothing (AC-2)
- `grep -rn '\.claude/scratch\|claude/projects\|~/\.cursor' skills/ | grep -v 'self-improve/AGENT-STRATEGIES.md'`
  → no matches (AC-9)
- (manual) run `self-improve` in this repo → it reports detecting Claude Code and routes a
  user-level proposal to `~/.claude/CLAUDE.md` (AC-10)
- (manual) re-run with a `.cursor/` directory present in the repo → it reports Cursor, writes
  no user-level file, and prints a paste-ready block naming `Customize → Rules` (AC-10)
- `ls -la ~/.claude/skills | grep -c '^l'` → `18` (AC-6)
- `rm -rf ~/.claude/skills && make -C ~/Workspaces/dot-files stow-claude && test -d ~/.claude/skills && ! test -L ~/.claude/skills && echo unfolded`
  → prints `unfolded`, then re-run `./install.sh --claude` to restore the 16 (AC-7)
- (manual) push the repo, then in a fresh Claude Code session run
  `/plugin marketplace add siraphobk/agent-skills` and
  `/plugin install agent-skills@siraphobk`; all 16 skills appear (AC-1, AC-8 — first CI run
  also proves the workflow YAML)

## Open questions

- Display name for `owner.name` and `author.name` in the manifests — currently `siraphobk`
  in both. (non-blocking)
- CI installs bats via `apt-get install -y bats` on `ubuntu-latest`, which is bats 1.x —
  confirm on the first run that the suite doesn't need a newer version. (non-blocking)
- Handoffs already written to `~/.claude/projects/<encoded-root>/handoffs/` are orphaned by
  the move to `~/.agent-skills/`. Move them, or let them age out? (non-blocking)
