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
| Branch, ahead/behind, dirty files | `git status --porcelain=v1 -b` | Detached HEAD prints `HEAD (no branch)` — report the short commit instead |
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
| Neighbouring checkouts | in the **parent** of the repo root: `find <parent> -maxdepth 2 -name .git`, dropping the current repo's own hit, then branch and dirty count for each | Parent unreadable — say "neighbour scan skipped" |
| Recent scratch artifacts | newest few files under `.agents/scratch/` (plans, deliverables, issue-analysis, reviews) and under `~/.agent-skills/<encoded-repo-root>/handoffs/`, with mtimes | Directory missing — drop the section |

`<encoded-repo-root>` is the absolute repo root with every `/` replaced by `-`.

**Bound the neighbour scan.** One level around the repo root, nothing deeper,
and cap the list at eight entries sorted newest-first. The scan always finds the
current repo first — drop that hit, or the report lists the checkout you are
standing in as if it were somewhere else. Report only checkouts
that are dirty or ahead of their upstream — a clean neighbour is not a session
someone left open, and listing it buries the ones that are.

## Agent state

| Field | Where it comes from |
|---|---|
| Context used | The running agent's own context accounting. Report it as a percentage of the window plus the raw figure, only if the harness stated both |
| Remaining token budget | The remaining-token figure the harness reports in context, when it reports one |
| Model | The model identifier the agent is running under |
| Session identity | The session id the harness exposes, when it exposes one |

None of these are shell-readable. If the harness has not stated a figure this
session, the field is unavailable — do not derive it from token arithmetic over
the transcript, and do not repeat a figure from an earlier turn as if it were
current.

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
