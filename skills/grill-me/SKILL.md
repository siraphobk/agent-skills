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

Pressure-test a plan. Interview the user one question at a time. Continue until every branch of
the design tree is resolved. The result is shared understanding, with **no code** and no plan
file. The plan file belongs to `write-plan`.

## Mode

One optional word decides whether the project's docs join the interview:

| Mode | Behavior |
|------|----------|
| `plain` | Interview only. No doc reads, no doc writes. |
| `docs` | Interview **plus** the domain-model work in *Docs mode* below. |
| *(none)* | **Ask the user, in one line.** Use the detection rule below. |

In `docs` mode you also challenge the glossary. You update `CONTEXT.md` and the ADRs as decisions
land.

Detection rule: a `CONTEXT.md`, a `CONTEXT-MAP.md`, or a `docs/adr/` anywhere in the repo means
you recommend `docs`. If the repo has none of them, recommend `plain`. The user picks before the
first question.

Docs mode writes to the user's repo, so it is not a mode to assume. The detection picks the
likely answer. The user still confirms it:

```
Repo has CONTEXT.md and docs/adr/.
Grill in docs mode (glossary + ADR updates), or plain?
```

Use one line and one turn. Then go straight into question 1. Never ask twice. Never ask when the
user already said `plain` or `docs`.

## Workflow

1. **Find the plan.** Take it from chat, from a file the user points at, or from a
   `.agents/scratch/plans/` file. If there is no plan to grill yet, say so and stop. A blank page
   gives you nothing to test, so you invent requirements instead.

2. **Map the decision tree before you ask anything.** List the decisions the plan depends on. List
   which decisions block which. Interview in dependency order. An upstream decision can force the
   answer to a later question. If you ask that later question first, you waste both turns.

3. **Ask one question at a time, and wait.** Never batch questions. Every question carries **your
   recommended answer** and the one-line reason for it. The user can then accept it fast, or
   object with something concrete.

4. **Read the repo instead of a question, whenever the code can answer.** If the repo can settle a
   question, read the repo. Bring the finding back as a statement to confirm, not as a question:
   "the handler already retries three times — so the plan's retry layer is redundant, right?"

5. **Run the docs work inline** (docs mode only). See *Docs mode* below. Capture each resolved
   term the moment it resolves. Do not batch them for the end.

6. **Close the loop.** When the tree is resolved, restate the settled design in a few lines. Give
   the decisions, and what changed from the plan you started with. Then recommend `write-plan` to
   save it. Recommend `execute-plan` instead when a plan file already exists and only needed a
   sharper form. Recommend only. Do not invoke.

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

A `CONTEXT-MAP.md` at the root means the repo has multiple contexts. The map shows where each one
lives:

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

Create files lazily. Create a file only when you have something to write. If the repo has no
`CONTEXT.md`, create one when the first term resolves. If the repo has no `docs/adr/`, create it
when you need the first ADR.

### During the session

- **Challenge against the glossary.** When a term conflicts with `CONTEXT.md`, say so at once:
  "your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"
- **Sharpen fuzzy language.** Propose a precise canonical term for a vague or overloaded one:
  "you're saying 'account' — do you mean the Customer or the User? Those are different things."
- **Discuss concrete scenarios.** Stress-test the domain relationships with invented edge cases.
  The edge cases force precision about where one concept ends and the next begins.
- **Cross-reference with code.** When the user states how something works, check that the code
  agrees. Report each contradiction: "your code cancels entire Orders, but you just said partial
  cancellation is possible — which is right?"
- **Update `CONTEXT.md` inline** as each term resolves. Follow
  [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md).

### Offer ADRs sparingly

Offer an ADR only when **all three** of these hold:

1. **Hard to reverse.** A later change of mind costs something real.
2. **Surprising without context.** A future reader will ask "why did they do it this way?"
3. **The result of a real trade-off.** There were genuine alternatives, and one won for reasons.

If any one of the three fails, skip the ADR. Format: [ADR-FORMAT.md](ADR-FORMAT.md).

## Constraints

| Constraint | Why |
|---|---|
| **One question per turn.** | Batched questions are the failure this skill exists to prevent. |
| **Every question ships a recommendation.** | A bare question returns the thinking you were asked to do. |
| **Read before you ask.** | A question the repo already answers costs the user a turn for nothing. |
| **`CONTEXT.md` is a glossary and nothing else.** | Decisions go to an ADR or to the plan. |
| **Do not write the plan.** | This skill resolves decisions. `write-plan` saves them. |
| **No code.** | Not even a small fix you notice on the way. |

Notes on the table above:

- When you batch questions, the user answers the easy ones. The hard one gets lost.
- `CONTEXT.md` holds no implementation detail, no spec, and no scratch pad.
- A plan file drafted at the end of a grill skips the approval gate of `write-plan`.
- Name a small fix and continue. Do not apply it.
