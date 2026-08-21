# agent-skills

The agent skills I use day to day, in one tree that both **Claude Code** and **Cursor**
read. There is no build step and no second copy — `skills/<name>/SKILL.md` is the source
of truth, and both tools parse the same file.

This is my setup, published so teammates can opt into it. Installing `write-plan` means
opting into `.agents/scratch/plans/` and the rest of my conventions; that is the point,
not a rough edge.

## What's in it

Run `./install.sh --list` for the descriptions. The short version:

| Chain | Skills |
|---|---|
| Plan and ship a change | `analyze-issue` → `write-plan` → `execute-plan` → `github-pr-create` |
| GitHub | `github-issue-pickup`, `github-issue-write`, `github-pr-review`, `split-stack-pr` |
| Think before building | `research-solutions`, `grill-me` |
| When something is broken | `diagnose`, `run-and-report-tests` |
| Across sessions | `write-handoff`, `self-improve`, `write-skill` |

The first four hand off to each other through `.agents/scratch/`, so they are worth
installing together.

## Using them

Skills trigger on what you say — you do not call them by name. "Plan this feature" reaches
`write-plan`, "this PR is too big" reaches `split-stack-pr`, "grill me" reaches `grill-me`.
Every skill's `description` lists the phrases it answers to; `./install.sh --list` prints
them.

Some take an argument to pick a mode:

| Skill | Argument | What it changes |
|---|---|---|
| `grill-me` | `plain` \| `docs` | `plain` interviews only; `docs` also updates `CONTEXT.md` and ADRs. Asks you when you don't say. |
| `analyze-issue` | `quick` \| `default` \| `deep`, and `bug` \| `feature` | how wide the survey goes, and which report shape it writes |
| `research-solutions` | `quick` \| `default` \| `deep` | how far the research fans out |

A typical run through the chain:

```
"analyze issue 412"          -> .agents/scratch/issue-analysis/
"grill me on that"           -> decisions resolved, no files
"plan it"                    -> .agents/scratch/plans/
"execute the plan"           -> code, plus .agents/scratch/deliverables/
"open a PR"                  -> reads the deliverable, drafts to .agents/scratch/draft-prs/
```

Each step stops for approval before it writes, commits, or pushes.

## Install — Claude Code

```
/plugin marketplace add siraphobk/agent-skills
/plugin install agent-skills@siraphobk
```

**Use an SSH remote, not HTTPS.** Background auto-update disables git credential helpers,
so a private HTTPS remote cannot authenticate on refresh and falls back to a full
re-clone that can time out. The `owner/repo` shorthand above already clones over SSH.

If a marketplace refresh ever fails and drops the entry, set
`CLAUDE_CODE_PLUGIN_KEEP_MARKETPLACE_ON_FAILURE=1` so the failure does not take your
installed plugins with it.

## Install — Cursor, or anything else

Cursor has no plugin registry, so the clone is the delivery:

```sh
git clone git@github.com:siraphobk/agent-skills.git
cd agent-skills
./install.sh --cursor
```

Symlinks by default, so `git pull` here is the update mechanism.

```sh
./install.sh --list                          # skills in this repo, with descriptions
./install.sh --cursor --only diagnose,write-plan
./install.sh --claude --exclude self-improve
./install.sh --cursor --copy                 # real copies instead of links
./install.sh --claude --dry-run              # print the plan, touch nothing
./install.sh --doctor                        # audit what is installed
./install.sh --uninstall --cursor            # remove only what we own
```

| Target | Destination |
|---|---|
| `--claude` | `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/` |
| `--cursor` | `$HOME/.cursor/skills/` |
| `--agents` | `$HOME/.agents/skills/` (tool-neutral; Cursor scans it too) |

**No target flag means no writes.** The script prints usage and exits non-zero rather
than guessing where your config lives.

### It never deletes what it did not create

- A **symlink** is self-identifying — ours when it points inside this repo's `skills/`.
- A **`--copy`** is not, so it leaves a `.installed-from` file recording the repo path
  and commit. `--doctor` and `--uninstall` read it.
- Anything else is reported as `foreign` and left strictly alone. If a destination
  already holds something we do not own, the install refuses and names it. `--force`
  overrides, printing what it replaces first.

`--doctor` reports five states, and exits non-zero if anything is `BROKEN`:

```
~/.cursor/skills
  ok        analyze-issue     -> ~/src/agent-skills/skills/analyze-issue
  BROKEN    diagnose          -> dangling (clone moved or deleted?)
  stale     write-plan        copy from a4f21c9, repo is at 9b3e102
  foreign   my-own-thing      not managed by this repo — untouched
  missing   github-pr-review  in repo, not installed here
```

`BROKEN` is the price of symlinks-by-default: move or delete the clone and every link
dies. `--doctor` is how you catch that instead of silently living with it.

## Already using stow for `~/.claude`?

If `~/.claude/skills` is a single folded symlink into your dotfiles, one symlink cannot
serve two repos — `install.sh --claude` would write into the dotfiles repo. Stow only
folds when the target does not exist, so make it a real directory first:

```sh
cd your-dotfiles && stow -D claude -t ~   # drop the folded link; files stay in the repo
mkdir -p ~/.claude/skills                 # the whole trick
stow -R claude -t ~                       # stow now links each entry separately
cd agent-skills && ./install.sh --claude  # our skills land alongside yours
./install.sh --doctor
```

Put the `mkdir -p` in your dotfiles Makefile too, or a fresh machine folds again.

## Adding a skill

See [CLAUDE.md](CLAUDE.md). Short version: create `skills/<name>/SKILL.md`, make the
frontmatter `name` match the folder exactly, run `scripts/validate.sh`. Both manifests
scan `skills/` by default, so there is no registry to update.

## Checks

```sh
shellcheck -x install.sh scripts/*.sh tests/helpers.bash   # shell lint
scripts/validate.sh                                        # skill well-formedness
bats tests/                                                # install.sh and validate.sh
```

CI runs all three on Linux and macOS. The macOS job also runs the scripts under
`/bin/bash` directly, because Homebrew's newer bash is on `PATH` there and `env bash`
would quietly test the wrong interpreter.

`install.sh` targets bash 3.2 so it runs on stock macOS — no associative arrays, no
`mapfile`.
