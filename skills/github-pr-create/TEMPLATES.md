# PR template shapes

This file holds five literal shapes that [SKILL.md](SKILL.md) fills in. The last two shapes are for
a stack only. SKILL.md holds every decision about *which* shape to use. This file holds only the
shapes themselves.

## Default PR body (no repo template)

Use this shape when Step 2 found no `.github/PULL_REQUEST_TEMPLATE*`. Each section names what feeds
it. The Step 3 deliverable feeds it when there is one. The diff feeds it when there is not.

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

Write this file to `.agents/scratch/draft-prs/{filename}`. The title and the base live in the
header. The user can check them there and does not need to read the body.

```markdown
# PR Draft — {branch name}

**Title:** {pr title}

**Base branch:** {base}

---

{pr body}
```

## Confirm block

Print this block in chat for a single PR, after you write the draft file. Stop here. Step 6 needs a
separate approval for both the push and the PR.

```
Draft written to .agents/scratch/draft-prs/{filename}
Title: {pr title}
Base: {base} ← {branch}

Review the draft. Say "looks good" or "create the PR" to proceed,
or tell me what to change.
```

## Stack draft file wrapper

Write one file per rung, at the same path as above. The header carries the rung's position and its
parent. The user can check the chain there and does not need to open the other drafts.

```markdown
# PR Draft — {branch name}

**Title:** {pr title}

**Base branch:** {parent branch}

**Stack:** rung {n} of {total} — {"bottom, targets trunk" | "sits on {parent}"}

---

{pr body}
```

Put no stack navigation section in the body. GitHub's native Stack renders the chain itself. A
hand-written table would duplicate the chain, and it would go out of date as the stack changes.

## Stack confirm block

This block replaces the single-PR confirm block when you detect a chain. It shows the whole stack.
It marks which rungs already have PRs. It names every branch that `gh stack link` will push.

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
