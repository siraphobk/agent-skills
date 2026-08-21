# Checkout mechanics

Local code work uses **plain `git` only** — never `gh`. The PR's `owner/repo` must already
match `origin` (checked in Step 0). Fetch the PR head ref straight from origin; this works for
fork PRs too:

```
git fetch origin pull/<n>/head
```

Ask the user: **current dir** or **worktree**.

## Current dir

1. **Check for uncommitted changes** (`git status --porcelain`).
   - **Has changes** → tell the user and **ask them to confirm** before you touch anything. Once
     they confirm:
     - Save the current branch: `git rev-parse --abbrev-ref HEAD` (and the SHA if detached).
     - Run `git stash --include-untracked` and **show the stash ref** to the user.
     - Point out worktree mode as the cleaner option — they may want to switch to it.
     - If they say no to the stash, **stop**. Don't review on top of uncommitted changes.
   - **Clean** → just save the current branch.
2. Check out the PR head:
   ```
   git fetch origin pull/<n>/head
   git checkout FETCH_HEAD        # or: git checkout -b pr-<n> FETCH_HEAD
   ```
3. **When the user says the review is done:**
   - **Ask** before switching back with `git checkout <original-branch>`. Don't switch on your
     own — they may want to keep digging into the PR.
   - If you stashed, **ask** before `git stash pop` — never do it silently. The user may have
     moved on to something else.

## Worktree

Follow the worktree setup convention in [[coding/worktree-setup]] — the `.worktrees/` ignore
rule, the flattened dir name, and the `core.bare` check that runs right after the add. Then the
PR-specific part: fetch the head into a local branch, and add the worktree off that branch.

```
git fetch origin pull/<n>/head:pr-<n>
git worktree add .worktrees/pr-<n>--<short-desc> pr-<n>
```

`<short-desc>` is a kebab-case slug from the PR title. Run every later step from inside the
worktree dir.

**When the review is done:** leave the worktree on disk by default — reviews often have
follow-up. Tell the user the path and print the teardown commands from the convention. Don't
remove it on your own.

## Read-only fallback (mode C)

Use this only when the user can't or won't clone the repo (Step 0). No checkout, no worktree,
no doc search, no reading full files. Review straight from `gh pr diff {number}` and
`gh pr view {number} --json files`. Say plainly that this is a diff-only review, so its
calls on correctness and maintainability are shallower.
