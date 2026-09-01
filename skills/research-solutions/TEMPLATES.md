# Output templates

This file holds the four output files, the scales they share, and one worked
example. The example shows the density to aim for. Copy the structure. Omit a
section only when it would be genuinely empty.

## Scales

**Evidence grade.** Every claim in `02` and `03` carries one.

| Grade | Means |
|---|---|
| **A** | Normative. An RFC, a formal spec, or a published standard. |
| **B** | Official. The vendor's own docs, API reference, or changelog. |
| **C** | Practitioner. An engineering blog, a conference talk, or a well-regarded open source implementation. |
| **D** | Community. A forum answer, an unofficial post, or a second-hand summary. |
| **I** | Inference. Your own reasoning. It is not sourced, and never disguised as sourced. |
| **S** | Our system. Read directly from our code, manifests, or live cluster. Must carry a `file:line` or a resource name. |
| **U** | The user said so. An architecture fact, decision, or constraint that is not in the repo. |

**A** to **D** grade claims about the outside world. **S** and **U** grade claims
about our own system. A feasibility claim with no **S** or **U** behind it is an
**I**. Label it that way, however obvious it feels.

Anything the recommendation depends on that is **D** or **I** goes in the
unverified list. That list is the honest part of the report. Do not shrink it.

**Cost-to-reverse.** This is the same scale that `analyze-issue` uses, so the two
reports match.

| Level | Means |
|---|---|
| **Architecture** | To undo it touches contracts, data shape, or other teams. |
| **Module-shape** | Contained to one module's internals, but a real rewrite. |
| **Local** | A few files. Undo it in an afternoon. |

**Effort.** Give it in agent-days, sized at AI pace. See *Character* in the brain index.
**Fit.** Rate it Good, Workable, or Poor against the Tech Profile in your agent's
user-level instructions file. Add one line on what makes it that rating.

---

## `01-summary.md`

```md
# <Problem> — Solution Research

> **SUMMARY**: <one line — the problem, the recommended approach, and why it wins>

## Requirement
<The distilled requirement from Step 1 — this is what was agreed at Gate 1, and
it carries into write-plan later. Keep the five fields even when one is short.>

- **Goal:** <one sentence, in their words>
- **Non-goals:** <what this does not cover, and the nearby things people will
  otherwise assume are included>
- **Constraints:** <what is already fixed — vendor, deadline, system, regulation, budget>
- **Assumptions:** <every place the requirement was silent and you filled the gap;
  each one appears again under Questions for product>
- **Success signal:** <how anyone would know it worked>

## Type
<Primary type from LENSES.md, and why. Secondary type if one applies.>

## Options

| ID | Approach | Fit | Effort | Cost-to-reverse | Verdict |
|---|---|---|---|---|---|
| A-01 | <name> | Good | ~2d | Module-shape | **Recommended** |
| A-02 | <name> | Workable | ~5d | Architecture | Considered |
| A-03 | <name> | Poor | ~1d | Local | Rejected |

## Recommendation
<Which one and why, in 3-5 sentences. Name the thing that decided it. If the
call is close, say it's close and name what would break the tie.>

## Questions for product
<Numbered. Each one a thing the requirement left open that changes the build.
Written so they can be pasted straight into a reply.>

## What I could not confirm
<Pointer to the unverified list, plus the single biggest unknown.>
```

## `02-landscape.md`

```md
# Landscape

## Standards & specs
<What is formally defined here, and what it obliges. [Grade] per claim.>

## What the vendors do
<One short block per player worth reading. What their approach is, and the one
thing they do that we should copy or avoid.>

## Open source & prior art
<Implementations worth reading, and what each one teaches.>

## What our system does today
<The inward recon, once, so approaches don't each repeat it. What exists that an
approach could hang off, what pattern is already established, and what rules
options out. Every line carries a `file:line`, a resource name [S], or "you told
me" [U]. Keep it to recon depth — the full build map is analyze-issue's job.>

## What this means for us
<3-6 bullets. Where the outside world and our system agree, and — more useful —
where they don't. A standard practice our architecture can't support belongs
here, named.>
```

## `03-approaches.md`

Write one section per approach. Put the recommended one first and the rejected
ones last. Every approach gets every field. A blank field is a research gap, not
a shortcut.

```md
## A-01 — <name>   *(recommended)*

**Shape:** <one line — the idea in a sentence>

**How it works**
<Numbered steps, plus an ASCII diagram whenever there is a flow. Each diagram
line reads input → what happened → resulting state.>

**Connection points**

| Our side | Their side | Direction | Triggered by |
|---|---|---|---|
| `<path:line or route>` | `<their endpoint>` | out | <event> |

*Our side* names a real path, route, or resource — one you read. "The webhook
handler" is a guess wearing a table cell.

**Feasibility check**
<What in our system proves this can be built, and what would have to be new.
2-4 lines, each [S] with a reference or [U] from the user. This is the field that
separates an approach from a wish — if you cannot fill it, that is the finding.>

**Failure & recovery**
<One line per failure mode from the type's list in LENSES.md. Mandatory for
integration-shaped work — a missing row is an unanswered question, not a
non-issue.>

**Limits & caveats**
<What this cannot do, and what it costs to live with. [Grade] where sourced.>

**Effort:** ~Nd · **Cost-to-reverse:** <level> · **Fit:** <Good/Workable/Poor> — <why>

**Later, not now**
<The improvements this approach opens up but does not need on day one.>
```

