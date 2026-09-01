# Probes: one command per field, and what to print when it fails

Every value in the report comes from this file or from something the harness
stated in context. Estimate nothing. A probe that errors or returns nothing
makes the field unavailable. Print the field as unavailable and continue. Never
retry.

## brief set

Run these as one batch. Together they take well under a second.

| Field | Command | When it fails |
|---|---|---|
| Repo root | `git rev-parse --show-toplevel` | Not a git repo. Say so, report the working directory instead, and skip every git field below |
| Project name | basename of the repo root | — |
| Branch, ahead/behind, dirty files | `git status --porcelain=v1 -b` | The first line names the state. `## HEAD (no branch)` means a detached checkout, so report the short commit. `## No commits yet on <branch>` means a fresh repo, so say so. Do not show a zero-file diff as a clean tree |
| In a worktree? | `git rev-parse --git-common-dir`. A path other than `.git` under the root means this checkout is a linked worktree | Report the checkout path plainly |
| Hostname | `hostname` | Use `uname -n` instead |
| OS | `uname -s -r`, plus the `PRETTY_NAME` line of `/etc/os-release` when it exists | Print whatever `uname -s` gives |

The first line of `git status --porcelain=v1 -b` carries the branch and the
`[ahead N, behind M]` marker. Every line after it is one changed file. A line
count therefore gives the dirty count without a second call.

## full set

Everything above, plus:

| Field | Command | When it fails |
|---|---|---|
| Every worktree of this repo | `git worktree list` | Single-checkout repo. Say "no linked worktrees" |
| Dirty state per worktree | `git -C <path> status --porcelain` counted per line | Skip that row, note the path as unreadable |
| Stashes | `git stash list` | No stashes. Drop the line |
| Last commit | `git log -1 --format='%h %s (%cr)'` | Empty repo. Say "no commits yet" |
| Kernel, uptime, user | `uname -r`, `uptime -p`, `id -un` | Drop the individual value |
| Working directory | the shell's current directory, when it differs from the repo root | — |
| Neighbouring checkouts | in the **parent** of the repo root. See *The neighbour scan* below | Parent unreadable. Say "neighbour scan skipped" |
| Recent scratch artifacts | newest few files under `.agents/scratch/` (plans, deliverables, issue-analysis, reviews) and under `~/.agent-skills/<encoded-repo-root>/handoffs/`, with mtimes | Directory missing. Drop the section |

`<encoded-repo-root>` is the absolute repo root with every `/` replaced by `-`.

### The neighbour scan

```
find <parent> -maxdepth 5 \
  \( -name node_modules -o -name vendor -o -name target -o -name dist \) -prune \
  -o -name .git -print -prune
```

Then take the branch and the dirty count of each directory that holds a hit.

**Five levels, not one.** A linked worktree lives at `<repo>/.worktrees/<type>/<name>`.
That path is five levels below the parent. A branch name with a slash in it adds one
more level. A worktree is the clearest sign of a session that somebody left open.
A scan that cannot reach one misses the exact thing this section must find. Five is
the floor that reaches them, and not a round number.

**The two `-prune` clauses keep the scan cheap.** The `.git` prune stops the walk
before it descends into every object directory, which is nearly all the cost. The
dependency prune skips trees that hold no checkouts. With both prunes, the scan takes
milliseconds, even across a workspace of twenty repositories.

**A linked worktree's `.git` is a file, not a directory.** `-name .git` matches both.
That match is the only reason nested worktrees appear at all. Do not narrow it to
`-type d`.

Then, in order:

- **Drop the current repo's own hit.** The scan always finds it. A row for it reports
  the checkout you are standing in as if it were somewhere else.
- **Keep only checkouts that are dirty or ahead of their upstream.** A clean neighbour
  is not a session that anyone left open. A row for it hides the checkouts that are.
- **Cap at eight, newest first.** Say how many rows you dropped. Do not truncate the
  list in silence.
- **Read the branch with `git symbolic-ref --short -q HEAD`.** The obvious alternative
  is `git rev-parse --abbrev-ref HEAD`. It prints the string `HEAD` for a detached
  checkout **and** for a branch with no commits yet. That is two unrelated states under
  one label, and the label also reads like a branch named HEAD. The command above
  returns the branch name when there is one, and it fails when the checkout is
  detached. That difference separates the two states.
- **Three states are not a branch, and each one says something different.** A detached
  checkout is `detached at <short commit>`. A branch with no commits is
  `<branch> (no commits)`. A branch that tracks nothing is `no upstream`. None of the
  three carries an ahead/behind count. None of the three is the same as a checkout in
  sync.

## Agent state

| Field | Where it comes from |
|---|---|
| Context used | The session transcript. See [AGENT-STRATEGIES.md](AGENT-STRATEGIES.md) for the file location and the formula, which differ per agent |
| Remaining token budget | The remaining-token figure the harness reports in context, when it reports one |
| Model | The model identifier the agent is running under |
| Session identity | The session id the harness exposes, when it exposes one |

Context used is the one field here that is worth a read from disk. It is also
the field that goes wrong most easily. A sum of the turns, or a subagent's
entry, produces a confident number that is simply false. Follow the formula in
that file. Do not improvise one.

You cannot read the other fields from the shell. If the harness did not state a
figure this session, the field is unavailable. Never repeat a figure from an
earlier turn as if it were current.

## Quota: the snapshot contract

The 5-hour and weekly limits arrive on the **statusline's** input. The statusline
is a separate process, and this skill cannot call it. The only way to read the
limits here is a snapshot file that the statusline writes:

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

Read the file. Report each window as a used percent and the time until reset.

- **Missing file** → print `quota: unknown — run /usage`. Add one line that says
  a statusline which receives the rate-limit payload can write this snapshot.
  Point its usage-snapshot **write** setting at the absolute path above, and
  create the parent directory first. Most implementations skip the write in
  silence when the directory does not already exist.
- **Older than fifteen minutes** → report the numbers **with their age**, for
  example `5h: 41% (snapshot 40m old)`. A stale 5-hour figure may describe a
  window that already reset. An unmarked number here is therefore misleading.
- **Malformed file, or a missing key** → treat that window as unknown. Never
  fill a gap with the other window's number.
