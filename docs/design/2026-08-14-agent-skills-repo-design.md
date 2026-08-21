# agent-skills — repository design

> **SUMMARY**: One `skills/` tree in a private personal repo serves both Claude Code
> (as a plugin marketplace) and Cursor (via a Bash installer), so a skill is authored
> once and installed three ways with no build step and no second copy.

- **Date:** 2026-08-14
- **Repo:** `github.com/siraphobk/agent-skills` — private, collaborators added individually
- **Status:** implemented. This document records the design as approved and is not
  updated as the repo evolves — `README.md` and `CLAUDE.md` describe the current state.
  Skill names and counts below are as of the design, not as of today.

## 1. What this is

A home for the agent skills I actually use day to day. It is my setup, published so
teammates can opt into it — not a team-owned standard. Anyone who installs `write-plan`
is opting into `.agents/scratch/plans/` and the rest of my conventions; that is the
point, not a rough edge.

Two agents are supported: **Claude Code** and **Cursor**.

### Non-goals

- Not a public marketplace. Access is by collaborator invite.
- Not a format-conversion tool. Both agents read the same `SKILL.md`; nothing is generated.
- Not the home for every skill I have. `remember` and `work-log` stay in `dot-files`.

## 2. Why one tree works for both agents

Cursor 2.4+ implements the same Agent Skills format as Claude Code. It discovers skills in
`.cursor/skills/`, `.agents/skills/`, `~/.cursor/skills/`, `~/.agents/skills/`, and reads
`.claude/skills/` as a compatibility path. Required frontmatter is `name` (must match the
folder name) and `description`; `paths`, `disable-model-invocation`, and `metadata` are
optional. Bundled `scripts/`, `references/`, and `assets/` are supported.

**So there is no conversion step.** A skill folder is valid for both tools as-is. The only
differences are packaging and install destination.

```
                    skills/<name>/SKILL.md          <- ONE source of truth
                    skills/<name>/references/...
                            |
        +-------------------+--------------------+
        |                                        |
   Claude Code                                Cursor
   .claude-plugin/marketplace.json          no registry exists
   + .claude-plugin/plugin.json             install = folder in
   /plugin marketplace add ...                ~/.cursor/skills/
   /plugin install ...                      -> install.sh does this
```

**Format portability is not content portability.** Three skills read or write Claude Code
directories that have no Cursor equivalent. Section 6 covers how that is handled.

## 3. Repository layout

The repo root **is** the plugin. With `source: "./"` in the catalog, Claude Code treats the
repo root as the plugin root and scans `skills/` there by default. There is exactly one
plugin, so a `plugins/<name>/` nesting level would buy nothing and would bury `skills/`
below where a human looks after cloning.

```
agent-skills/
├── .claude-plugin/
│   ├── marketplace.json           catalog: one entry, source "./"
│   └── plugin.json                plugin identity + version
├── skills/                        <- SOURCE OF TRUTH (16 skills)
│   ├── analyze-issue/
│   │   ├── SKILL.md
│   │   ├── BUG_TEMPLATES.md
│   │   ├── FEATURE_TEMPLATES.md
│   │   ├── TEMPLATES.md
│   │   └── CHECKLIST.md
│   ├── diagnose/
│   │   ├── SKILL.md
│   │   └── scripts/hitl-loop.template.sh
│   └── ... 14 more
├── install.sh                     Cursor + plain-clone installer
├── scripts/
│   └── validate.sh                CI check
├── .github/workflows/ci.yml       shellcheck + validate + bats
├── tests/                         bats-core tests for install.sh
├── README.md                      install docs
└── CLAUDE.md                      how to add a skill to THIS repo
```

Three ways in, one tree:

```
       skills/
          |
    +-----+------------------+------------------------+
    |                        |                        |
 marketplace              plain clone              CLI install
 /plugin marketplace add  git clone, point         ./install.sh --cursor
   siraphobk/agent-skills   your tool at             -> symlinks into
 /plugin install            skills/ by hand            ~/.cursor/skills/
   agent-skills@siraphobk
```

## 4. The two manifests

`marketplace.json` is the catalog; `plugin.json` is the identity. Splitting them keeps the
version with the plugin, and if this is ever split into themed bundles, only the catalog
changes.

