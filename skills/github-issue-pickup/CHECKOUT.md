# Checkout mechanics

How [SKILL.md](SKILL.md) Step 7 puts you on the new branch. Two shapes — the user picked one at
Step 6. Find the project root first:

```bash
git rev-parse --show-toplevel
```

## Worktree

Follow the worktree setup convention in [[coding/worktree-setup]] — the `.worktrees/` ignore
rule, the flattened dir name, and the `core.bare` check that runs right after the add. Here the
add creates the branch too, so there's no separate fetch:

```bash
git worktree add {project_root}/.worktrees/{prefix}-{number}--{short_description} -b {prefix}-{number}/{short_description}
```

Report the worktree path so the user can `cd` into it.

## Plain checkout

```bash
git checkout -b {prefix}-{number}/{short_description}
```

No ignore rules, no `core.bare` risk. The working directory is now on the new branch.
