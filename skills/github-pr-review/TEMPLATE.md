# Code Review — PR #<number>: <title>

> Use this template to deliver findings. In chat, show it directly. When saving, write to
> `.agents/scratch/reviews/pr-<number>.md`. Drop any section that's truly empty instead of
> filling it with padding.
>
> **Anchors:** every finding cites `path:line` — use `path:start-end` when the issue spans a
> range. **Big-PR mode** (see `BIG_PR.md`) adds two optional sections below: a **Chunk map** and
> a **Spec conformance** table. Use them only when chunking / a governing spec applies.

## Context

- **PR:** #<number> — <title> (`<head_branch>` → `<base_branch>`)
- **Author:** <author>
- **Linked issues:** #<id> (<one-line title>), …
- **Claimed intent:** <1–3 sentences: what the PR says it does>
- **Acceptance criteria:** <from linked issues, if any — bullet the testable ones>
- **Docs consulted:** <relative/path.md>, … (or "none found")

## Chunk map

> Big-PR mode only. Drop for small PRs.

| # | Chunk | Files reviewed | Status |
|---|-------|----------------|--------|
| A | <shared infra — review first> | `pkg/...`, … | ✅ / pending |
| B | <core feature logic> | `…/domain`, `…/app` | … |

## Spec conformance

> Only when a feature spec / ADR governs the change. Verify each anchor still exists in the code.

| Requirement (doc §) | Impl | ✓ |
|---------------------|------|---|
| <wire contract / invariant / MUST clause> | `path/to/file.go:line` | ✅ / ❌ / partial |

**Severity re-assessment from the doc:** <e.g. "documented consumer TTL backstop → a dropped
event is delayed revocation, not data loss → the two candidate blockers drop to Should-fix" — or
"violates MUST §x → Nit upgraded to Blocker">

## Verdict

<One line: e.g. "Request changes — 2 blockers" / "Approve with nits" / "Approve". When the
feature is flag-gated, distinguish "merge blocker" from "blocker to enabling in prod".>

| Severity | Count |
|----------|-------|
| 🔴 Blocker | <n> |
| 🟡 Should-fix | <n> |
| 🔵 Nit | <n> |

## Findings

Order strictly by severity (Blocker → Should-fix → Nit). Within one severity, order by the
value hierarchy: **correctness → maintainability → performance**. Tag each finding with the
area it breaks so the priority is clear — one of `correctness`, `tests`, `maintainability`,
`performance`, `security`, `style`.
- Security bugs are correctness/safety and go 🔴 no matter where they sit in the hierarchy.
- `tests` (missing or weak coverage) is a correctness concern — Should-fix most of the time,
  Blocker on invariant-heavy or domain code.

**Every finding is two labelled layers.** Never ship only one: a bare summary is too terse to act on
with confidence, and detail with no summary buries the point.

1. **`**Where:**` line** — `path:line` anchors first, so the reader can jump straight there.
2. **`**SUMMARY**`** — ≤5 sentences stating the defect, its impact, and the fix direction, ending on a
   `Fix:` clause. A reader who stops here can still act.
3. **`**DETAILED EXPLANATION**`** — mechanism, evidence, constraints, cross-references. Use bolded
   mini-headings (`**How it happens.**`, `**Why it is not a blocker.**`, `**Implementation notes.**`)
   and tables where the evidence is enumerable. Drop this layer, heading and all, when there is
   nothing more to say — common for nits.

Both labels go on their own line with a blank line after, so the two layers stay visually separable
when the detail runs long.

**Density rules for both layers.** Plain English, no preamble or recap. Keep the technical terms and
code (race, nil, N+1, invariant, identifiers, `snippets`) — plain ≠ vague. **One reason per claim:**
give the strongest reason and move on; arguing the same point three ways is padding. Detail earns its
place by adding *new* information — a mechanism, a table, a constraint, the line that settles it —
never by restating the summary at greater length.

## Posting keeps this exact shape

**An inline comment is the finding, whole — `**Where:**`, `**SUMMARY**`, `**DETAILED EXPLANATION**`,
mini-headings, tables, code blocks and all.** Do NOT compress it into prose for GitHub's narrow
column. That compression looks like a reasonable call and is not one: it drops the anchor list (so
the other files a finding touches go invisible), removes the labelled stopping point (so the reader
must read all of it), and dissolves the mini-headings that let someone skip to "what it affects".
The shape *is* the deliverable — a reader on the PR should see what a reader of the saved report
sees. Length is fine; GitHub renders long comments without complaint.

**Generate comment bodies from the saved report file, never by re-typing them.** Split the report on
its `#### <ID> — <title> · <tags>` headers, take everything up to the next `####`/`###`, and post that
verbatim under a `**<ID> · <Severity> · <tags>** — <title>` line. Two payoffs: the PR and the report
cannot drift, and re-posting after an edit is regeneration rather than rework. Assert every finding
ID resolved to a section before building the payload — a silently missing ID posts an incomplete
review.

**Prune before posting, don't shorten.** When the finding set is large, drop whole findings (the user
may say "blockers and should-fix only, skip the nits") and keep the survivors at full depth. Record
dropped ones in the report as a compact "raised and dropped" table with ID, one-line claim, and
`path:line`, so a later pass does not rediscover them as new. **If a surviving finding cross-refers
to a dropped one, fold that content in and delete the reference** — a comment pointing at an ID
nobody can see is worse than no reference.

### The API calls

Get the head SHA, then post body + every inline comment in **one** call:

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

- **`side`** — `RIGHT` for lines in the new file (the default); `LEFT` for deleted lines.
- **`event`** — `COMMENT` by default. `REQUEST_CHANGES` only with ≥1 Blocker and the user's
  opt-in. Never `APPROVE`.
- **Replies are a separate call** — they are not part of the review payload:
  ```bash
  gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/replies -X POST -f body='…'
  ```
- **Editing one you already posted:** `gh api repos/{owner}/{repo}/pulls/comments/{id} -X PATCH`.

### 🔴 Blockers

#### B1 — <short title> · `correctness` | `security`

**Where:** `path/to/file.go:123`, `path/to/other.go:45`

**SUMMARY**

<Defect, impact — wrong result, data loss, auth bypass, broken invariant — and direction, ≤5
sentences. Fix: <minimal direction, not a rewrite>.>

**DETAILED EXPLANATION**

**<How it happens.>** <mechanism — the code path, the exact call that misbehaves>

**<What it affects.>** <scope: which services or callers; a table when enumerable>

**<Implementation notes.>** <constraints on the fix: bounds, ordering, what must NOT change>

### 🟡 Should-fix

#### S1 — <short title> · `maintainability` | `correctness`

**Where:** `path/to/file.go:45`

**SUMMARY**

<The problem, its cost to the next maintainer, and the direction. Fix: <direction>.>

**DETAILED EXPLANATION**

**<Why it is not a blocker.>** <what limits the damage — often the most useful line in the finding>

**<Why it is still worth fixing.>** <the residual risk or cost>

### 🔵 Nits

#### N1 — <short title> · `style` | `performance`

**Where:** `path/to/file.go:9`

**SUMMARY**

<One or two sentences — non-blocking. Perf-when-not-a-priority lives here.>

**DETAILED EXPLANATION**

<Only when there is more to say — e.g. why you are NOT recommending the obvious bigger change. Omit
this heading and its content entirely otherwise.>

## What's good

<Optional. 1–3 bullets on good choices worth keeping — keeps the review balanced and stops it
from sounding all-negative.>

## Open questions

<Anything you need the author to explain before the verdict is final, if any.>
