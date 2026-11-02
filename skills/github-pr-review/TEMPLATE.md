# Code Review — PR #<number>: <title>

> Use this template to deliver findings. In chat, show it directly. When you save it, write to
> `.agents/scratch/reviews/pr-<number>.md`. Drop any section that is truly empty. Do not fill it
> with padding.
>
> **Anchors:** every finding cites `path:line`. Use `path:start-end` when the issue spans a
> range. **Big-PR mode** (see `BIG_PR.md`) adds two optional sections below: a **Chunk map** and
> a **Spec conformance** table. Use them only when you chunk the PR, or when a governing spec
> applies.
> Guided mode adds an objective assessment. It records evidence, not just walkthrough completion.
> Summary mode uses only the Context and Change summary sections. See `SUMMARY.md`.

## Context

- **PR:** #<number> — <title> (`<head_branch>` → `<base_branch>`)
- **Author:** <author>
- **Linked issues:** #<id> (<one-line title>), …
- **Claimed intent:** <1–3 sentences: what the PR says it does>
- **Acceptance criteria:** <testable requirements with sources. Label inferred criteria>
- **Docs consulted:** <paths or URLs with relevant sections, or "none found">
- **Context limits:** <conflicting sources, unavailable documentation, and accepted non-blocking gaps>

## Change summary

Write this section in every mode, after you read the implementation. A reader who stops here
must know what the PR does and why, without the diff. Do not copy the PR body.

**Why:** <The problem, who it affects, and why now. 1–3 sentences with sources. Label inferred
reasons as inferred.>

**What changed:**
- <A behavior change, stated as what a user or caller now sees> — `path:line`
- <3–7 bullets in order of importance. Group by behavior, not by file. One bullet can cover
  several files>
- <Last bullet: refactors, renames, generated code, and test-only changes, in one line>

**What did not change:** <Scope limits that a reader could assume wrongly. For example, "the API
contract stays the same". Drop this line when nothing is ambiguous.>

**Claim vs. code:** <Places where the PR body or the issue disagrees with the diff. Write "none
found" when they agree.>

**Read first:** <2–3 anchors, each with one reason, for a reader who has 5 minutes>

## Chunk map

> Use this section in Big-PR mode only. Drop it for a small PR.

| # | Chunk | Files reviewed | Status |
|---|-------|----------------|--------|
| A | <shared infra, review first> | `pkg/...`, … | ✅ / pending |
| B | <core feature logic> | `…/domain`, `…/app` | … |

## Objective assessment

Use this section in guided mode. It is optional in standard mode.
Cover every objective from the approved brief. Include governing clauses when a specification or architecture decision applies.
Keep objective IDs stable across the walkthrough and final report.

| Objective and source | Implementation | Verification evidence | Assessment |
|---|---|---|---|
| O1: <required behavior and source> | `path/to/file.go:line` | <assertion, observed scenario, or evidence gap> | <status and reason> |

- **met:** Evidence establishes the required behavior, including relevant failure conditions.
- **partially met:** Evidence establishes only some conditions. Name the unmet or uncertain part.
- **not met:** Evidence demonstrates a requirement violation. Cite the finding or mismatch.
- **unverified:** Available evidence cannot establish whether the objective holds. Name the missing evidence.

Distinguish source inspection, tests inspected, observed execution, and author-reported results.
For observed execution, record the scenario, expected result, actual result, and evidence source.
Never label an unrun test as passing. A passing suite alone does not establish runtime behavior.
Walkthrough completion measures review coverage, not correctness.

## Spec conformance

> Use this section only when a feature spec or ADR governs the change. Verify that each anchor
> still exists in the code.
If the objective assessment covers all governing clauses, omit this duplicate table and retain any severity reassessment below.

| Requirement (doc §) | Impl | ✓ |
|---------------------|------|---|
| <wire contract / invariant / MUST clause> | `path/to/file.go:line` | ✅ / ❌ / partial |