```jsonc
// .claude-plugin/marketplace.json
{
  "name": "siraphobk",
  "owner": { "name": "siraphobk" },   // swap for your display name if you want one
  "plugins": [
    {
      "name": "agent-skills",
      "source": "./",
      "description": "Planning, diagnosis, GitHub and review workflows",
      "category": "workflow"
    }
  ]
}
```

```jsonc
// .claude-plugin/plugin.json
{
  "name": "agent-skills",
  "description": "Planning, diagnosis, GitHub and review workflows for Claude Code and Cursor",
  "version": "0.1.0",
  "author": { "name": "siraphobk" },  // swap for your display name if you want one
  "repository": "https://github.com/siraphobk/agent-skills",
  "keywords": ["planning", "debugging", "github", "code-review", "cursor"]
}
```

**No `skills` field.** The default scan picks up `skills/` under the plugin root, so adding
a skill means adding a folder — no manifest edit to forget.

Teammate install:

```
/plugin marketplace add siraphobk/agent-skills
/plugin install agent-skills@siraphobk
```

**Rejected:** `strict: false` would let `plugin.json` be deleted and everything defined in the
catalog entry — one file instead of two. Skipped, because the plugin would then have no
identity of its own and could only ever be installed through this marketplace.

### Private-repo mechanics

- `/plugin marketplace add` and `/plugin install` use the teammate's existing git credentials.
- **Use SSH.** Background auto-update disables git credential helpers, so an HTTPS private
  remote cannot authenticate on refresh; it falls back to a full re-clone that can time out.
  SSH remotes are unaffected — a key in `ssh-agent` authenticates background pulls normally.
  The `owner/repo` shorthand already clones over SSH by default.
- README documents `CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE=1` as a safety net.
- Plugin `source` stays a relative path, so a teammate needs access to exactly one repo.

## 5. `install.sh`

Bash, in-repo, no toolchain and no registry — the clone is the delivery. Symlinks by
default so `git pull` is the update mechanism.

```
./install.sh --list                          # skills in this repo, with descriptions
./install.sh --claude                        # link all -> ~/.claude/skills/
./install.sh --cursor                        # link all -> ~/.cursor/skills/
./install.sh --cursor --only diagnose,write-plan
./install.sh --claude --exclude self-improve
./install.sh --cursor --copy                 # real copies instead of links
./install.sh --claude --dry-run              # print the plan, touch nothing
./install.sh --doctor                        # audit what is installed
./install.sh --uninstall --cursor            # remove only what we own
./install.sh --force                         # replace an entry we do not own
```

### Targets

| Flag | Destination |
|---|---|
| `--claude` | `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/` |
| `--cursor` | `$HOME/.cursor/skills/` |
| `--agents` | `$HOME/.agents/skills/` (tool-neutral; Cursor also scans it) |

**No target flag prints usage and exits non-zero.** Nothing is written until the user says
where. Auto-detection was rejected: writing to a place the user did not name is exactly the
surprise the ownership rules exist to prevent.

### Ownership

`--uninstall` must never delete something it did not create.

- A **symlink** is self-identifying: owned if it resolves inside this repo's `skills/`.
- A **copy** is not, so `--copy` writes a `.installed-from` marker inside each skill folder
  recording the repo path and commit sha. `--doctor` and `--uninstall` read it.
- Anything without either signal is reported as `foreign` and left strictly alone.
- If a destination exists and is not ours, the script refuses and reports. `--force`
  overrides, printing exactly what it will replace first.

### `--doctor` states

```
~/.cursor/skills
  ok        analyze-issue     -> ~/src/agent-skills/skills/analyze-issue
  BROKEN    diagnose          -> dangling (clone moved or deleted?)
  stale     write-plan        copy from a4f21c9, repo is at 9b3e102
  foreign   my-own-thing      not managed by this repo — untouched
  missing   github-pr-review  in repo, not installed here
```

`BROKEN` is the accepted cost of symlink-by-default: moving or deleting the clone breaks
every link. `--doctor` is how that is caught rather than silently endured.

### Portability constraint

macOS ships bash 3.2, so no associative arrays and no `mapfile`. The script targets 3.2 and
stays shellcheck-clean — a little more verbose, but no `brew install bash` prerequisite for
anyone on a Mac.

