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

One big branch becomes several small PRs. Each PR is based on the PR below it. There are six
phases. Run them strictly in order. **Phases 1 to 4 are read-only.** Create no branch, no commit,
no push, and no PR before the user says yes in Phase 4.

**Run this command first on every run:** `git status --porcelain`. Any output means the tree is
dirty. Stop, and ask the user to commit or stash the work. A split on top of uncommitted work
loses that work.

## Phase 1: Read the plan first

The diff shows *what* changed. It never shows *why*. The why decides the cut lines.

1. **Ask the user outright:** "Is there a plan, analysis, design doc, RFC, or ticket for this work?
   Point me at it."
2. **Search the repo:** `.agents/scratch/plans/`, `.agents/scratch/issue-analysis/`, `PLAN.md`,
   `docs/`, `rfcs/`, `design/`, `*.plan.md`, `ADR-*.md`.
3. **If the branch has an open PR**, read it and anything it links: `gh pr view --json
   body,title,url`, then `gh issue view {n}` per issue mentioned.
4. **Read the commit messages** with `git log --format='%h %s%n%b' {base}..HEAD`. They carry intent
   that the diff cannot show.

Show the user **three bullets** of what you learned. Do this before you continue to Phase 2. **If
you find no plan anywhere**, say so plainly. Then ask the user to describe the feature in two or
three sentences. Never guess the feature from the diff.

## Phase 2: Analyse the branch

This phase is read-only. Find the base first with `git merge-base --fork-point main HEAD`. Ask the
user if that command does not give you the base.

```bash
git diff --stat {base}...HEAD          # file inventory + line counts
git diff --name-status {base}...HEAD   # A/M/D — D means a deletion, handle separately
git log --oneline {base}..HEAD         # do commits already line up with layers?
```

Find these three things:

- **Deleted files** (`D` rows) need an explicit `git rm` in Phase 5. A file copy does not remove
  them.
- **Commits that map onto layers.** A clean history means cherry-pick. A tangled history means a
  file copy.
- **Files that more than one layer touches.** These files need a hunk split. A split goes wrong
  here most often. List them now.

## Phase 3: Propose the split

Print the plan to the terminal. **Create nothing. Push nothing.** Read [EXAMPLE.md](EXAMPLE.md)
first. It sets the density that this proposal must reach. All six parts are required.

| # | Part | What it must contain |
|---|------|----------------------|
| 1 | A table, one row per PR | Number, branch name, base branch, title, files, approximate lines changed, and a one-line reviewer summary. |
| 2 | An ASCII diagram of the stack | Which branch forks from which branch. |
| 3 | The split method for each PR, and the reason for it | A cherry-pick, or a file copy. See note 3 below. |
| 4 | Every file that a hunk split must divide | Which hunks land in which PR. |
| 5 | The feature flag or dead-code arrangement | The reason each PR is safe to merge alone. Users see no behaviour change until the last PR. |
| 6 | Open questions | Anything you could not place with confidence, written as a question. |

Notes on the table:

- **Note 1.** Write the reviewer summary as one line, for example "checks indexes and nullability
  only".
- **Note 3.** Cherry-pick whole commits when the history already matches the layers. Copy files out
  of the original branch when the commits are tangled across layers.
- **Note 6.** Write it as a question, not as a silent assumption.

**Size:** aim for ~300 to 400 lines of real change per PR. Cut along the layer boundaries: prep
refactors → schema → core logic with its tests → transport and wiring → flag activation.
**Never propose a tests-only PR.** Tests ship in the same PR as the code they cover.

## Phase 4: Confirm

Stop. Ask the user to approve, adjust, or reject.

Wait for an **explicit yes**. Silence is not a yes. A vague reply is not a yes. A message that
answers only part of the question is not a yes, so ask about the rest. If the user requests
changes, revise the proposal and ask again. There is no limit on the number of rounds.

## Phase 5: Build the stack

Start this phase only after the user approves. Work **bottom-up**, one rung at a time.
[SPLITTING.md](SPLITTING.md) holds the mechanics: cherry-pick, file copy, hunk-level `git apply`,
deletions, and feature flags.

For each PR in order:

1. Branch from **the previous rung**, not from main. The bottom rung branches from `{base}`.
2. Move the changes onto the rung with the method agreed in Phase 3.
3. `git rm` each deletion assigned to this rung.
4. Run the project's build and test commands. Use the pre-done checks in `CLAUDE.md`, or the repo's
   own `CLAUDE.md`/`AGENTS.md` where it defines them. **A failure stops the whole run.** Report the
   failure, and never build the rung above a broken rung.
5. Commit with a Conventional Commits message, per `rules/git-commit.md`.

Then **stop again**. The local stack exists. Nothing has left the machine. A push and a PR are
separate actions, and each one needs its own approval. See `rules/git-push.md`.

**When the user approves, pass the work to `github-pr-create`.** That skill detects the chain. It
drafts each PR body from the repo's template. It opens the PRs as a native GitHub Stack. Where
`gh-stack` is missing, it opens plain chained PRs instead. Recommend that skill, and do not invoke
it. Every mechanic that publishes a PR lives there.

## Phase 6: Verify

Prove nothing was lost. Run this and **show the user the output**:

```bash
git diff {original-branch} {top-of-stack}
```

Empty output means the stack is complete. Any output means content is missing or changed. Show the
difference, and explain what it is. Then report the final stack with the PR links, **in merge
order** (bottom first).

## Troubleshooting

- **A review asks for changes on a lower rung.** Commit the fix on that rung. Then run `git rebase
  --update-refs {base}` from the top branch. That command moves every rung above in one pass, not
  one rung at a time. The force push after it uses `--force-with-lease`, and you must ask the user
  for it. After the stack is published, `gh stack sync` does the same job. See `github-pr-create`
  for the rest of the stack upkeep.
- **A file does not split cleanly by hunk.** The changes of two layers overlap on the same lines.
  Do not invent a middle state. Say so, and offer the two honest options. Option 1 puts the whole
  file in the later PR, and that PR grows. Option 2 lands a prep commit in the earlier PR that
  makes the file splittable. Ask the user which option to use. Never choose in silence.

## Constraints

| Constraint | Detail |
|------------|--------|
| Never modify, rebase, or delete the original branch. | It is the safety net until every PR merges. Read it, copy from it, and leave it alone. |
| Never merge anything. | The human always makes the merge decision. |
| Never run `git push --force`. | If a force push is genuinely needed, use `--force-with-lease` and ask first. |
| Never create, push, or open anything during Phases 1 to 4. | Those phases are read-only, with no exceptions. |
| A dirty tree stops the run. | The check runs before Phase 1 does any work. |
| Ask, do not assume. | Any change you cannot place with confidence becomes a question. See the note below. |
| This skill splits and builds. `github-pr-create` publishes. | Keep the PR-body and stack-linking mechanics in that skill. |

Note on "Ask, do not assume": the change becomes an open question in Phase 3, or a question in
Phase 5. It never becomes a guess.
