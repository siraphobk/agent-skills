# PR Templates — the output shapes

Five literal shapes [SKILL.md](SKILL.md) fills in — the last two are stack-only. Every branch about
*which* shape to use lives in SKILL.md; this file only holds the shapes themselves.

## Default PR body (no repo template)

Used when Step 2 found no `.github/PULL_REQUEST_TEMPLATE*`. Each section names what feeds it —
the Step 3 deliverable when there is one, the diff when there isn't.

```markdown
## Summary
<2-4 bullet points of what changed — from the deliverable's Summary when there is one>

## Breaking Changes
<list any breaking changes, or "None">

## Closes
Closes #{issue_number}
<omit this section if no issue number>

## Test Plan
<the deliverable's Verification output — real commands and their results — or, with no
deliverable, a brief checklist of how to verify this PR>

## Out of scope
<the deliverable's "Not done / follow-ups" — omit the section entirely when there is no
deliverable or the list is empty>
```

## Draft file wrapper

Written to `.agents/scratch/draft-prs/{filename}`. The title and base live in the header so the
user can check them without re-reading the body.

```markdown
# PR Draft — {branch name}

**Title:** {pr title}

**Base branch:** {base}

---

{pr body}
```

## Confirm block

Printed in chat once the draft file is written, for a single PR. Stop here — Step 6 needs a
separate go for the push and the PR both.

```
Draft written to .agents/scratch/draft-prs/{filename}
Title: {pr title}
Base: {base} ← {branch}

Review the draft. Say "looks good" or "create the PR" to proceed,
or tell me what to change.
```

## Stack draft file wrapper

One file per rung, same path as above. The header carries the rung's position and its parent, so
the user can check the chain without opening the other drafts.

```markdown
# PR Draft — {branch name}

**Title:** {pr title}

**Base branch:** {parent branch}

**Stack:** rung {n} of {total} — {"bottom, targets trunk" | "sits on {parent}"}

---

{pr body}
```

No stack navigation section goes in the body. GitHub's native Stack renders the chain itself; a
hand-written table would duplicate it and drift as the stack changes.

## Stack confirm block

Replaces the single-PR confirm block when a chain was detected. Shows the whole stack, marks which
rungs already have PRs, and names every branch `gh stack link` will push.

```
Detected stack ({total} rungs, {n} PR(s) to create):

  {trunk}
   └── {rung1}   → PR #{num} (exists)
        └── {rung2}   → no PR   base: {rung1}
             └── {rung3}   → no PR   base: {rung2}

Drafts written:
  .agents/scratch/draft-prs/{file2}
  .agents/scratch/draft-prs/{file3}

Review the drafts. Creating them runs `gh stack link`, which pushes
{list of branches} to {remote} and opens {n} PR(s) as a GitHub Stack.

Say "create the stack" to proceed, or tell me what to change.
```
