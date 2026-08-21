# write-plan templates

The full templates the skill drafts from, plus a worked example for calibration.
SKILL.md keeps only the section skeletons inline; copy the complete structure
from here.

## Required template (single plan, and each sub-plan)

````md
# <Plan Title>

## Goal

One paragraph: the problem this plan addresses and what "done" looks like.
Frame it around the change or outcome, not a question being investigated.
When the plan comes from an analyze-issue report, name the finding IDs it
addresses (e.g. "fixes F-01, F-03, F-07") and link the report directory.

## Non-goals

Three or four bullets: nearby work this plan deliberately leaves alone, each
with a one-line why. This is the cheapest guard against scope drift — an
executing agent that knows where the edge is won't wander past it. Omit only
when nothing nearby could plausibly get pulled in.

## Acceptance criteria

Numbered, checkable statements of done. Each is a fact someone can verify, not
a task — "a redelivered event writes no ledger row", not "add dedupe". Phases
cite the IDs they advance; Verification proves every one.

- **AC-1** — <checkable statement>
- **AC-2** — <checkable statement>

Numbering is local to this file. In an epic, a sub-plan's phases cite only that
sub-plan's ACs, never the epic overview's. Omit the section entirely for a pure
findings/analysis writeup with nothing to execute.

## Approach

Open with one or two short paragraphs in plain English: the overall shape of
the change and the one or two tradeoffs that matter. No code here — just the
reasoning. No alternatives unless the user asked.

Then one block per change, each with an ID (`C-1`, `C-2`, …) so phases can point
at it instead of repeating it. Each block pairs where the code stands now with
what changes, so a reader sees the problem and the fix together without flipping
between sections. Put the file path(s) in a code block at the top of the block;
keep the prose plain, with as little inline code as you can. Seed the **Now**
lines from the report's `02-current-state.md` when one exists.

**C-1 — <short label>**

```
path/to/file.go:120-145
```
**Now** — plain-English description of how this code behaves today and why it
matters for the change.

**Change** — plain-English description of what to do here and why this and not
the obvious alternative. Name the symbols you touch (`handleEvent`), not the
area ("the handler").

**C-2 — <short label>**

```
path/to/other.go  (new)
```
**Change** — brand-new code has no "Now". State what it does and give the
signature of anything a later phase has to call.

For a pure findings/analysis writeup that doesn't yet target specific edits,
drop the per-change blocks and keep only the design paragraphs.

## Phased rollout

Numbered phases, each independently revertible where possible — one phase is
one commit-sized change. Phase headings start with a `[ ]` marker — execute-plan
flips it to `[x]` as each gate passes. The heading line's format is parsed, so
keep it exact; the fields below it are what the executing agent works from.

Every phase carries these four fields, in this order:

- **Files:** every path the phase touches, with `(new)` on files it creates.
  No "and related callers" — find them now and name them.
- **Does:** the work, at symbol level. Point at the Approach block (`apply C-2`)
  rather than restating it. A phase a fresh agent can't execute without
  re-reading Approach is under-specified. Name the existing helper to call
  (`db/pg.go:IsUniqueViolation`) rather than leaving the agent to reinvent it.
- **Don't touch:** nearby code that stays as-is, and why. Omit the field when
  nothing is genuinely at risk.
- **Gate:** a copy-pasteable command plus its expected result. Prose-only gates
  let an agent declare a pass without running anything. When no command fits,
  mark it `(manual)` and describe the observation.

When the plan addresses analyze-issue findings, name the IDs each phase fixes
alongside the ACs it advances.

1. **[ ] Phase 1 — <name>** (AC-1, fixes F-01)
   **Files:** `path/a.go:88-140`, `path/a_test.go` (new)
   **Does:** apply C-1 — <what to do, naming the symbols>.
   **Don't touch:** <what stays as-is, and why>
   **Gate:** `<command>` → <expected result>

2. **[ ] Phase 2 — <name>** (AC-2, AC-3)
   ...

## Verification

End-to-end check after all phases complete. execute-plan runs this section
**verbatim**, so write copy-pasteable commands (`go test ./pricing/...`), not
prose ("run the test suite"). Every acceptance criterion must be proved by a
line here — tag each line with the ACs it covers. Manual checks are fine when
no command fits; mark them `(manual)`. Omit if the plan is purely analytical.

- `<command>` → <expected result> (AC-1, AC-3)
- (manual) <observation> (AC-2)

## Open questions

Anything still undecided, phrased as questions. Tag each one `(blocking)` —
must be answered before execution starts — or `(non-blocking)` — can be
settled mid-flight. execute-plan halts only on blocking ones.
````

For an epic, each sub-plan opens with a one-line backlink above its title:
`> Part of the [<epic title>](00-epic.md) epic.`

## Epic overview template (`00-epic.md`)

````md
# <Epic Title>

## Goal

One paragraph: the overall outcome this epic delivers and what "done" looks
like across every sub-plan.

## Non-goals

Work adjacent to the epic that no sub-plan covers, with a one-line why. Omit if
nothing nearby is at risk of creeping in.

## Acceptance criteria

Epic-level, integration-scale statements of done — what must be true once every
sub-plan lands. Global verification proves these. Keep them few; per-sub-plan
detail belongs in that sub-plan's own (independently numbered) ACs.

- **AC-1** — <checkable statement spanning sub-plans>

## Current state

Context that spans the sub-plans — facts, conventions, invariants that matter
epic-wide. Per-sub-plan detail belongs in that sub-plan. Omit if nothing is shared.

