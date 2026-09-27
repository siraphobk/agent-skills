# write-plan templates

This file defines the plan sections, phase fields, progress markers, and omission
rules. SKILL.md defines the workflow. Use these templates and the worked example
when you draft.

Omit sections that would contain only filler. Implementation plans always need
Acceptance criteria, Phased rollout, and Verification. Omit implementation-only
sections for a pure findings writeup with nothing to execute.

## Required template (single plan, and each sub-plan)

````md
# <Plan Title>

## Goal

One paragraph. State the problem this plan addresses, and what "done" looks
like. Frame it around the change or the outcome, not around a question under
investigation. When the plan comes from an analyze-issue report, name the
finding IDs it addresses (e.g. "fixes F-01, F-03, F-07"). Link the exact
analysis report path as well.

## Non-goals

Three or four bullets. Each one names nearby work this plan deliberately leaves
alone, with a one-line why. This is the cheapest way to stop scope drift. An
executing agent that knows where the edge is does not cross it. Omit the section
only when nothing nearby could plausibly enter the plan.

## Acceptance criteria

Numbered, checkable statements of done. Each one is a fact someone can verify,
not a task. Write "a redelivered event writes no ledger row", not "add dedupe".
Phases cite the IDs they advance. Verification proves every one.

- **AC-1** — <checkable statement>
- **AC-2** — <checkable statement>

The numbers are local to this file. In an epic, the phases of a sub-plan cite
only the ACs of that sub-plan. They never cite the ACs of the epic overview.
Omit the section entirely for a pure findings or analysis writeup with nothing
to execute.

## Approach

Open with one or two short paragraphs. State the overall change and the tradeoffs
that matter. Define the terms, assumptions, and precedence rules needed to execute
the plan. Keep this context in the file, not only in chat. Put rationale here,
not implementation code. Discuss alternatives only when the user asks.

Then write one block per change. Give each block an ID (`C-1`, `C-2`, …). A
phase can then point at that block instead of a repeat of it. Each block pairs
the state of the code now with what changes. The reader then sees the problem and the fix
together, with no jump between sections. Put the file paths in a code block at
the top of the block. Keep the prose plain, with as little inline code as you
can. Take the first content for the **Now** lines from the report's
`## Current state` section, when one exists.

**C-1 — <short label>**

```
path/to/file.go:120-145
```
**Now** — describe in plain English how this code behaves today, and why that
matters for the change.

**Change** — describe in plain English what to do here. Say why you chose this
and not the obvious alternative. Name the symbols you touch (`handleEvent`), not
the area ("the handler").

**C-2 — <short label>**

```
path/to/other.go  (new)
```
**Change** — new code has no "Now". State what the code does. Give the signature
of anything a later phase must call.

A pure findings or analysis writeup may not yet target specific edits. Drop the
per-change blocks there, and keep only the design paragraphs.

## Phased rollout

Use numbered phases. Each phase delivers one coherent behavior with a checkable
stopping point. Make each phase independently revertible where possible. Split
unrelated concerns, not changes that must work together. File count is a review
signal, not a split rule.

Keep reproduction, the regression test, and the fix in one phase for a bug.
Require evidence that the test fails for the reported behavior before the fix
and passes afterward. An expected failure is an intermediate observation, not
the phase gate. The completed phase must pass its gate and required repository
checks.

Keep the heading and `[ ]` marker format shown below. execute-plan changes the
marker to `[x]` after the gate passes. Use these fields in this order:

- **Files:** every path the phase touches, with `(new)` on the files it creates.
  Do not write "and related callers". Find those callers now, and name them.
- **Does:** explicit actions, symbols, and dependencies on earlier phases.
  Reference Approach blocks for rationale, not as a substitute for actions.
  A fresh agent must be able to execute the phase from the complete plan.
  Name existing helpers such as `db/pg.go:IsUniqueViolation` to reuse them.
- **Don't touch:** nearby code that stays as it is, and why. Omit the field when
  nothing is genuinely at risk.
