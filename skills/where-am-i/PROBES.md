# Probes — one command per field, and what to print when it fails

Every value in the report comes from this file or from something the harness
stated in context. Nothing is estimated. A probe that errors or returns nothing
means the field is unavailable — print it as such and move on; never retry.

## brief set

Run these as one batch. Together they take well under a second.

| Field | Command | When it fails |
|---|---|---|
| Repo root | `git rev-parse --show-toplevel` | Not a git repo — say so, report the working directory instead, and skip every git field below |
| Project name | basename of the repo root | — |
| Branch, ahead/behind, dirty files | `git status --porcelain=v1 -b` | The first line names the state: `## HEAD (no branch)` is detached, so report the short commit; `## No commits yet on <branch>` is a fresh repo, so say so rather than showing a zero-file diff as if it were a clean tree |
| In a worktree? | `git rev-parse --git-common-dir` — a path other than `.git` under the root means this checkout is a linked worktree | Report the checkout path plainly |
| Hostname | `hostname` | Fall back to `uname -n` |
| OS | `uname -s -r`, plus the `PRETTY_NAME` line of `/etc/os-release` when it exists | Print whatever `uname -s` gives |

The first line of `git status --porcelain=v1 -b` carries the branch and the
`[ahead N, behind M]` marker; every line after it is one changed file, so a line
count gives the dirty count without a second call.

## full set

Everything above, plus:

| Field | Command | When it fails |
|---|---|---|
| Every worktree of this repo | `git worktree list` | Single-checkout repo — say "no linked worktrees" |
| Dirty state per worktree | `git -C <path> status --porcelain` counted per line | Skip that row, note the path as unreadable |
| Stashes | `git stash list` | No stashes — drop the line |
| Last commit | `git log -1 --format='%h %s (%cr)'` | Empty repo — say "no commits yet" |
| Kernel, uptime, user | `uname -r`, `uptime -p`, `id -un` | Drop the individual value |
| Working directory | the shell's current directory, when it differs from the repo root | — |
| Neighbouring checkouts | in the **parent** of the repo root — see *The neighbour scan* below | Parent unreadable — say "neighbour scan skipped" |
| Recent scratch artifacts | newest few files under `.agents/scratch/` (plans, deliverables, issue-analysis, reviews) and under `~/.agent-skills/<encoded-repo-root>/handoffs/`, with mtimes | Directory missing — drop the section |

`<encoded-repo-root>` is the absolute repo root with every `/` replaced by `-`.

### The neighbour scan

```
find <parent> -maxdepth 5 \
  \( -name node_modules -o -name vendor -o -name target -o -name dist \) -prune \
  -o -name .git -print -prune
```

Then take the branch and dirty count of each directory holding a hit.

**Five levels, not one.** A linked worktree lives at `<repo>/.worktrees/<type>/<name>`,
which is five levels below the parent — and a branch name containing a slash adds
another. A worktree is the clearest sign of a session somebody left open, so a scan
that cannot reach one misses the exact thing this section exists to find. Five is the
floor that reaches them, not a round number.

**The two `-prune` clauses are what keep it cheap.** Pruning `.git` stops the walk
descending into every object directory, which is nearly all the cost; pruning the
dependency directories skips trees that hold no checkouts. With both, the scan is
milliseconds even across a workspace of twenty repositories.

**A linked worktree's `.git` is a file, not a directory.** `-name .git` matches both,
which is the only reason nested worktrees show up at all. Do not narrow it to `-type d`.

Then, in order:

- **Drop the current repo's own hit.** The scan always finds it, and listing it reports
  the checkout you are standing in as if it were somewhere else.
- **Keep only checkouts that are dirty or ahead of their upstream.** A clean neighbour is
  not a session anyone left open, and listing it buries the ones that are.
- **Cap at eight, newest first.** Say how many were dropped rather than truncating in
  silence.
- **Read the branch with `git symbolic-ref --short -q HEAD`.** The obvious alternative,
  `git rev-parse --abbrev-ref HEAD`, prints the string `HEAD` for a detached checkout
  **and** for a branch with no commits yet — two unrelated states collapsed into one
  label that also reads like a branch named HEAD. The command above returns the branch
  name when there is one and fails when the checkout is detached, which separates them.
- **Three states are not a branch, and each says something different.** A detached
  checkout is `detached at <short commit>`; a branch with no commits is
  `<branch> (no commits)`; a branch that tracks nothing is `no upstream`. None of them
  carries an ahead/behind count, and none is the same as being in sync.

## Agent state

| Field | Where it comes from |
|---|---|
| Context used | The session transcript — see [AGENT-STRATEGIES.md](AGENT-STRATEGIES.md) for the file location and the formula, which differ per agent |
| Remaining token budget | The remaining-token figure the harness reports in context, when it reports one |
| Model | The model identifier the agent is running under |
| Session identity | The session id the harness exposes, when it exposes one |

Context used is the one field here that is worth reading off disk, and the one
most easily got wrong — summing turns instead of taking the newest, or picking a
subagent's entry, both produce a confident number that is simply false. Follow
the formula in that file rather than improvising one.

The rest are not shell-readable. If the harness has not stated a figure this
session, the field is unavailable — and never repeat a figure from an earlier
turn as if it were current.

## Quota — the snapshot contract

The 5-hour and weekly limits arrive on the **statusline's** input, which is a
separate process this skill cannot call. The only way to read them here is a
snapshot the statusline leaves behind:

```
~/.agent-skills/usage-snapshot.json
```

```json
{
  "updated_at": "<ISO 8601 timestamp>",
  "five_hour": { "used_percentage": 41, "resets_at": "<ISO 8601 timestamp>" },
  "seven_day": { "used_percentage": 68, "resets_at": "<ISO 8601 timestamp>" }
}
```

Read it, and report each window as used percent plus time until reset.

- **Missing file** → `quota: unknown — run /usage`, plus one line saying a
  statusline that receives the rate-limit payload can leave this snapshot
  behind: point its usage-snapshot **write** setting at the absolute path above,
  and create the parent directory first — most implementations skip the write
  silently when the directory is not already there.
- **Older than fifteen minutes** → report the numbers **with their age**, e.g.
  `5h: 41% (snapshot 40m old)`. A stale 5-hour figure may describe a window that
  has already reset, so an unmarked number here is actively misleading.
- **Malformed or a missing key** → treat that window as unknown. Never fill a
  gap by carrying the other window's number across.
