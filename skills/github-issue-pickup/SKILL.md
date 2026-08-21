---
name: github-issue-pickup
model: sonnet
allowed-tools: Read Bash(gh *) Bash(git checkout *) Bash(git worktree *) Bash(git rev-parse *) Bash(git remote *) Bash(git config *) Bash(mkdir *) Bash(grep *)
description: >
  Interactive workflow to browse and claim a GitHub issue using gh. Lists open issues (yours first),
  lets you filter by assignee, summarizes the chosen issue (type, scope, what needs doing), then
  creates a properly named branch, assigns you, and comments that you're taking it. Trigger when
  user says "pick up an issue", "take an issue", "start working on an issue", "claim a GitHub
  issue", "show me issues", "what issues can I work on", "assign me to an issue", "pick an issue for
  <repo>", "grab an issue from <repo>", "find me an issue in <repo>", or any intent to browse and
  start work on a repo issue — whether invoked directly with /github-issue-pickup or phrased
  naturally.
---

# GitHub Issue Pickup Workflow

Use **`gh`** throughout. Require `gh` to be authenticated and `git` to be present for
local branch operations.

## Step 0 — Resolve repo and identity

Run these in parallel:

```bash
git remote get-url origin   # parse {owner}/{repo} from the URL
gh api user --jq '.login'   # your GitHub login → {me}
```

Parse `{owner}` and `{repo}` from the remote URL (handles both
`git@github.com:{owner}/{repo}.git` and `https://github.com/{owner}/{repo}.git`).

Call the login result `{me}`. Use `{owner}`, `{repo}`, and `{me}` in all subsequent calls.

## Step 1 — Show your issues first

Fetch the open issue set once and partition it client-side:

```bash
gh issue list --state open --limit 100 \
  --json number,title,labels,assignees,createdAt
```

Each returned issue carries an `assignees` array (each entry has a `login` field). Keep
this fetched set — every filter below reuses it, no second API call needed. From it,
select the issues where `assignees` includes an entry with `login == {me}` and display
them clearly: number, title, labels, created date.

If any are assigned to you, ask: "Want to work on one of these, or see other issues?"

If none are, proceed directly to Step 2.

## Step 2 — Filter if needed

If the user doesn't want to work on their assigned issues (or has none), ask which issues
to show, then filter the set fetched in Step 1:

- **No assignee** — empty `assignees` array
- **Assigned to others** — `assignees` non-empty and no entry has `login == {me}`
- **Both (unassigned + others')** — every issue where no entry has `login == {me}`
- **All open issues** — the full fetched set

Display results: number, title, labels, assignee (if any).

## Step 3 — User picks an issue

Ask the user which issue number they want to work on.

Fetch full details:

```bash
gh issue view {number} --json number,title,body,labels,assignees,comments
```

## Step 4 — Determine issue type from labels

Map labels to a branch prefix. Use the first matching label:

| Label contains | Prefix |
|---|---|
| enhancement, feature, feat | `enh` |
| bug, fix, defect | `bug` |
| documentation, docs | `doc` |
| optimization, perf, performance | `opt` |
| chore, maintenance, refactor | `chore` |
| anything else / no label | `issue` |

**No labels is not the same as an unclassifiable issue.** When the issue carries no labels,
read the body and propose the prefix its content implies — a reported defect → `bug`, a
requested capability → `enh` — and say you inferred it. Fall back to `issue` only when the
content is genuinely ambiguous.

## Step 5 — Summarize to the user

Present a concise summary before doing anything:

```
Issue #<number>: <title>
Type: <type> (<label>)
─────────────────────────
<2-4 sentence summary of what needs to be done, based on the issue body>

Branch will be: <prefix>-<number>/<short_description>
```

For `short_description`: derive from the issue title — lowercase, words joined by underscores, max ~5 words, strip articles and filler. Examples:
- "Fix cannot list QuickPages" → `fix_cannot_list_quickpages`
- "Add org permission UAT" → `org_permission_uat`
- "Improve dashboard loading performance" → `improve_dashboard_loading`

Ask: "Ready to proceed?"

## Step 6 — Worktree or checkout?

After the user confirms, ask which they want:

- **Worktree** — isolated working directory under `.worktrees/`, keeps the main checkout clean
- **Checkout** — switch the current directory to the new branch as usual

## Step 7 — Execute (only after user confirms)

Follow [CHECKOUT.md](CHECKOUT.md) for the branch setup — worktree or plain checkout, whichever
Step 6 settled on. Don't improvise the git commands; the worktree path has two traps
(`.worktrees/` ignore rules, and `core.bare` flipping) that the file already handles.

Then claim the issue:

```bash
gh issue edit {number} --add-assignee {me}
gh issue comment {number} --body "Taking this issue."
```

Report what was done: the branch name, the worktree path if there is one, the issue link, and
confirmation that the assignee and comment landed.

## Next step

Once the issue is claimed and the branch is ready, recommend the `analyze-issue` skill to survey
the existing code before writing any fix — pass it the issue number (`#<number>`), which its Step 0
reads directly. From there the chain continues **analyze-issue → write-plan → execute-plan**.
Recommend it; don't invoke it automatically — the user decides when to start.

## Error handling

- `gh` not authenticated: tell the user to run `gh auth login`
- Not in a git repo: tell user to `cd` into the project first
- Branch already exists: suggest `git checkout {branch}` to switch to it
- Issue already assigned to someone else: warn the user before assigning, let them decide