**Severity re-assessment from the doc:** <e.g. "documented consumer TTL backstop → a dropped
event is delayed revocation, not data loss → the two candidate blockers drop to Should-fix", or
"violates MUST §x → Nit upgraded to Blocker">

## Verdict

<One line. Examples: "Request changes — 2 blockers", "Approve with nits", "Approve". When a flag
gates the feature, separate "merge blocker" from "blocker to enabling in prod".>

| Severity | Count |
|----------|-------|
| 🔴 Blocker | <n> |
| 🟡 Should-fix | <n> |
| 🔵 Nit | <n> |

## Findings

Order the findings strictly by severity: Blocker → Should-fix → Nit. Within one severity, order
by the value hierarchy: **correctness → maintainability → performance**. Tag each finding with
the area it breaks, so the priority is clear. The tags are `correctness`, `tests`,
`maintainability`, `performance`, `security`, and `style`.
- A security bug is a correctness and safety bug. It goes 🔴 wherever it sits in the hierarchy.
- `tests` means missing or weak coverage. It is a correctness concern. It is Should-fix most of
  the time, and Blocker on invariant-heavy or domain code.

**Every finding uses one labelled shape.** Each part answers one question. Never repeat a fact
from an earlier part.

| Part | Question it answers |
|---|---|
| Header title | What is wrong, as a complete claim |
| `**Where:**` | Where the reader goes first: the `path:line` or `path:start-end` anchors |
| `**Problem:**` | What goes wrong, for which input, and who sees it |
| `**Why it happens:**` | The code path, step by step |
| `**Evidence:**` | How we know: source inspection, tests inspected, observed execution, or author report |
| `**Why this severity:**` | Why the grade is right, when it is not obvious |
| `**Fix:**` | The direction, the preferred option and its reason, and what must not change |

- **The title is a claim, not a topic.** Write "`GetOrder` panics when the cache holds a deleted
  customer", not "nil deref". A reader who scans only the titles sees every problem.
- **Explain so the reader does not need to open the code.** Name the function, the input, the
  state, and the result. Use concrete values. Define an uncommon term once. Show a snippet when
  it makes the code path clear.
- **There is no length limit.** Each sentence must add a fact. Give the strongest reason for a
  claim, then stop. Use a table when the evidence is enumerable.
- **Leave out a part that has nothing to say.** A nit often needs only Where, Problem, and Fix.
  Always keep Where, Problem, and Fix.
- **Start each label on its own paragraph.** Keep technical terms and identifiers. Plain is not
  vague.

A worked example with fictional code:

~~~~markdown
#### B1 — `GetOrder` panics when the cache holds a deleted customer · `correctness`

**Where:** `order/service.go:88`, `cache/customer.go:41-47`

**Problem:** A request for an order whose customer was deleted makes the handler panic on a nil
pointer. The client gets a 500 response, and every retry fails the same way. All orders of
deleted customers are affected.

**Why it happens:** When the database returns no row, `cache/customer.go:41-47` stores `nil`. A
later lookup then returns `(nil, true)`. `order/service.go:88` checks only the `ok` flag, and then
reads `c.Name` on the nil pointer.

```go
c, ok := s.cache.Get(id)
if ok {
    name = c.Name // c is nil for a deleted customer
}
```

**Evidence:** Source inspection only. No test covers a deleted customer. The scenario was not run.

**Fix:** Stop caching `nil` in `cache/customer.go`. This is better than a nil check at line 88,
because three other callers use the same lookup. Keep the cache key format the same, because the
eviction job parses it.
~~~~

## Posting keeps this exact shape

**An inline comment is the finding, whole.** It keeps the `**Where:**` line, every labelled part,
the tables, and the code blocks. Do NOT compress it into prose for the narrow column of GitHub.
That compression looks like a reasonable call, and it is not one. It costs two things:
- It drops the anchor list, so the other files a finding touches become invisible.
- It removes the labels that let a reader go straight to the part they need, such as the fix.

