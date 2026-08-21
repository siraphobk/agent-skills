# Stacked PRs — the mechanics

What [SKILL.md](SKILL.md) uses when the branch sits on another feature branch instead of trunk.
Needs the `gh-stack` extension (`gh extension install github/gh-stack`).

This skill **creates** a stack. It does not maintain one — `sync`, `rebase`, `modify`, and `merge`
belong to `gh stack` itself, run directly.

## Detecting the chain

Two paths. Try the cheap one first:

```bash
gh stack view --json
```

Output means the stack is already tracked locally — use that order and skip the walk. The message
`is not part of a stack` means no local tracking; fall back to the walk below. Match on that text,
not the exit code.

The walk: a rung is a local branch that is an **ancestor of HEAD** but **not an ancestor of trunk**.
That second test is what drops trunk itself and any stale branch parked on trunk's history.

```bash
cur=$(git branch --show-current); base=main   # base from MECHANICS.md
git for-each-ref --format='%(refname:short)' refs/heads/ | while read -r b; do
  [ "$b" = "$cur" ] || [ "$b" = "$base" ] && continue
  git merge-base --is-ancestor "$b" HEAD  2>/dev/null || continue
  git merge-base --is-ancestor "$b" "$base" 2>/dev/null && continue
  echo "$(git rev-list --count "$b") $b"
done | sort -n
```

Commit count sorts the rungs bottom-up. Append the current branch as the top rung. Each rung's base
is the rung below it; the bottom rung's base is trunk.

Two branches on the *same* commit tie and sort arbitrarily — if the counts collide, show the user
the chain and ask for the order rather than guessing.

## Which rungs already have PRs

```bash
gh pr list --head {branch} --state open --json number,url,baseRefName
```

An existing PR is reused, never duplicated. Empty output means the rung needs one.

## Diffing a rung

Diff each rung against **its own parent**, not trunk:

```bash
git diff {parent}..{branch}
```

`{base}..HEAD` would show every rung below it too, which is what makes a hand-rolled stacked PR
unreviewable.

## Creating the stack

`gh stack link` takes branches bottom to top. It pushes them, chains the base branches, opens any
missing PRs, and builds the native Stack on GitHub — in one non-interactive call:

```bash
gh stack link --open {rung1} {rung2} {rung3}
```

- `--open` marks the PRs ready for review; without it new PRs are created as drafts.
- `--base {trunk}` if the bottom rung targets something other than the repo default.
- **Use `link`, never `submit`.** `submit` opens a full-screen editor in a terminal, which hangs an
  agent session, and its `--auto` escape hatch replaces the drafted titles with generated ones.

`link` sets no title or body, so install the drafted content per rung afterwards:

```bash
gh pr edit {number} --title "{title}" --body-file .agents/scratch/draft-prs/{filename}
```

## No native stack available

Extension missing, or the repo has stacks turned off. Fall back to plain chaining — one call per
rung, bottom-up, after pushing each branch:

```bash
gh pr create --base {parent} --head {branch} --title "{title}" --body "{body}"
```

Say in one line that the PRs are chained but not a GitHub Stack, and name the install command.

## What to warn about once

- **Merge bottom-up.** A rung can't merge before the rung below it.
- **Squash-merging a rung forces a rebase above it** — the squashed commit doesn't match the
  history the rungs above carry. `gh stack sync` handles it.
- **GitHub retargets children** when a merged rung's branch is deleted, so the stack survives.
