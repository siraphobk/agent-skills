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

Use **`gh`** to create the PR. Use `git` to get the local branch context. Both tools must be
present, and `gh` must be authenticated. A stack also needs the `gh-stack` extension.

## Step 1: Gather the branch context, then check for a stack

Run the context commands in [MECHANICS.md](MECHANICS.md). They give you the branch, the
`{owner}/{repo}`, the trunk branch, and the diff. Run them in parallel. Parse the issue number
from the branch name. No match is not an error. It means the PR has no "Closes" section.

Then use [STACKS.md](STACKS.md) to detect the chain and to decide which path this run takes.

- **Single PR.** Nothing sits between this branch and trunk. Steps 3 to 6 run once.
- **Stack.** One or more feature branches sit below this branch. Steps 3 to 5 run **once per
  rung** that has no PR yet. Step 6 creates the PRs together.

Show the detected chain before you do the work. A wrong chain wastes every step after it.

## Step 2: Check for a PR template

```bash
find .github -maxdepth 2 -type f \
  \( -iname 'pull_request_template*' -o -ipath '*PULL_REQUEST_TEMPLATE/*.md' \) 2>/dev/null | head -1
```

If you find a template, the PR body must follow *that* structure exactly. Fill each section from
the diff and the issue context. Do this for every rung of a stack. If you find no template, use
the default body from Step 4.

## Step 3: Look for a deliverable record

If the work came from `execute-plan`, it left a record of what shipped. Check for that record.

```bash
ls .agents/scratch/deliverables/*.md 2>/dev/null
```

Pick the file that matches this branch. The file's `Branch:` header line is the reliable match. A
slug that resembles the branch name is the fallback. If more than one file looks like a match, ask
the user which one to use. Read the whole file.

**For a stack, expect one file, not one file per rung.** `execute-plan` writes a single deliverable
per epic. Its `Branch:` header names only the branch it ran on last, so that header matches at most
one rung. Match the epic file by its directory slug instead. Then split the file per rung. The
sub-plan number prefixes its entries. Two examples are `### [x] 02 · Phase 1 — …` and
`**02-<slug>**` under the acceptance criteria. Each rung's PR body gets only the parts from its own
sub-plan.

The record beats the diff for intent. A diff does not show the **Deviations from the plan**, which
is what reality forced mid-run. A diff does not show the **Not done / follow-ups** either, which is
what the run deliberately left out.

Use the record as the primary source in Step 4. Its **Summary** seeds the PR summary. Its
**Verification output** seeds the test plan. Its **Not done / follow-ups** becomes an out-of-scope
note. Still read the diff and cross-check it. The record covers planned work. Anything in the diff
that the record does not mention needs an explanation, not a deletion.

If there is no deliverable file, or if none matches, say so in one line. Then build the PR from the
diff alone (Step 3b). Never invent a record.

## Step 3b: Analyze the changes

Diff a single PR against trunk. Diff a rung against **its parent rung** with
`git diff {parent}..{branch}`. That makes the rung's PR show only its own work. Use that diff to
determine two things.

- **What changed.** Summarize in plain language the files touched, the features added or removed,
  and the behavior modified. Group the changes by area, such as "auth", "UI", or "config".
- **Breaking changes.** Look for removed exports, changed function signatures, renamed config keys,
  dropped API endpoints, and changed CLI flags. If you find none, state "None."

## Step 4: Write the PR title and body

**Title.** Keep it short and imperative, at 72 characters or fewer. Use the format
`{type}: {what changed}`. The type is fix, feat, chore, docs, refactor, or perf. Derive the type
from the branch prefix or from the changes.

**Body.** Follow [TEMPLATES.md](TEMPLATES.md). Step 2 decides which shape you use.

- **The repo has a PR template.** Fill every section of *their* template. Do not skip or remove a
  template section. Leave "N/A" when a section truly does not apply. Feed the deliverable's content
  into the sections that fit. Do not add extra sections to someone's template.
- **The repo has no template.** Use the default body skeleton in TEMPLATES.md. Feed it from the
  Step 3 deliverable.

**Never claim a check that nobody ran.** The test plan reports what the deliverable recorded. A
failed check or a skipped check stays visible in the PR body.

## Step 5: Write the draft file

Build the draft filename from the branch name. Make it lowercase, change each `/` and `-` to `_`,
and add `.md` at the end. For example, `bug-42/fix_auth_crash` becomes `bug_42_fix_auth_crash.md`.

Run `mkdir -p` first, then write the file to `.agents/scratch/draft-prs/{filename}`. Use the
draft-file shape in TEMPLATES.md. Use the stack wrapper when this branch is a rung, because that
wrapper records the rung's position and parent. Add `.agents/scratch/` to `.gitignore` when it is
missing. Check for it with `grep -q "\.agents/scratch"`.

Then show the confirm block from TEMPLATES.md. Use the stack confirm block when this is a chain,
and print it once after you write every rung's draft. Then wait for the user's answer.

## Step 6: Create the PRs, only after the user confirms

**Ask for the push on its own.** When the user approves the drafts, the user approves the *text*
and not the push. `rules/git-push.md` wants explicit permission in the same turn. Name every branch
and the remote. Then wait for a clear yes.

**Single PR.** Push, then create.

```bash
git push -u origin {branch}
gh pr create --title "{title}" --base {trunk} --head {branch} --body-file {draft path}
```

**Stack.** One call to `gh stack link` pushes every rung, chains the bases, opens the missing PRs,
and builds the Stack. Then install the drafted content for each rung. [STACKS.md](STACKS.md) holds
the commands and the fallback for a repo with no native stack.

Report every PR URL. Then offer to delete the draft files. Name each file in the offer.

## Error handling

| Problem | What to do |
|---|---|
| `gh` is not authenticated | Tell the user to run `gh auth login`. |
| Not in a git repo | Tell the user to `cd` into the project first. |
| On trunk already, or no commits ahead of the base | Warn the user and do nothing. The PR would be empty. |
| Push rejected, or a pre-push hook fails | Report the reason and stop. Never bypass the hook. |
| `gh-stack` is not installed | Name `gh extension install github/gh-stack`. Offer the plain fallback. |
| A rung already has an open PR | Reuse that PR. Never open a second one. |

## Constraints

- **Never push or open a PR without approval in the same turn.** A draft costs nothing. A published
  PR does not. `gh stack link` pushes as a side effect. Say that in the ask, and name each branch it
  moves.
- **Never edit a PR body that this run did not create.** Ask the user first.
- **Never force push, and never push to a protected branch.** The head is always a feature branch.
- **Never guess a stack order.** If the chain is ambiguous, show it and ask the user.
- **This skill creates PRs. It does not maintain them.** The rebase, the sync, the restack, and the
  merge of a stack are `gh stack`'s job. Point the user there. Do not do that work here.
