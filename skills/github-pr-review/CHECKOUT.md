# Checkout mechanics

Local code work uses **plain `git` only**. Never use `gh` for it. The PR `owner/repo` must
already match `origin`. Step 0 checks that. Fetch the PR head ref directly from origin. This
works for a fork PR too:

```
git fetch origin pull/<n>/head
```

Ask the user: **current dir** or **worktree**.

## Current dir

1. **Check for uncommitted changes** (`git status --porcelain`).
   - **The tree has changes** → tell the user, and **ask the user to confirm** before you change
     anything. After the user confirms:
     - Save the current branch with `git rev-parse --abbrev-ref HEAD`. Save the SHA too if the
       HEAD is detached.
     - Run `git stash --include-untracked` and **show the stash ref** to the user.
     - Name worktree mode as the cleaner option. The user may want to switch to it.
     - If the user refuses the stash, **stop**. Do not review on top of uncommitted changes.
   - **The tree is clean** → save the current branch only.
2. Check out the PR head:
   ```
   git fetch origin pull/<n>/head
   git checkout FETCH_HEAD        # or: git checkout -b pr-<n> FETCH_HEAD
   ```
3. **When the user says the review is done:**
   - **Ask** before you return to the original branch with `git checkout <original-branch>`. Do
     not switch on your own. The user may want to examine the PR further.
   - If you made a stash, **ask** before you run `git stash pop`. Never run it in silence. The
     user may now work on something else.

## Worktree

Follow the worktree setup convention in [[coding/worktree-setup]]. It gives the `.worktrees/`
ignore rule, the flattened dir name, and the `core.bare` check that runs directly after the add.
Then do the PR-specific part. Fetch the head into a local branch. Add the worktree from that
branch.

```
git fetch origin pull/<n>/head:pr-<n>
git worktree add .worktrees/pr-<n>--<short-desc> pr-<n>
```

`<short-desc>` is a kebab-case slug from the PR title. Run every later step from inside the
worktree dir.

**When the review is done:** leave the worktree on disk by default. A review often has follow-up
work. Tell the user the path, and print the teardown commands from the convention. Do not remove
the worktree on your own.

## Read-only fallback (mode C)

Use this mode only when the user cannot clone the repo, or refuses to (Step 0). It has no
checkout, no worktree, no doc search, and no full file reads. Review directly from `gh pr diff
{number}` and `gh pr view {number} --json files`. Say plainly that this is a diff-only review.
Its calls on correctness and maintainability are shallower.