A rejected approach keeps the same header and adds one field. It may leave the
detail fields short.

```md
## A-03 — <name>   *(rejected)*
**Why rejected:** <the specific thing that rules it out — not "worse than A-01">
```

## `04-references.md`

```md
# References

| # | Source | Grade | Backs which claim | Retrieved |
|---|---|---|---|---|
| R-01 | <title> — <url> | B | A-01 webhook retry behavior | <date> |

## Unverified
<Every D- or I-grade claim the recommendation leans on. For each: what is
assumed, why it could not be confirmed, and the cheapest way to settle it —
a doc to find, a support question to ask, or a spike to run.>
```

---

## Worked example: density calibration

This example is illustrative only. The sources are placeholders. Real output
cites real fetched URLs.

> **Too coarse.** This is the failure mode to avoid.
>
> ```md
> ## A-01 — Webhook integration *(recommended)*
> **Shape:** Use their webhooks to keep our data in sync.
> **How it works:** They send us events, we update our records.
> **Feasibility check:** Our system can support this.
> **Failure & recovery:** Retry failed requests.
> **Effort:** ~3d · **Cost-to-reverse:** Module-shape · **Fit:** Good
> ```
>
> Nothing here is wrong. Nothing here is usable either. Every hard question is
> exactly the one it skipped. Two examples: "what happens on a duplicate?" and
> "do we even have a worker?". The line "Our system can support this" carries no
> reference, so it is a guess formatted as a finding.

**Right density.** This is the same approach, actually researched.

````md
## A-01 — Webhook-driven sync with a local event ledger   *(recommended)*

**Shape:** Their webhook is the trigger, but we persist every event before acting
on it, so our processing is decoupled from their delivery.

**How it works**
1. Their system POSTs an event to `POST /webhooks/<vendor>`; we verify the
   signature and write the raw body to an `inbound_event` row. [B]
2. We reply 200 as soon as the row commits — before any business logic runs. The
   vendor treats a slow response as a failure and retries. [B]
3. A worker picks up unprocessed rows and applies them, keyed on the vendor's
   event id so a replay is a no-op. [B]
4. A nightly reconcile job lists their objects changed in the last 48h and
   compares against ours, repairing drift. [I — no vendor guidance on this]

```
their event ──▶ POST /webhooks   (signature ok, row written)      ──▶ 200, event stored
             └▶ POST /webhooks   (same event id, replay)          ──▶ 200, no-op
worker       ──▶ apply event     (order not found, arrived early) ──▶ row parked, retried
nightly      ──▶ list changed    (our copy stale)                 ──▶ repaired, logged
```

**Connection points**

| Our side | Their side | Direction | Triggered by |
|---|---|---|---|
| `api/routes/webhooks.go:41` | their webhook sender | in | any subscribed event |
| `worker/sync.go:88` | `GET /objects/{id}` | out | event references an object we lack |
| `worker/cron.go` (new job) | `GET /objects?updated_since=` | out | nightly schedule |

**Feasibility check**
- The inbound webhook route and signature middleware already exist for another
  vendor — same shape, different secret. `api/routes/webhooks.go:41` [S]
- The worker pool and its retry-with-backoff are in place; this adds a handler,
  not infrastructure. `worker/pool.go:23` [S]
- The ledger table is new. Nothing today stores raw inbound payloads. [S — no
  match under `internal/store/` for an inbound/event table]
- No nightly cron exists in this service; the reconcile job needs a schedule.
  You confirmed the platform team's CronJob pattern is the way to add one. [U]

**Failure & recovery**
- **Duplicate delivery** — vendor event id is the idempotency key; second apply is a no-op. [B]
- **Timeout, unknown outcome** — we never act before the row commits, so a lost
  response only costs a retry. [I]
- **Out-of-order events** — worker parks an event whose parent object is missing
  and retries it; ordering is not guaranteed by the vendor. [B]
- **Reconciliation** — nightly diff on `updated_since`; drift is repaired and logged. [I]
- **Backfill** — one-time paged pull of existing objects before enabling the webhook. [B]
- **Vendor outage** — inbound stops; our data goes stale but stays consistent. No
  degraded write path needed. [I]

**Limits & caveats**
- Their retry schedule gives up after a fixed window — past that, only the nightly
  reconcile recovers the event. [B]
- Signature verification needs the raw body, so the framework's JSON body parser
  has to be bypassed on this route. [C — from their SDK source]

**Effort:** ~3d · **Cost-to-reverse:** Module-shape — the ledger table and worker
are ours; swapping the vendor keeps both · **Fit:** Good — Postgres for the
ledger, the worker pattern already in `worker/pool.go` [S], no new infra beyond
one CronJob.

**Later, not now**
- Expose the ledger as an internal event stream so other services can subscribe.
- Move reconcile from nightly to continuous once volume justifies it.
````

**What makes it the right density:**

| Element | What it shows |
|---|---|
| Failure modes | Every mode from the integration lens has a line. |
| `[I]` tags | Exactly where the vendor is silent and we guess. |
| `[S]` lines | Real files, including the one that says a thing does *not* exist yet, and how that was checked. |
| `[U]` line | What only the user could tell us. |
| Diagram lines | Outcomes, not labels. |
| Cost-to-reverse | *What* survives a vendor swap, not only a level. |
