---
name: grill-me
argument-hint: "[plain|docs]"
allowed-tools: Read Write Edit Grep Glob
description: >
  Interview the user relentlessly about a plan or design until you reach shared understanding,
  resolving each branch of the decision tree one dependency at a time. Runs either way: plain is the
  interview alone, and docs adds domain-model work — challenging the plan against the project's
  existing language, sharpening fuzzy terms, and updating CONTEXT.md and ADRs inline as decisions
  crystallise. Asks which one you want when you don't say. Use when the user says "grill me", "grill
  me on this", "stress-test my plan", "challenge my design", "poke holes in this", "interview me
  about this plan", "check this against our domain model", or otherwise wants a plan pressure-tested
  before it gets built. NOT for writing the plan up (use write-plan), NOT for surveying the code
  around an issue (use analyze-issue), and NOT for reviewing code that already exists (use
  github-pr-review or diagnose).
---

# Grill

Pressure-test a plan by interviewing the user, one question at a time, until every branch of the
design tree is resolved. The deliverable is shared understanding — **no code**, and no plan file
(that's `write-plan`'s job).

## Mode

One optional word decides whether the project's docs join the interview:

| Mode | Behavior |
|------|----------|
| `plain` | Interview only. No doc reads, no doc writes. |
| `docs` | Interview **plus** the domain-model work in *Docs mode* below — glossary challenges, and `CONTEXT.md` / ADR updates as decisions land. |
| *(none)* | **Ask, in one line.** Detect first — `CONTEXT.md`, `CONTEXT-MAP.md`, or `docs/adr/` anywhere in the repo means recommend `docs`, otherwise recommend `plain` — then let the user pick before the first question. |

Docs mode writes to the user's repo, so it is not a mode to assume. The detection picks the
likely answer; the user still confirms it:

```
Repo has CONTEXT.md and docs/adr/.
Grill in docs mode (glossary + ADR updates), or plain?
```

One line, one turn, then straight into question 1. Never ask twice, and never ask when the user
already said `plain` or `docs`.

## Workflow

1. **Find the plan.** Take it from chat, a file the user points at, or a `.agents/scratch/plans/`
   file. If there's no plan to grill yet, say so and stop — grilling a blank page invents
   requirements instead of testing them.

2. **Map the decision tree before asking anything.** List the decisions the plan depends on and
   which ones block which. Interview in dependency order — a question whose answer is forced by an
   unasked upstream decision wastes both turns.

3. **Ask one question at a time, and wait.** Never batch. Every question carries **your
   recommended answer** and the one-line reason for it, so the user can accept fast or push back
   with something concrete.

4. **Explore instead of asking, whenever the code can answer.** If a question is settleable by
   reading the repo, read it. Bring the finding back as a statement to confirm, not a question:
   "the handler already retries three times — so the plan's retry layer is redundant, right?"

5. **Run the docs work inline** (docs mode only) — see below. Capture each resolved term the
   moment it resolves; don't batch them for the end.

6. **Close the loop.** When the tree is resolved, restate the settled design in a few lines — the
   decisions, and what changed from the plan you started with. Then recommend `write-plan` to
   persist it, or `execute-plan` if a plan file already exists and only needed sharpening.
   Recommend; don't invoke.

## Docs mode

### File structure

Most repos have a single context:

```
/
├── CONTEXT.md
├── docs/
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

A `CONTEXT-MAP.md` at the root means the repo has multiple contexts. The map points at where each
one lives:

```
/
├── CONTEXT-MAP.md
├── docs/
│   └── adr/                          ← system-wide decisions
├── src/
│   ├── ordering/
│   │   ├── CONTEXT.md
│   │   └── docs/adr/                 ← context-specific decisions
│   └── billing/
│       ├── CONTEXT.md
│       └── docs/adr/
```

Create files lazily — only when there's something to write. No `CONTEXT.md`? Create one when the
first term resolves. No `docs/adr/`? Create it when the first ADR is needed.

### During the session

- **Challenge against the glossary.** When a term conflicts with `CONTEXT.md`, call it out on the
  spot: "your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"
- **Sharpen fuzzy language.** Propose a precise canonical term for vague or overloaded ones:
  "you're saying 'account' — do you mean the Customer or the User? Those are different things."
- **Discuss concrete scenarios.** Stress-test domain relationships with invented edge cases that
  force precision about where one concept ends and the next begins.
- **Cross-reference with code.** When the user states how something works, check the code agrees.
  Surface contradictions: "your code cancels entire Orders, but you just said partial cancellation
  is possible — which is right?"
- **Update `CONTEXT.md` inline** using [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md), as each term
  resolves.

### Offer ADRs sparingly

Only when **all three** hold:

1. **Hard to reverse** — changing your mind later costs something real.
2. **Surprising without context** — a future reader will ask "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and one won for reasons.

Miss any one and skip the ADR. Format: [ADR-FORMAT.md](ADR-FORMAT.md).

## Constraints

- **One question per turn.** Batching questions is the failure mode this skill exists to prevent —
  the user answers the easy ones and the hard one gets lost.
- **Every question ships a recommendation.** A bare question offloads the thinking you were asked
  to do.
- **Read before you ask.** A question the repo already answers costs the user a turn for nothing.
- **`CONTEXT.md` is a glossary and nothing else.** No implementation detail, no spec, no scratch
  pad. Decisions go to an ADR or the plan.
- **Don't write the plan.** This skill resolves decisions; `write-plan` persists them. Ending a
  grilling session by drafting a plan file skips that skill's approval gate.
- **No code.** Not even a small fix noticed along the way — name it and move on.
