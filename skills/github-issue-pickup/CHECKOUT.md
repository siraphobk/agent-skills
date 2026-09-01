# Checkout mechanics

This file shows how Step 7 of [SKILL.md](SKILL.md) moves you to the new branch. There are
two shapes. The user selected one of them at Step 6. Find the project root first:

```bash
git rev-parse --show-toplevel
```

## Worktree

Follow the worktree setup convention in [[coding/worktree-setup]]. It has three parts: the
`.worktrees/` ignore rule, the flattened dir name, and the `core.bare` check. The
`core.bare` check runs immediately after the add. Here the add also creates the branch, so
a separate fetch is not necessary:

```bash
git worktree add {project_root}/.worktrees/{prefix}-{number}--{short_description} -b {prefix}-{number}/{short_description}
```

Report the worktree path so the user can `cd` into it.

## Plain checkout

```bash
git checkout -b {prefix}-{number}/{short_description}
```

There are no ignore rules and no `core.bare` risk. The working directory is now on the new
branch.
