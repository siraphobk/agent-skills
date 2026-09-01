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

Use **`gh`** in every step. The `gh` tool must be authenticated already. The `git` tool
must be available for the local branch operations.

## Step 0: Resolve the repo and the identity

Run these in parallel:

```bash
git remote get-url origin   # parse {owner}/{repo} from the URL
gh api user --jq '.login'   # your GitHub login → {me}
```

Parse `{owner}` and `{repo}` from the remote URL. The URL has one of two formats:
`git@github.com:{owner}/{repo}.git` or `https://github.com/{owner}/{repo}.git`.

Call the login result `{me}`. Use `{owner}`, `{repo}`, and `{me}` in all later calls.

## Step 1: Show your issues first

Fetch the open issue set one time. Then divide the set locally:

```bash
gh issue list --state open --limit 100 \
  --json number,title,labels,assignees,createdAt
```

Each issue in the result has an `assignees` array. Each entry in that array has a `login`
field. Keep this fetched set. Every filter below uses the same set, so a second API call
is not necessary. From the set, select the issues where `assignees` has an entry with
`login == {me}`. Display these fields for each one: number, title, labels, created date.

If any issue is assigned to you, ask: "Want to work on one of these, or see other issues?"

If no issue is assigned to you, go directly to Step 2.

## Step 2: Filter the set if it is necessary

The user can refuse the assigned issues. The user can also have no assigned issues. In
both cases, ask which issues to show. Then filter the set that Step 1 fetched.

| Filter | Rule |
|---|---|
| No assignee | The `assignees` array is empty |
| Assigned to others | `assignees` is not empty, and no entry has `login == {me}` |
| Both (unassigned and others') | No entry has `login == {me}` |
| All open issues | The full fetched set |

Display these fields for each result: number, title, labels, assignee (if any).

## Step 3: The user picks an issue

Ask the user which issue number to work on.

Fetch the full details:

```bash
gh issue view {number} --json number,title,body,labels,assignees,comments
```

## Step 4: Determine the issue type from the labels

Map the labels to a branch prefix. Use the first label that matches:

| Label contains | Prefix |
|---|---|
| enhancement, feature, feat | `enh` |
| bug, fix, defect | `bug` |
| documentation, docs | `doc` |
| optimization, perf, performance | `opt` |
| chore, maintenance, refactor | `chore` |
| anything else / no label | `issue` |

**An issue with no labels is not an issue that you cannot classify.** When the issue has
no labels, read the body. Propose the prefix that the content implies. A reported defect
gives `bug`. A requested capability gives `enh`. Tell the user that you inferred the
prefix. Pick `issue` only when the content is truly ambiguous.

## Step 5: Summarize the issue for the user

Show a short summary before you do anything else:

```
Issue #<number>: <title>
Type: <type> (<label>)
─────────────────────────
<2-4 sentence summary of what needs to be done, based on the issue body>

Branch will be: <prefix>-<number>/<short_description>
```

Make `short_description` from the issue title. Use lowercase. Join the words with
underscores. Use a maximum of approximately 5 words. Remove the articles and the filler
words. Examples:
- "Fix cannot list QuickPages" → `fix_cannot_list_quickpages`
- "Add org permission UAT" → `org_permission_uat`
- "Improve dashboard loading performance" → `improve_dashboard_loading`

Ask: "Ready to proceed?"

## Step 6: Worktree or checkout?

After the user confirms, ask which option the user wants:

| Option | What it does |
|---|---|
| Worktree | Makes an isolated working directory under `.worktrees/`. The main checkout stays clean. |
| Checkout | Moves the current directory to the new branch, as usual. |

## Step 7: Execute, only after the user confirms

Follow [CHECKOUT.md](CHECKOUT.md) for the branch setup. Use the option that Step 6
selected, worktree or plain checkout. Do not write your own git commands. The worktree
path has two traps, and that file already handles both. The traps are the `.worktrees/`
ignore rules and the change of `core.bare`.

Then claim the issue:

```bash
gh issue edit {number} --add-assignee {me}
gh issue comment {number} --body "Taking this issue."
```

Report the result. Give the branch name, and the worktree path if one exists. Give the
issue link. Confirm that the assignee and the comment are in place.

## Next step

The issue is now claimed and the branch is ready. Recommend the `analyze-issue` skill.
That skill surveys the existing code before anyone writes a fix. Give it the issue number
(`#<number>`). Step 0 of that skill reads the number directly. The chain then continues:
**analyze-issue → write-plan → execute-plan**. Only recommend the skill. Do not invoke it
automatically. The user decides when to start.

## Error handling

| Problem | What to do |
|---|---|
| `gh` is not authenticated | Tell the user to run `gh auth login` |
| The directory is not a git repo | Tell the user to `cd` into the project first |
| The branch already exists | Suggest `git checkout {branch}` to change to it |
| Another person has the issue | Warn the user before you assign it, and let the user decide |