## Sub-plans

Ordered index. One entry per sub-plan: file, one-line goal, and a status box —
the bare marker `[ ]` (flipped to `[x]` as each completes), written exactly as
on phase headings so execute-plan's exact-match flip finds it.

1. `01-<slug>.md` — <one-line goal>  [ ]
2. `02-<slug>.md` — <one-line goal>  [ ]

## Sequencing & dependencies

Which sub-plans block which, and which can run in parallel. State "all
independent" if there are no ordering constraints.

## Global verification

End-to-end, integration-level check after every sub-plan is complete — the
proof the epic as a whole works. Copy-pasteable commands, each tagged with the
epic ACs it proves. Per-sub-plan checks stay in their sub-plans.

- `<command>` → <expected result> (AC-1)

## Open questions

Epic-level unknowns, tagged `(blocking)` / `(non-blocking)` like a plan's.
Sub-plan-local questions stay in their sub-plan.
````

## Phase density — too coarse vs. right

The same phase, written twice. The first is executable only by someone who was
in the planning conversation; the second is executable by a fresh agent with
nothing but the file.

**Too coarse:**

```md
2. **[ ] Phase 2 — dedupe in handler**
   Wrap in tx, swallow the unique violation as a 200 no-op.
   **Gate:** existing tests still green.
```

Nothing says which file, which function, which error helper, or what "still
green" means. The gate can be declared passed without running a command.

**Right:**

```md
2. **[ ] Phase 2 — dedupe in handler** (AC-1, AC-2, fixes F-02)
   **Files:** `billing/webhook.go:88-140`
   **Does:** apply C-1 — in `handleEvent`, open a tx before the ledger write and
   insert the idempotency key first. When `db/pg.go:IsUniqueViolation` matches
   the insert error, roll the tx back and return 200 with no ledger row.
   **Don't touch:** `billing/charge.go` — the payments path already dedupes.
   **Gate:** `go test ./billing/...` → PASS, including `TestWebhookDedupe`.
```

Length follows the work: the prose sections stay tight, the phase specs carry
the detail. Never pad a phase to look thorough.

## Worked example (single plan)

Calibration for the level of detail — bounded scope, checkable ACs, concrete
paths, phases small enough to revert, gates that run.

````md
# Dedupe webhook deliveries by idempotency key

## Goal

Stripe retries webhooks, so a flaky handler can charge a customer's wallet
twice. Done = a redelivered event with the same idempotency key is a no-op,
proven by a regression test. Fixes F-02 from
`.agents/scratch/issue-analysis/2026-06-20-webhook-dupes/`.

## Non-goals

- Pruning old idempotency keys — separate job, no bearing on correctness here.
- The payments path in `billing/charge.go` — it already dedupes.
- Retry/backoff behavior on our side; this plan only handles replays we receive.

## Acceptance criteria

- **AC-1** — a second delivery of an event with a seen idempotency key writes no
  new ledger row.
- **AC-2** — that replay returns HTTP 200, not a 409 or a 500 — Stripe stops
  retrying only on a 2xx.
- **AC-3** — first-delivery behavior is unchanged: one ledger row, 200.

## Approach

Reuse the idempotency-keys table that already exists rather than adding a new
one — the payments path already relies on it, so the convention is in place.
The tradeoff: we lean on the database unique constraint to reject replays
instead of checking in application code. That keeps the dedupe atomic with the
write, but the replay surfaces as a database conflict we have to catch.

**C-1 — dedupe the ledger write**

```
billing/webhook.go:88-140
```
**Now** — `handleEvent` writes the ledger row with no dedupe check, so when
Stripe redelivers an event the handler writes a second row and double-charges
the wallet.

**Change** — wrap the key insert and the ledger write in one transaction. The
unique constraint on the key rejects the replay; catch that one conflict and
return a 200 with no write.

**C-2 — regression test**

```
billing/webhook_test.go  (new)
```
**Change** — `TestWebhookDedupe` fires the same event through `handleEvent`
twice and asserts a single ledger row and a 200 on both calls.

## Phased rollout

1. **[ ] Phase 1 — failing regression test** (AC-1, fixes F-02)
   **Files:** `billing/webhook_test.go` (new)
   **Does:** apply C-2 — build the event with `newStripeEvent`, call
   `handleEvent` twice, assert `SELECT count(*) FROM ledger` returns 1.
   **Don't touch:** `billing/webhook.go` — the fix lands in Phase 2.
   **Gate:** `go test ./billing/ -run TestWebhookDedupe` → FAILS with
   "want 1 row, got 2" (the real bug, not a compile or fixture error).

2. **[ ] Phase 2 — dedupe in handler** (AC-1, AC-2, AC-3)
   **Files:** `billing/webhook.go:88-140`
   **Does:** apply C-1 — in `handleEvent`, open a tx before the ledger write and
   insert the idempotency key first. When `IsUniqueViolation` matches the insert
   error, roll the tx back and return 200 with no ledger row.
   **Don't touch:** `billing/charge.go` — the payments path already dedupes.
   **Gate:** `go test ./billing/...` → PASS, `TestWebhookDedupe` included.

## Verification

- `go test ./billing/...` → PASS (AC-1, AC-3)
- (manual) POST the same event id twice against a local server; both return 200
  and `select count(*) from ledger` stays at 1 (AC-2)

## Open questions

- Retain idempotency keys forever, or prune after 30 days? (non-blocking)
````
