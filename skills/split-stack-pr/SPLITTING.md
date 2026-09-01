# Split mechanics

Phase 5 of [SKILL.md](SKILL.md) runs these commands. They move changes out of the original branch
and onto a rung. The original branch stays read-only throughout. Every command here reads *from*
the original branch. Every command writes to the rung that you stand on.

This file uses three names. `{orig}` is the original big branch. `{base}` is the trunk that it
forked from. `{parent}` is the rung below the rung that you build.

## Start a rung

Always branch from the rung below. Never branch from the trunk.

```bash
git switch -c {rung} {parent}      # bottom rung: {parent} is {base}
```

## Method 1: cherry-pick whole commits

Use this method when Phase 2 found that the commits already match the layers. It keeps the original
authorship and message. It is also the only method that survives a later `git rebase --update-refs`
cleanly.

```bash
git cherry-pick {sha}              # one commit
git cherry-pick {sha1}^..{sha3}    # an inclusive range, oldest first
```

A conflict here means the commits are *not* as clean as they looked. Stop. Do not resolve the
conflict by hand into a state that nobody planned. Report the conflict, and propose that rung again
with Method 2.

## Method 2: copy whole files out of the original branch

Use this method when the commits are tangled across layers. That is the common case. The method
takes the **final** state of the file on `{orig}`. It ignores how the file reached that state.

```bash
git checkout {orig} -- path/to/file.go path/to/other.go
git add -A && git commit -m "feat: ..."
```

There is one trap. A file that you copy at its final state may reference code that lands in a
*later* rung. The feature-flag arrangement below handles that case. It is also the reason that
every rung runs the build.

## Method 3: split a file by hunk

Use this method for the files that Phase 2 flagged. Those are the files that more than one layer
touches. There are two ways. Pick one by size.

**The interactive way suits a few hunks.** Move the file into the working tree as a change. Then
stage only the parts that this rung owns.

```bash
git checkout {orig} -- path/to/file.go   # file now staged at its final state
git reset path/to/file.go                # unstage; changes stay in the working tree
git add -p path/to/file.go               # y/n per hunk, s to split, e to edit
git commit -m "feat: ..."
git checkout -- path/to/file.go          # discard the hunks that belong to a later rung
```

**The patch-file way suits many hunks, or a split that you must repeat.** Write the diff to a file.
Delete the hunks that belong elsewhere. Then apply what is left.

```bash
git diff {base}..{orig} -- path/to/file.go > /tmp/file.patch
# edit /tmp/file.patch — delete the hunks other rungs own, leave the @@ headers intact
git apply --3way /tmp/file.patch
```

`--3way` lets the patch apply even when the lines around it have moved. Run `git apply --check`
first if you want a dry run.

**Never retype a hunk by hand.** A copy by eye is how a split loses a line in silence.

## Deletions

A `D` row from `git diff --name-status` is not a file copy. A copy does nothing, and the file
survives to the top of the stack. Remove the file explicitly on the rung that owns it.

```bash
git rm path/to/dead_file.go
```

Renames show as `R` (or a `D` plus an `A`). Do both halves on the *same* rung, or the build breaks
on one of them.

## Make each rung safe to merge alone

Every PR must be mergeable on its own. Users see **no behaviour change** until the last PR. Here
are three arrangements, in order of preference.

1. **Dead code.** New functions, types, and tables land with nothing that references them. Nothing
   calls them before the wiring rung. This costs nothing, and it works for most splits.
2. **Feature flag.** The new path exists and code can reach it, but the flag is off by default. The
   last PR in the stack changes the default. Use this when the new code replaces an existing path
   instead of a path that sits beside the old one.
3. **Expand / contract.** Use this for schema and API changes. The early rung adds the new column
   or field next to the old one. The middle rungs move readers and writers to the new one. A later
   PR drops the old one, often after the stack merges. Never combine an add and a drop in one rung.

Name your choice in the Phase 3 proposal. The reviewer needs to know why nothing appears to call
the code that they read.
