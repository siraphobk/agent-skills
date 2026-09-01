# Stacked PR mechanics

[SKILL.md](SKILL.md) uses this file when the branch sits on another feature branch instead of
trunk. This needs the `gh-stack` extension. Install it with `gh extension install github/gh-stack`.

This skill **creates** a stack. It does not maintain one. The `sync`, `rebase`, `modify`, and
`merge` commands belong to `gh stack` itself. Run them directly.

## Detect the chain

There are two paths. Try the cheap one first.

```bash
gh stack view --json
```

Output means the stack already has local tracking. Use that order and skip the walk. The message
`is not part of a stack` means there is no local tracking. Then use the walk below. Match on that
text, not on the exit code.

In the walk, a rung is a local branch. It must be an **ancestor of HEAD**. It must not be an
**ancestor of trunk**. The second test drops trunk itself. It also drops any stale branch that
sits on trunk's history.

```bash
cur=$(git branch --show-current); base=main   # base from MECHANICS.md
git for-each-ref --format='%(refname:short)' refs/heads/ | while read -r b; do
  [ "$b" = "$cur" ] || [ "$b" = "$base" ] && continue
  git merge-base --is-ancestor "$b" HEAD  2>/dev/null || continue
  git merge-base --is-ancestor "$b" "$base" 2>/dev/null && continue
  echo "$(git rev-list --count "$b") $b"
done | sort -n
```

The commit count sorts the rungs from the bottom to the top. Add the current branch as the top
rung. The base of each rung is the rung below it. The base of the bottom rung is trunk.

Two branches on the *same* commit tie, and they then sort in an arbitrary order. If the counts
collide, show the user the chain and ask for the order. Do not guess.

## Find which rungs already have PRs

```bash
gh pr list --head {branch} --state open --json number,url,baseRefName
```

Reuse an existing PR. Never duplicate one. Empty output means the rung needs a PR.

## Diff a rung

Diff each rung against **its own parent**, not against trunk.

```bash
git diff {parent}..{branch}
```

`{base}..HEAD` would also show every rung below it. That is what makes a hand-rolled stacked PR
hard to review.

## Create the stack

`gh stack link` takes the branches from the bottom to the top. One non-interactive call pushes
them, chains the base branches, opens any missing PRs, and builds the native Stack on GitHub.

```bash
gh stack link --open {rung1} {rung2} {rung3}
```

- `--open` marks the PRs ready for review. Without it, the new PRs are created as drafts.
- Add `--base {trunk}` when the bottom rung targets something other than the repo default.
- **Use `link`, never `submit`.** `submit` opens a full-screen editor in a terminal, and that hangs
  an agent session. Its `--auto` option replaces the drafted titles with generated ones.

`link` sets no title and no body. Install the drafted content for each rung afterwards.

```bash
gh pr edit {number} --title "{title}" --body-file .agents/scratch/draft-prs/{filename}
```

## No native stack is available

The extension is missing, or the repo has stacks turned off. Use plain chaining instead. Push each
branch, then make one call per rung from the bottom to the top.

```bash
gh pr create --base {parent} --head {branch} --title "{title}" --body "{body}"
```

Say in one line that the PRs are chained but are not a GitHub Stack. Name the install command too.

## Warn the user about these once

- **Merge from the bottom to the top.** A rung cannot merge before the rung below it.
- **A squash-merge of a rung forces a rebase above it.** The squashed commit does not match the
  history that the rungs above carry. `gh stack sync` handles this.
- **GitHub retargets the child PRs** when someone deletes a merged rung's branch. The stack
  survives.