- **Gate:** a copy-pasteable command plus its expected successful result.
  Use `(manual)` only when no command fits, and describe the required observation.

When the plan addresses analyze-issue findings, name the IDs each phase fixes
next to the ACs it advances.

1. **[ ] Phase 1 — <name>** (AC-1, fixes F-01)
   **Files:** `path/a.go:88-140`, `path/a_test.go` (new)
   **Does:** <actions, symbols, and prerequisites>. See C-1 for rationale.
   **Don't touch:** <what stays as-is, and why>
   **Gate:** `<command>` → <expected result>

2. **[ ] Phase 2 — <name>** (AC-2, AC-3)
   ...

## Verification

Run the end-to-end checks after all phases are complete. execute-plan runs this
section verbatim. Write copy-pasteable commands, not instructions such as "run
the test suite". Cover every acceptance criterion and tag each check with its
ACs. Use `(manual)` when no command fits. Omit this section for a pure findings
writeup with nothing to execute.

- `<command>` → <expected result> (AC-1, AC-3)
- (manual) <observation> (AC-2)

## Open questions

Anything still undecided, written as questions. Tag each one `(blocking)` or
`(non-blocking)`. A blocking question must be answered before execution starts.
A non-blocking question can be settled during execution. execute-plan halts only
on the blocking ones.
````

For an epic, each sub-plan opens with a one-line backlink above its title. The
backlink is `> Part of the [<epic title>](00-epic.md) epic.`

## Epic overview template (`00-epic.md`)

````md
# <Epic Title>

## Goal

One paragraph. State the overall outcome this epic delivers. State what "done"
looks like across every sub-plan.

## Non-goals

Work next to the epic that no sub-plan covers, with a one-line why. Omit the
section when no nearby work could enter the epic.

## Acceptance criteria

Epic-level, integration-scale statements of done. They say what must be true
after every sub-plan lands. Global verification proves them. Keep them few.
Detail for one sub-plan belongs in the ACs of that sub-plan, which are numbered
independently.

- **AC-1** — <checkable statement spanning sub-plans>

## Current state

Context that spans the sub-plans. These are the facts, conventions, and
invariants that matter across the whole epic. Detail for one sub-plan belongs in
that sub-plan. Omit the section when nothing is shared.

## Sub-plans

Ordered index. Each entry holds the file, a one-line goal, and a status box. The
status box is the bare marker `[ ]`, and it becomes `[x]` as each sub-plan
completes. Write it exactly as on the phase headings, so the exact-match flip in
execute-plan finds it.

1. `01-<slug>.md` — <one-line goal>  [ ]
2. `02-<slug>.md` — <one-line goal>  [ ]

## Sequencing & dependencies

State which sub-plans block which, and which ones can run in parallel. Write
"all independent" when there are no ordering constraints.

## Global verification

End-to-end, integration-level check after every sub-plan is complete. It is the
proof that the whole epic works. Write copy-pasteable commands. Tag each one
with the epic ACs it proves. A check for one sub-plan stays in that sub-plan.

- `<command>` → <expected result> (AC-1)

## Open questions

Epic-level unknowns, tagged `(blocking)` or `(non-blocking)` as in a plan. A
question local to one sub-plan stays in that sub-plan.
````

## Phase density

Here is the same phase, written twice. Only someone who was in the planning
conversation can execute the first one. A fresh agent can execute the second one
with nothing but the file.

**Too coarse:**

```md
2. **[ ] Phase 2 — dedupe in handler**
   Wrap in tx, swallow the unique violation as a 200 no-op.
   **Gate:** existing tests still green.
```

Nothing says which file, which function, or which error helper. Nothing says
what "still green" means. An agent can declare the gate passed without a command
run.

**Right:**

