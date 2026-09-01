# Code Review — PR #<number>: <title>

> Use this template to deliver findings. In chat, show it directly. When you save it, write to
> `.agents/scratch/reviews/pr-<number>.md`. Drop any section that is truly empty. Do not fill it
> with padding.
>
> **Anchors:** every finding cites `path:line`. Use `path:start-end` when the issue spans a
> range. **Big-PR mode** (see `BIG_PR.md`) adds two optional sections below: a **Chunk map** and
> a **Spec conformance** table. Use them only when you chunk the PR, or when a governing spec
> applies.

## Context

- **PR:** #<number> — <title> (`<head_branch>` → `<base_branch>`)
- **Author:** <author>
- **Linked issues:** #<id> (<one-line title>), …
- **Claimed intent:** <1–3 sentences: what the PR says it does>
- **Acceptance criteria:** <from linked issues, if any. Bullet the testable ones>
- **Docs consulted:** <relative/path.md>, … (or "none found")

## Chunk map

> Use this section in Big-PR mode only. Drop it for a small PR.

| # | Chunk | Files reviewed | Status |
|---|-------|----------------|--------|
| A | <shared infra, review first> | `pkg/...`, … | ✅ / pending |
| B | <core feature logic> | `…/domain`, `…/app` | … |

## Spec conformance

> Use this section only when a feature spec or ADR governs the change. Verify that each anchor
> still exists in the code.

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

**Every finding has two labelled layers.** Never ship only one layer. A bare summary is too terse
to act on with confidence. Detail with no summary hides the point.

1. **`**Where:**` line.** Put the `path:line` anchors first, so the reader goes directly there.
2. **`**SUMMARY**`.** Use 5 sentences at most. State the defect, its impact, and the fix
   direction. End on a `Fix:` clause. A reader who stops here can still act.
3. **`**DETAILED EXPLANATION**`.** Give the mechanism, the evidence, the constraints, and the
   cross-references. Use bolded mini-headings such as `**How it happens.**`, `**Why it is not a
   blocker.**`, and `**Implementation notes.**`. Use a table where the evidence is enumerable.
   Drop this layer, heading and all, when there is nothing more to say. That is common for a nit.

Both labels go on their own line, with a blank line after. The two layers then stay visually
separate when the detail runs long.

**Density rules for both layers.** Write plain English. Give no preamble and no recap. Keep the
technical terms and code (race, nil, N+1, invariant, identifiers, `snippets`). Plain ≠ vague.
**One reason per claim:** give the strongest reason, then stop. The same point argued three ways
is padding. Detail earns its place with *new* information: a mechanism, a table, a constraint, or
the line that settles it. Detail never earns its place as a longer restatement of the summary.

## Posting keeps this exact shape

**An inline comment is the finding, whole.** It keeps `**Where:**`, `**SUMMARY**`,
`**DETAILED EXPLANATION**`, the mini-headings, the tables, and the code blocks. Do NOT compress
it into prose for the narrow column of GitHub. That compression looks like a reasonable call, and
it is not one. It costs three things:
- It drops the anchor list, so the other files a finding touches become invisible.
- It removes the labelled stopping point, so the reader must read all of it.
- It dissolves the mini-headings that let someone skip to "what it affects".

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
    {"path": "file.go", "line": 123, "side": "RIGHT", "body": "**B1 · Blocker · `correctness`** — nil deref when the cache misses\n\n**Where:** …\n\n**SUMMARY**\n\n…"}
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

#### B1 — <short title> · `correctness` | `security`

**Where:** `path/to/file.go:123`, `path/to/other.go:45`

**SUMMARY**

<The defect and its impact: wrong result, data loss, auth bypass, or broken invariant. Then the
direction. 5 sentences at most. Fix: <minimal direction, not a rewrite>.>

**DETAILED EXPLANATION**

**<How it happens.>** <the mechanism: the code path, and the exact call that misbehaves>

**<What it affects.>** <scope: which services or callers. Use a table when enumerable>

**<Implementation notes.>** <constraints on the fix: bounds, ordering, what must NOT change>

### 🟡 Should-fix

#### S1 — <short title> · `maintainability` | `correctness`

**Where:** `path/to/file.go:45`

**SUMMARY**

<The problem, its cost to the next maintainer, and the direction. Fix: <direction>.>

**DETAILED EXPLANATION**

**<Why it is not a blocker.>** <what limits the damage. This is often the most useful line in the finding>

**<Why it is still worth fixing.>** <the residual risk or cost>

### 🔵 Nits

#### N1 — <short title> · `style` | `performance`

**Where:** `path/to/file.go:9`

**SUMMARY**

<One or two sentences. Non-blocking. A perf issue that is not a priority lives here.>

**DETAILED EXPLANATION**

<Only when there is more to say. For example, why you do NOT recommend the obvious bigger change.
Otherwise omit this heading and its content entirely.>

## What is good

<Optional. 1–3 bullets on good choices worth keeping. This keeps the review balanced, so it does
not sound all-negative.>

## Open questions

<Anything you need the author to explain before the verdict is final, if any.>
