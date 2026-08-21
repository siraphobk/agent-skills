---
name: github-pr-create
model: sonnet
allowed-tools: Read Write Bash(gh *) Bash(git branch *) Bash(git remote *) Bash(git log *) Bash(git diff *) Bash(git rev-parse *) Bash(git rev-list *) Bash(git for-each-ref *) Bash(git merge-base *) Bash(git push *) Bash(grep *) Bash(awk *) Bash(sort *) Bash(find *) Bash(ls *) Bash(mkdir *)
description: >
  Interactive workflow to draft and create GitHub Pull Requests from the current branch using gh — a
  single PR, or a chain of dependent PRs as a native GitHub Stack via the gh-stack extension. Diffs
  each branch against its real base, reuses an execute-plan deliverable record from
  .agents/scratch/deliverables/ when one matches, fills the repo's PR template from .github/, pulls
  the issue number from the branch name, writes every draft to .agents/scratch/draft-prs/ for
  verification, then pushes and creates after approval. Trigger when the user says "create a PR",
  "open a pull request", "make a PR", "submit PR", "draft a PR", "open a stacked PR", "stack these
  PRs", "open PRs for the epic", "PR chain", "base this PR on my other branch", or any intent to
  open pull requests from the current branch. NOT for maintaining a stack that already exists —
  sync, rebase, restack, or merge (run gh stack directly).
---

# GitHub PR Create Workflow

Use **`gh`** for PR creation and `git` for local branch context. Both must be present, `gh`
authenticated. Stacks additionally need the `gh-stack` extension.

## Step 1 — Gather branch context, then check for a stack

Run the context commands in [MECHANICS.md](MECHANICS.md) — they give you the branch, the
`{owner}/{repo}`, the trunk branch, and the diff. Run them in parallel. Parse the issue number out
of the branch name; no match means the PR simply has no "Closes" section, not an error.

Then decide which path this run takes, using [STACKS.md](STACKS.md) to detect the chain:

- **Single PR** — nothing sits between this branch and trunk. Steps 3–6 run once.
- **Stack** — one or more feature branches sit below it. Steps 3–5 run **once per rung** that has
  no PR yet, and Step 6 creates them together.

Show the detected chain before doing the work. A wrong chain wastes every step after it.

## Step 2 — Check for PR template

```bash
find .github -maxdepth 2 -type f \
  \( -iname 'pull_request_template*' -o -ipath '*PULL_REQUEST_TEMPLATE/*.md' \) 2>/dev/null | head -1
```

A template found means the PR body must follow *that* structure exactly, filling each section from
the diff and issue context — for every rung of a stack. None found means Step 4's default.

## Step 3 — Look for a deliverable record

If the work came from `execute-plan`, it left a record of what actually shipped. Check:

```bash
ls .agents/scratch/deliverables/*.md 2>/dev/null
```

Pick the one matching this branch — the file's `Branch:` header line is the reliable match; a
slug resembling the branch name is the fallback. If more than one plausibly matches, ask which.
Read it in full.

**For a stack, expect one file, not one per rung.** `execute-plan` writes a single deliverable per
epic, and its `Branch:` header names only the branch it last ran on — so that header will match at
most one rung. Match the epic file by its directory slug instead, then slice it per rung: the
sub-plan number prefixes its entries (`### [x] 02 · Phase 1 — …`, and `**02-<slug>**` under the
acceptance criteria). Each rung's PR body gets only its own sub-plan's slices.

It beats the diff for intent — a diff shows neither the **Deviations from the plan** (what reality
forced mid-run) nor the **Not done / follow-ups** (what was deliberately left out).

Use it as the primary source in Step 4: its **Summary** seeds the PR summary, its **Verification
output** seeds the test plan, its **Not done / follow-ups** becomes an out-of-scope note. Still
read the diff and cross-check — the record covers planned work, and anything in the diff it
doesn't mention needs explaining, not dropping.

No deliverable file, or none matching? Say so in one line and build from the diff alone (Step 3b).
Never invent a record.

## Step 3b — Analyze changes

Diff a single PR against trunk. Diff a rung against **its parent rung** — `git diff {parent}..{branch}`
— so its PR shows only its own work. From that diff, determine:

- **What changed**: summarize in plain language — files touched, features added/removed,
  behavior modified. Group by logical area (e.g., "auth", "UI", "config").
- **Breaking changes**: look for removed exports, changed function signatures, renamed
  config keys, dropped API endpoints, changed CLI flags. If none found, state "None."

## Step 4 — Write PR title and body

**Title**: concise, imperative, ≤72 chars. Format: `{type}: {what changed}`.
Type = fix / feat / chore / docs / refactor / perf — derived from branch prefix or changes.

**Body**: follow [TEMPLATES.md](TEMPLATES.md). Which shape you use depends on Step 2:

- **Repo has a PR template** → fill every section of *theirs*. Do not skip or remove template
  sections — leave "N/A" if truly not applicable. Feed the deliverable's content into whichever
  sections fit; do not bolt extra sections onto someone's template.
- **No template** → the default body skeleton in TEMPLATES.md, fed by the Step 3 deliverable.

**Never claim a check that wasn't run.** The test plan reports what the deliverable
actually recorded — a failed or skipped check stays visible in the PR body.

## Step 5 — Write draft file

Draft filename from the branch name: lowercase, `/` and `-` → `_`, append `.md` — e.g.
`bug-42/fix_auth_crash` → `bug_42_fix_auth_crash.md`.

Write it to `.agents/scratch/draft-prs/{filename}` (`mkdir -p` first) using the draft-file shape in
TEMPLATES.md — the stack wrapper when this is a rung, which records its position and parent. Add
`.agents/scratch/` to `.gitignore` if missing (check with `grep -q "\.agents/scratch"`).

Then show the confirm block from TEMPLATES.md — the stack one if this is a chain, printed once
after every rung's draft is written — and wait for their word.

## Step 6 — Create (only after user confirms)

**Ask for the push on its own.** Approving the drafts approves the *text*, not the push —
`rules/git-push.md` wants explicit permission in the same turn. Name every branch and the remote,
then wait for a clear go.

**Single PR** — push, then create:

```bash
git push -u origin {branch}
gh pr create --title "{title}" --base {trunk} --head {branch} --body-file {draft path}
```

**Stack** — `gh stack link` pushes every rung, chains the bases, opens the missing PRs, and builds
the Stack in one call; then install the drafted content per rung. Commands and the no-native-stack
fallback: [STACKS.md](STACKS.md).

Report every PR URL. Then offer to delete the draft files, naming them.

## Error handling

- `gh` not authenticated: tell the user to run `gh auth login`
- Not in a git repo: tell user to `cd` into the project first
- On trunk already, or no commits ahead of the base: warn, do nothing — the PR would be empty
- Push rejected, or a pre-push hook fails: report the reason and stop, never bypass
- `gh-stack` not installed: name `gh extension install github/gh-stack`, offer the plain fallback
- A rung already has an open PR: reuse it, never open a second one

## Constraints

- **Never push or open a PR without approval in the same turn.** Drafting is free; publishing is
  not. `gh stack link` pushes as a side effect — say so in the ask, and name each branch it moves.
- **Never edit a PR body that this run didn't create** without asking first.
- **Never force push, and never push to a protected branch.** The head is always a feature branch.
- **Never guess a stack order.** Ambiguous chain → show it and ask.
- **This skill creates PRs; it does not maintain them.** Rebasing, syncing, restacking, and merging
  a stack are `gh stack`'s job — point the user there rather than doing it here.