The shape *is* the deliverable. A reader on the PR must see what a reader of the saved report
sees. Length is fine. GitHub renders long comments without complaint.

**Generate every comment body from the saved report file. Never re-type one.** Split the report
on its `#### <ID> — <title> · <tags>` headers. Take everything up to the next `####` or `###`.
Post that text verbatim under a `**<ID> · <Severity> · <tags>** — <title>` line. This gives two
payoffs. The PR and the report cannot drift. A re-post after an edit is a regeneration, not
rework. Assert that every finding ID resolved to a section before you build the payload. A
missing ID posts an incomplete review, and nothing warns you.

**Prune before you post. Do not shorten.** When the finding set is large, drop whole findings and
keep the survivors at full depth. The user may say "blockers and should-fix only, skip the nits".
Record the dropped findings in the report as a compact "raised and dropped" table. Give the ID, a
one-line claim, and the `path:line`. A later pass then does not rediscover them as new. **If a
surviving finding cross-refers to a dropped one, copy that content in and delete the reference.**
A comment that points at an ID nobody can see is worse than no reference.

### The API calls

Get the head SHA. Then post the body and every inline comment in **one** call:

```bash
gh pr view {number} --json headRefOid --jq '.headRefOid'

gh api repos/{owner}/{repo}/pulls/{number}/reviews -X POST --input - << 'PAYLOAD'
{
  "commit_id": "<head_sha>",
  "event": "COMMENT",
  "body": "<verdict, severity table, and what's good>",
  "comments": [
    {"path": "file.go", "line": 123, "side": "RIGHT", "body": "**B1 · Blocker · `correctness`** — `GetOrder` panics when the cache holds a deleted customer\n\n**Where:** …\n\n**Problem:** …"}
  ]
}
PAYLOAD
```

- **`side`**: use `RIGHT` for a line in the new file. That is the default. Use `LEFT` for a
  deleted line.
- **`event`**: `COMMENT` by default. Use `REQUEST_CHANGES` only with at least 1 Blocker and the
  agreement of the user. Never use `APPROVE`.
- **A reply is a separate call.** It is not part of the review payload:
  ```bash
  gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies -X POST -f body='…'
  ```
- **To edit a comment you already posted:** `gh api repos/{owner}/{repo}/pulls/comments/{id} -X PATCH`.

### 🔴 Blockers

#### B1 — <the defect as a complete claim> · `correctness` | `security`

**Where:** `path/to/file.go:123`, `path/to/other.go:45`

**Problem:** <What goes wrong, for which input, and who sees it: wrong result, data loss, auth
bypass, or broken invariant.>

**Why it happens:** <The code path, step by step, and the exact call that misbehaves. Add a
snippet when it helps.>

**Evidence:** <Source inspection, tests inspected, observed execution, or author report. Label
what is not verified.>

**Fix:** <The minimal direction, not a rewrite. The preferred option and why. What must not
change.>

### 🟡 Should-fix

#### S1 — <the problem as a complete claim> · `maintainability` | `correctness`

**Where:** `path/to/file.go:45`

**Problem:** <What goes wrong, and its cost to the next maintainer.>

**Why it happens:** <The code path or design that causes it.>

**Evidence:** <How we know.>

**Why this severity:** <What limits the damage, so it is not a blocker. The remaining risk that
makes it worth fixing.>

**Fix:** <Direction and constraints.>

### 🔵 Nits

#### N1 — <the problem as a complete claim> · `style` | `performance`

**Where:** `path/to/file.go:9`

**Problem:** <One or two sentences. A perf issue that is not a priority lives here.>

**Fix:** <Direction. Add why you do NOT recommend the obvious bigger change, when that applies.>

## What is good

<Optional. 1–3 bullets on good choices worth keeping. This keeps the review balanced, so it does
not sound all-negative.>

## Open questions

<Anything you need the author to explain before the verdict is final, if any.>
