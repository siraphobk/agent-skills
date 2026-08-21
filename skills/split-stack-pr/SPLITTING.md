# Splitting mechanics

What [SKILL.md](SKILL.md) Phase 5 runs to move changes out of the original branch and onto a rung.
The original branch is read-only throughout — every command here reads *from* it and writes to the
rung you are standing on.

Names used below: `{orig}` the original big branch, `{base}` the trunk it forked from, `{parent}`
the rung below the one being built.

## Starting a rung

Always branch off the rung below, never off trunk:

```bash
git switch -c {rung} {parent}      # bottom rung: {parent} is {base}
```

## Method 1 — cherry-pick whole commits

Use when Phase 2 found that commits already line up with layers. It keeps the original authorship
and message, and it is the only method that survives a later `git rebase --update-refs` cleanly.

```bash
git cherry-pick {sha}              # one commit
git cherry-pick {sha1}^..{sha3}    # an inclusive range, oldest first
```

A conflict here means the commits are *not* as clean as they looked — stop, don't resolve by hand
into a state nobody planned. Report it and re-propose that rung with Method 2.

## Method 2 — copy whole files out of the original branch

Use when the commits are tangled across layers, which is the common case. This takes the file's
**final** state on `{orig}`, ignoring how it got there.

```bash
git checkout {orig} -- path/to/file.go path/to/other.go
git add -A && git commit -m "feat: ..."
```

The trap: a file copied at its final state may reference code that lands in a *later* rung. That is
what the feature-flag arrangement below is for — and why every rung runs the build.

## Method 3 — hunk-level splitting

Use for the files Phase 2 flagged as touched by more than one layer. Two ways, pick by size.

**Interactive, for a handful of hunks.** Bring the file in as a working-tree change, then stage
only the parts this rung owns:

```bash
git checkout {orig} -- path/to/file.go   # file now staged at its final state
git reset path/to/file.go                # unstage; changes stay in the working tree
git add -p path/to/file.go               # y/n per hunk, s to split, e to edit
git commit -m "feat: ..."
git checkout -- path/to/file.go          # discard the hunks that belong to a later rung
```

**Patch file, for many hunks or a repeatable split.** Write the diff out, delete the hunks that
belong elsewhere, apply what is left:

```bash
git diff {base}..{orig} -- path/to/file.go > /tmp/file.patch
# edit /tmp/file.patch — delete the hunks other rungs own, leave the @@ headers intact
git apply --3way /tmp/file.patch
```

`--3way` is what lets the patch apply even when the surrounding lines have moved. `git apply
--check` first if you want a dry run.

**Never hand-retype a hunk.** Copying it by eye is how a split silently loses a line.

## Deletions

A `D` row from `git diff --name-status` is not a file copy — copying does nothing, and the file
survives to the top of the stack. Remove it explicitly on the rung that owns it:

```bash
git rm path/to/dead_file.go
```

Renames show as `R` (or a `D` plus an `A`). Do both halves on the *same* rung, or the build breaks
on one of them.

## Making each rung safe to merge alone

Every PR must be mergeable on its own with **no user-visible behaviour change** until the last one.
Three arrangements, in order of preference:

1. **Dead code.** New functions, types, and tables land unreferenced. Nothing calls them until the
   wiring rung. Costs nothing, works for most splits.
2. **Feature flag.** The new path exists and is reachable, but the flag is off by default. The last
   PR in the stack flips the default. Use when the new code replaces an existing path rather than
   sitting beside it.
3. **Expand / contract.** For schema and API changes: the early rung adds the new column or field
   alongside the old one, the middle rungs move readers and writers over, a later PR (often after
   the stack merges) drops the old one. Never combine add and drop in one rung.

Whichever you pick, name it in the Phase 3 proposal — the reviewer needs to know why the code they
are reading appears to be called by nothing.

## Publishing without gh-stack

Phase 5 hands off to `github-pr-create`, which opens the stack natively. When the `gh-stack`
extension is missing, chain them by hand instead — bottom-up, one rung at a time, **after explicit
approval to push**:

```bash
git push -u origin {rung}
gh pr create --base {parent} --head {rung} --title "{title}" --body-file {path}
```

The body states the rung's position in the stack and links the other PRs, since GitHub renders no
chain of its own here. Say in one line that these are chained but not a native Stack, and name
`gh extension install github/gh-stack` for next time.
