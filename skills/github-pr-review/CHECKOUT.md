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

1. Check that this is a non-bare working-tree clone before setup:

   ```
   project_root="$(git rev-parse --show-toplevel)" || {
     printf '%s\n' 'Worktree mode requires a non-bare clone.'
     exit 1
   }
   if [ "$(git rev-parse --is-bare-repository)" = true ]; then
     printf '%s\n' 'Worktree mode requires a non-bare clone.'
     exit 1
   fi
   ```

   If either command cannot establish a non-bare working-tree root, stop. Do not create a partial
   worktree.

2. Set the one review path. `<short-desc>` is a kebab-case slug from the PR title:

   ```
   worktree_path="$project_root/.worktrees/pr-<n>--<short-desc>"
   ```

3. Before creation, check the path and inspect registered worktrees:

   ```
   if [ -e "$worktree_path" ] || [ -L "$worktree_path" ]; then
     printf 'Review worktree already exists: %s\n' "$worktree_path"
     exit 1
   fi
   git worktree list --porcelain
   ```

   If the output contains `worktree <worktree-path>`, stop and report that path. Do not reuse,
   overwrite, remove, or prune a prior review worktree.

4. Keep the main checkout clean without changing tracked files:

   ```
   exclude_path="$(git rev-parse --git-path info/exclude)"
   if ! git check-ignore -q --no-index .worktrees/; then
     if ! test -f "$exclude_path" ||
       ! grep -Fxq '/.worktrees/' "$exclude_path"; then
       printf '/.worktrees/\n' >> "$exclude_path"
     fi
   fi
   ```

5. Fetch the PR head without creating a local branch, then add a detached worktree:

   ```
   git fetch origin pull/<n>/head
   git worktree add --detach "$worktree_path" FETCH_HEAD
   ```

Run every later local command from inside `$worktree_path`.

**When the review is done:** leave the worktree in place. Report its exact path and print
`git worktree remove <worktree-path>` as the manual teardown command. Do not remove the worktree
or run `git worktree prune` automatically.

## Read-only fallback (mode C)

Use this mode only when the user cannot clone the repo, or refuses to (Step 0). It has no
checkout, no worktree, no doc search, and no full file reads. Review directly from `gh pr diff
{number}` and `gh pr view {number} --json files`. Say plainly that this is a diff-only review.
Its calls on correctness and maintainability are shallower.