```md
1. **[ ] Phase 1 — dedupe in handler** (AC-1, AC-2, fixes F-02)
   **Files:** `billing/webhook.go:88-140`, `billing/webhook_test.go` (new)
   **Does:** add `TestWebhookDedupe` to assert one ledger row and two HTTP 200
   responses for repeated delivery. Run `go test ./billing/ -run TestWebhookDedupe`
   before the fix. Confirm failure reports a duplicate row, not a fixture error.
   In `handleEvent`, put the key insert and ledger write in one transaction.
   Insert the key first. When `db/pg.go:IsUniqueViolation` matches that insert,
   roll back the transaction and return 200. See C-1 for rationale.
   **Don't touch:** `billing/charge.go`. The payments path already dedupes.
   **Gate:** `go test ./billing/...` → PASS, including `TestWebhookDedupe`.
```

Length follows the work. The prose sections stay tight. The phase specs carry
the detail. Never pad a phase to look thorough.

## Worked example (single plan)

This example calibrates the level of detail. It shows bounded scope, checkable
ACs, and concrete paths. It also shows phases small enough to revert, and gates
that run.

````md
# Dedupe webhook deliveries by idempotency key

## Goal

Stripe retries webhooks, so a flaky handler can charge a customer's wallet
twice. Done means a redelivered event with the same idempotency key is a no-op.
A regression test proves it. Fixes F-02 from
`.agents/scratch/analysis/2026-06-20-webhook-dupes.md`.

## Non-goals

- This plan does not prune old idempotency keys. That is a separate job, with no
  effect on correctness here.
- The payments path in `billing/charge.go`. It already dedupes.
- Retry and backoff behavior on our side. This plan only handles the replays we
  receive.

## Acceptance criteria

- **AC-1** — a second delivery of an event with a seen idempotency key writes no
  new ledger row.
- **AC-2** — that replay returns HTTP 200, not a 409 and not a 500. Stripe stops
  its retries only on a 2xx.
- **AC-3** — first-delivery behavior is unchanged: one ledger row, 200.

## Approach

Reuse the idempotency-keys table that already exists, instead of a new one. The
payments path already depends on it, so the convention is in place. The tradeoff
is the database unique constraint. It rejects replays, and application code does
not check for them. That keeps the dedupe atomic with the write. The replay then
appears as a database conflict that we must catch.

**C-1 — dedupe the ledger write**

```
billing/webhook.go:88-140
```
**Now** — `handleEvent` writes the ledger row with no dedupe check. So when
Stripe redelivers an event, the handler writes a second row and charges the
wallet twice.

**Change** — put the key insert and the ledger write in one transaction. The
unique constraint on the key rejects the replay. Catch that one conflict, and
return a 200 with no write.

**C-2 — regression test**

```
billing/webhook_test.go  (new)
```
**Change** — `TestWebhookDedupe` sends the same event through `handleEvent`
twice. After each call, it asserts one ledger row and HTTP 200.

## Phased rollout

1. **[ ] Phase 1 — dedupe webhook deliveries** (AC-1, AC-2, AC-3, fixes F-02)
   **Files:** `billing/webhook.go:88-140`, `billing/webhook_test.go` (new)
   **Does:** add `TestWebhookDedupe` with an empty ledger fixture.
   Build the event with `newStripeEvent` and call `handleEvent` twice.
   After each call, assert one ledger row and HTTP 200.
   Run `go test ./billing/ -run TestWebhookDedupe` before the fix.
   Confirm it fails with "want 1 row, got 2", not a compile or fixture error.
   Then put the key insert and ledger write in one transaction in `handleEvent`.
   Insert the key first. When `db/pg.go:IsUniqueViolation` matches that insert,
   roll back the transaction and return 200. See C-1 and C-2 for rationale.
   **Don't touch:** `billing/charge.go`. The payments path already dedupes.
   **Gate:** `go test ./billing/...` → PASS, including `TestWebhookDedupe`.

## Verification

- `go test ./billing/...` → PASS (AC-1, AC-2, AC-3)
- (manual) Use a local server with an isolated test database and an empty ledger.
  POST one event, then POST it again with the same event ID.
  Both responses return 200. After each POST, `select count(*) from ledger`
  returns 1. (AC-1, AC-2, AC-3)
````
