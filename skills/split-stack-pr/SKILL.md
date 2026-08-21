---
name: split-stack-pr
allowed-tools: Read Grep Glob Bash
description: >
  Splits one oversized feature branch into a stack of small, chained pull requests, where each PR
  targets the branch below it instead of main. Reads the design intent first — plan doc, RFC,
  ticket, open PR description, commit messages — then inspects the branch read-only, proposes a
  numbered split with a per-PR table and an ASCII stack diagram, and waits for an explicit yes
  before creating anything. On approval it builds the branches bottom-up, runs the project's build
  and tests on every rung, and proves nothing was lost by diffing the top of the stack against the
  original branch. Trigger when the user says "split this branch", "this PR is too big", "break this
  into stacked PRs", "my reviewer wants smaller PRs", "turn this into a stack", or "chop this branch
  into reviewable pieces". NOT for opening PRs from branches that are already split (use
  github-pr-create), and NOT for maintaining a stack that already exists — sync, rebase, restack, or
  merge (run gh stack directly).
---

# Split a Branch into a Stack of PRs

One big branch becomes several small PRs, each based on the one below it. Six phases, strictly in
order. **Phases 1–4 are read-only** — no branch, no commit, no push, no PR until Phase 4's yes.

**First command, every run:** `git status --porcelain`. Any output means the tree is dirty — stop
and ask the user to commit or stash, since splitting on top of uncommitted work loses it.

## Phase 1 — Read the plan first

The diff shows *what* changed. It never shows *why*, and the why is what decides the cut lines.

1. **Ask the user outright:** "Is there a plan, analysis, design doc, RFC, or ticket for this work?
   Point me at it."
2. **Search the repo** — `.agents/scratch/plans/`, `.agents/scratch/issue-analysis/`, `PLAN.md`,
   `docs/`, `rfcs/`, `design/`, `*.plan.md`, `ADR-*.md`.
3. **If the branch has an open PR**, read it and anything it links: `gh pr view --json
   body,title,url`, then `gh issue view {n}` per issue mentioned.
4. **Read the commit messages** — `git log --format='%h %s%n%b' {base}..HEAD`. They carry intent
   the diff cannot.

Show the user **three bullets** of what you learned before moving on. **No plan anywhere?** Say so
plainly and ask the user to describe the feature in two or three sentences — never guess it from
the diff.

## Phase 2 — Analyse the branch

Read-only. Find the base first (`git merge-base --fork-point main HEAD`, or ask).

```bash
git diff --stat {base}...HEAD          # file inventory + line counts
git diff --name-status {base}...HEAD   # A/M/D — D means a deletion, handle separately
git log --oneline {base}..HEAD         # do commits already line up with layers?
```

Three things to pull out:

- **Deleted files** (`D` rows) — they need an explicit `git rm` in Phase 5, not a file copy.
- **Whether commits map onto layers** — clean history → cherry-pick, tangled → copy files.
- **Files touched by more than one layer** — these need hunk-level splitting, and are where a split
  goes wrong. List them now.

## Phase 3 — Propose the split

Print the plan to the terminal. **Create nothing. Push nothing.** Read [EXAMPLE.md](EXAMPLE.md)
first — it sets the density this proposal has to hit. All six parts are required:

1. **A table, one row per PR:** number, branch name, base branch, title, files, approximate lines
   changed, and a one-line reviewer summary ("checks indexes and nullability only").
2. **An ASCII diagram** of the stack, showing what branches off what.
3. **The split method per PR and why** — cherry-picking whole commits when history already lines
   up, copying files out of the original branch when commits are tangled across layers.
4. **Every file that must be split by hunk**, and which hunks land in which PR.
5. **The feature flag or dead-code arrangement** that makes each PR safe to merge alone, with no
   user-visible behaviour change until the last one.
6. **Open questions** — anything you could not confidently place, stated as a question rather than
   a silent assumption.

**Sizing:** aim for ~300–400 lines of real change per PR. Cut along layer boundaries — prep
refactors → schema → core logic with its tests → transport and wiring → flag activation.
**Never propose a tests-only PR;** tests ship in the same PR as the code they cover.

## Phase 4 — Confirm

Stop. Ask the user to approve, adjust, or reject.

Wait for an **explicit yes**. Silence is not a yes, a vague reply is not a yes, and a message that
answers only part of the question is not a yes — ask about the rest. Changes requested means revise
the proposal and ask again; there is no round limit.

## Phase 5 — Build the stack

Only after approval. Work **bottom-up**, one rung at a time. Mechanics — cherry-pick, file copy,
hunk-level `git apply`, deletions, feature flags — are in [SPLITTING.md](SPLITTING.md).

For each PR in order:

1. Branch off **the previous rung**, not off main. The bottom rung branches off `{base}`.
2. Bring in the changes using the method agreed in Phase 3.
3. `git rm` each deletion assigned to this rung.
4. Run the project's build and test commands (the pre-done checks in `CLAUDE.md`, or the repo's own
   `CLAUDE.md`/`AGENTS.md` where it defines them). **A failure stops the whole run** — report it
   and do not build the rung above a broken one.
5. Commit with a Conventional Commits message, per `rules/git-commit.md`.

Then **stop again**. The local stack exists; nothing has left the machine. Pushing and opening PRs
are separate actions that need their own approval — see `rules/git-push.md`.

**When approved, hand off to `github-pr-create`** — it detects the chain, drafts each PR body from
the repo's template, and opens them as a native GitHub Stack via `gh stack link`. Recommend it,
don't invoke it. Without `gh-stack`, SPLITTING.md holds the plain `git push -u` +
`gh pr create --base {parent}` fallback.

## Phase 6 — Verify

Prove nothing was lost. Run this and **show the user the output**:

```bash
git diff {original-branch} {top-of-stack}
```

Empty output means the stack is complete. Anything printed means content is missing or changed —
show the difference and explain what it is. Then report the final stack with PR links, **in merge
order** (bottom first).

## Troubleshooting

- **Review changes on a lower rung.** Commit the fix on that rung, then `git rebase --update-refs
  {base}` from the top branch — it moves every rung above in one pass instead of one at a time. The
  force-push that follows uses `--force-with-lease` and has to be asked for. `gh stack sync` does
  the same job.
- **A parent merged.** GitHub retargets the child PR's base once the parent's branch is deleted, so
  the stack survives — no base needs editing by hand. Locally, still rebase the children onto the
  updated trunk.
- **A file resists clean hunk splitting** — two layers' changes overlap in the same lines. Do not
  invent a middle state. Say so and offer the two honest options: put the whole file in the later
  PR (that PR grows), or land a prep commit in the earlier PR that makes the file splittable. Ask
  which; never pick silently.

## Constraints

- **Never modify, rebase, or delete the original branch.** It is the safety net until every PR has
  merged. Read it, copy from it, leave it alone.
- **Never merge anything.** Merging is the human's decision, always.
- **Never `git push --force`.** If a force push is genuinely needed, use `--force-with-lease` and
  ask first.
- **Never create, push, or open anything during Phases 1–4.** They are read-only, no exceptions.
- **Dirty tree stops the run** before Phase 1 does any work.
- **Ask, don't assume.** Any change you can't confidently place becomes an open question in Phase 3
  or a question in Phase 5 — never a guess.
- **This skill splits and builds; `github-pr-create` publishes.** Keep the PR-body and stack-linking
  mechanics there.