## 6. Skill contents

### 6.1 The 16 skills

Imported from `dot-files/claude/.claude/skills/`:

`analyze-issue`, `diagnose`, `execute-plan`, `github-issue-pickup`, `github-issue-write`,
`github-pr-create`, `github-pr-review`, `grill-me`, `grill-with-docs`, `read-handoff`,
`research-solutions`, `run-and-report-tests`, `self-improve`, `write-handoff`, `write-plan`,
`write-skill`

`remember` and `work-log` are deliberately excluded and stay in `dot-files`.

The chain `analyze-issue → write-plan → execute-plan → github-pr-create` hands off through
the shared scratch directory, and all four ship together — publishing a subset would leave a
dangling reference. That directory is renamed from `.claude/scratch/` to `.agents/scratch/`
on import; see 6.4.

### 6.2 Fix 1 — references to the dropped skills

| Location | What it is | Fix |
|---|---|---|
| `self-improve/SKILL.md:64`, `:78` | real handoff: "hand off to `remember`; it owns the two-file protocol" | conditional — hand off if a memory skill is present, otherwise inline the protocol |
| `write-skill/SKILL.md:13`, `:63` | `remember` as the worked example of a modes-based skill | swap to `analyze-issue`, which is in the repo and also has modes |
| `execute-plan/SKILL.md:89` | "offer `remember` and `work-log` as next steps — offer only" | drop the two names, keep the intent |
| `self-improve/EXAMPLES.md:20` | example row routing "via `remember`" | reword to the destination, not the skill |
| descriptions, several | "NOT for X (use `remember`)" routing clauses | restate as behaviour, drop the skill name |

Only the first is broken behaviour; the rest are pointers a teammate cannot follow.
`validate.sh` adds an automated check so this class of bug cannot return.

### 6.3 Fix 2 — make every skill agent-agnostic

*(Revised 2026-08-14. The original decision was to label the three host-specific skills
`metadata: {agents: [claude-code]}` and have the installer skip them on Cursor. Superseded:
every skill is rewritten to run on both agents, so nothing needs labelling or skipping.)*

Three skills reach outside the project for state:

| Skill | Host-specific path |
|---|---|
| `write-handoff` | `~/.claude/projects/<encoded-root>/handoffs/` (`SKILL.md:44`, prose at `:68`) |
| `read-handoff` | `~/.claude/projects/<encoded-root>/handoffs/` (`SKILL.md:26`, prose at `:17`) |
| `self-improve` | `~/.claude/rules/`, `~/.claude/CLAUDE.md`, `~/.claude/projects/<root>/memory/` |

**Cursor has no `~/.claude/projects/`, so there is nothing to remap to.** Agent-agnostic here
means picking a home neither tool owns, not translating a path. State moves to
`~/.agent-skills/<encoded-repo-root>/`, keeping handoffs outside the repo — which is why they
were put there in the first place. Both shell lines become:

```sh
dir=~/.agent-skills/$(printf '%s' "$root" | sed 's#/#-#g')/handoffs
```

**`self-improve` is a different shape — it can do strictly less on Cursor.** Two facts force
a per-agent *strategy*, not a per-agent path:

- **Cursor's User Rules have no file on disk.** They live in `Customize → Rules` in the
  settings UI. Project rules (`.cursor/rules/*.mdc`) and `AGENTS.md` are writable; user-level
  rules are not. So the two highest-level destinations have no writable target at all.
- **Claude Code's `~/.claude/projects/<root>/memory/` is a built-in**, auto-loaded by Claude
  Code. Redirecting it to a neutral directory would stop it being read — unlike the handoff
  directory, which was only ever a folder the skill chose, and so moves freely.

`SKILL.md` stays neutral: it ranks the lesson and picks a destination *class*, then detects the
agent and dispatches to the matching section of `skills/self-improve/AGENT-STRATEGIES.md`.

Detection probes the filesystem and asks when unclear: `~/.claude` present and no `.cursor/` →
Claude Code; `.cursor/` or `~/.cursor` present → Cursor; both or neither → ask in one line.

| Destination class | Claude Code | Cursor |
|---|---|---|
| User-level style / workflow | write `~/.claude/CLAUDE.md` | no writable target — paste-ready text |
| Non-negotiable policy | write `~/.claude/rules/<topic>.md` | no writable target — paste-ready text |
| Repo-specific, team-shared | project `CLAUDE.md` / `AGENTS.md` | `AGENTS.md`, or `.cursor/rules/<topic>.mdc` with `alwaysApply: true` |
| Repo-specific, private | `~/.claude/projects/<root>/memory/` (built-in) | gitignored `.cursor/rules/<topic>.mdc` |
| Learned knowledge | brain fragment, conditional (see 6.2) | `~/.agent-skills/<encoded-root>/memory/` |
| A repeatable procedure | `skills/<name>/SKILL.md` | `.cursor/skills/<name>/SKILL.md` |

**For the two rows Cursor cannot write, the skill writes nothing and prints the block plus
where to paste it.** It never writes a file Cursor will not read, and never silently downgrades
a rule meant to be global into a project-scoped one — a downgrade would look like it worked
while quietly applying to one repo.

**`AGENT-STRATEGIES.md` is the single place host names are allowed**, and `validate.sh` exempts
it by path.

**Testing limit:** Cursor is not installed on this machine (no `~/.cursor`), so the Cursor
branch cannot be exercised end to end here. `install.sh --cursor --dry-run` still verifies the
installer half.

`research-solutions` and `write-skill` only mention `~/.claude/CLAUDE.md` as one option in a
list — reword to "your agent's user-level instructions file" and cite `AGENT-STRATEGIES.md`.

### 6.4 Fix 3 — move the scratch convention off a host name

43 occurrences of `.claude/scratch/` across 9 skills, over 8 subdirectories: `plans`,
`issue-analysis`, `draft-prs`, `draft-issues`, `deliverables`, `test-reports`,
`solution-research`, `reviews`.

The path is project-relative, so it *works* under Cursor. But it names one vendor in every
project it touches, and it is the convention the `analyze-issue → write-plan → execute-plan
→ github-pr-create` chain hands off through. Rename to **`.agents/scratch/`**, keeping every
subdirectory name.

**Done in one phase, not spread out.** The chain breaks if any single skill is missed, so
`validate.sh` enforces that no `.claude/scratch/` survives.

**Known cost:** after the rename, plans and reports already sitting in `.claude/scratch/` in
other projects are invisible to the skills. No read-both-paths fallback is being built — it
would muddy the prose in 9 skills to serve a one-time move. `mv .claude/scratch
.agents/scratch` per project covers it.

### 6.5 Known bug fixed on import

`work-log` told the agent to run `~/.claude/skills/work-log/scripts/worklog.py`, which is
the wrong path once installed to `~/.cursor/skills/`. That skill is not being imported, but
the lesson is a rule for this repo: **a skill never hardcodes its own install path.** Bundled
scripts are referenced relative to the skill folder. `validate.sh` enforces it.

## 7. Migrating off stow

Today `~/.claude/skills` is a **single folded symlink** to the whole dot-files directory:

```
~/.claude/skills  ->  ../Workspaces/dot-files/claude/.claude/skills
```

One symlink cannot serve two repos. While the fold exists, `install.sh --claude` would be
writing skill folders into the dot-files repo.

```
   TODAY (folded)                     NEEDED (unfolded)
   ~/.claude/skills ─┐                ~/.claude/skills/        <- real dir
                     │                  ├── remember      -> dot-files/...
                     ▼                  ├── work-log      -> dot-files/...
   dot-files/.../skills/                ├── write-plan    -> agent-skills/skills/...
     (all 18 live here)                 └── ... 15 more   -> agent-skills/skills/...
```

**Stow's own folding rule is the fix.** Stow collapses a directory into one symlink only when
the target does not exist. If `~/.claude/skills/` is already a real directory, stow descends
and links each entry separately. No `--no-folding`, no `.stow-local-ignore`.

```
1.  cd dot-files && git status                    # must be clean
2.  copy the 16 skill dirs -> agent-skills/skills/, commit there
3.  git rm -r the 16 from dot-files, commit       # dot-files keeps remember, work-log
4.  stow -D claude -t ~                           # drops the folded symlink; files stay in the repo
5.  mkdir -p ~/.claude/skills                     # <- the whole trick
6.  make stow-claude                              # links remember + work-log INTO the real dir
7.  cd agent-skills && ./install.sh --claude      # links the 16 alongside them
8.  ./install.sh --doctor
    ls -la ~/.claude/skills                       # expect 18 links: 2 -> dot-files, 16 -> agent-skills
```

Migration history is a plain copy — one import commit in `agent-skills`, one removal commit
in `dot-files`. Authoring history stays available in `dot-files` if it is ever needed.

**Step 5 must also go in the Makefile,** or a fresh machine folds again:

```make
stow-claude:
	mkdir -p ~/.claude/skills
	stow -R claude -t ~
```

**Rollback is cheap through step 7.** Nothing is deleted — step 4 removes a symlink and every
file lives in one repo or the other. To undo: `rm -rf ~/.claude/skills && make stow-claude`.

## 8. Validation, tests, CI

### `scripts/validate.sh`

A malformed skill does not error — it silently never triggers. These are the checks:

- every `skills/*/` contains a `SKILL.md`
- frontmatter parses, and `name` **exactly matches the folder name** (Cursor rejects it otherwise)
- `description` present and non-empty
- every relative link in `SKILL.md` and bundled `.md` files resolves to a file that exists
- **no reference to a skill folder absent from `skills/`** — the automated form of Fix 1
- **no host-specific path** (`~/.claude/`, `~/.cursor/`, `.claude/scratch/`, `.cursor/`) —
  the automated form of Fixes 2 and 3. `skills/self-improve/AGENT-STRATEGIES.md` is the one
  exempt file, since naming per-agent locations is its whole job
- no skill hardcodes its own install path — see 6.5

### Tests

`install.sh` is branching logic, so it gets tests up front under `bats-core`, run against a
throwaway `HOME` so nothing touches real config: target selection, `--only`/`--exclude`,
symlink vs copy, ownership detection, refuse-to-clobber, `--force`, each `--doctor` state,
and uninstall sparing foreign entries.

### CI

One GitHub Actions workflow on push and PR:

```
shellcheck install.sh scripts/*.sh
scripts/validate.sh
bats tests/
```

## 9. Decisions on record

| Decision | Choice | Why |
|---|---|---|
| Distribution modes | marketplace + plain clone + CLI | Cursor has no registry, so the CLI is the mechanism there, not a convenience |
| Source of truth | `agent-skills`, curated subset | one copy, no drift; the skills I pick, not all 18 |
| Plugin granularity | one plugin, everything | opt-in personal setup, nobody is shopping for subsets |
| Hosting | private, personal account | my setup; teammates invited individually |
| Plugin root | repo root, `source: "./"` | one plugin, so `skills/` belongs at the top |
| Installer runtime | Bash in-repo | zero toolchain, zero registry, the clone is the delivery |
| Install mode | symlink default, `--copy` opt out | `git pull` becomes the update mechanism |
| No-flag behaviour | usage + exit non-zero | never write somewhere the user did not name |
| Cursor-incompatible skills | rewrite to be agent-agnostic | *(revised — was label + installer skip)* every skill should run on both agents |
| Out-of-repo state home | `~/.agent-skills/<encoded-root>/` | Cursor has no `~/.claude/projects/`, so pick a home neither tool owns; keeps handoffs outside the repo |
| `self-improve` on Cursor | per-agent strategy, not per-agent path | Cursor's User Rules are UI-only, so two destinations have no writable target — the skill does less, honestly |
| Cursor user-level fallback | emit paste-ready text | writing a project-scoped rule instead would look like it worked while applying to one repo |
| Agent detection | probe filesystem, ask if unclear | works with no config; both-or-neither is the only case worth a question |
| Shared scratch directory | `.agents/scratch/` | project-relative already worked, but it named one vendor in every project it touched |
| Migration history | plain copy | simple; history stays in dot-files |

## 10. Open questions

None blocking. Two to revisit after the repo is in use:

- **Themed bundles.** If the install-everything plugin turns out too coarse, splitting into
  `planning` / `github` / `review` changes only `marketplace.json`.
- **Public flip.** If collaborator invites become tedious, going public costs nothing in the
  design — README and `install.sh` work either way.
