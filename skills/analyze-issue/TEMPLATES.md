# Report Templates: shared ground

The report is a directory with exactly **four** files. Findings live in doc 3. Recommendations live
in doc 4. A **finding ID** (`F-01`, `F-02`, …) links the two, so each finding can be explored later
on its own.

Docs **01–02 are shared**, and the skeleton is below. Docs **03–04 differ by kind**. Pick the kind
in Step 0 of [SKILL.md](SKILL.md), then follow that kind's file:

- bug / investigation → [BUG_TEMPLATES.md](BUG_TEMPLATES.md)
- feature → [FEATURE_TEMPLATES.md](FEATURE_TEMPLATES.md)

Each kind file also gives two things for that kind: the **Findings index columns** and the
**Documents block** to put into `01-summary.md`.

**Bug / investigation report:**

```
.agents/scratch/issue-analysis/<YYYY-MM-DD-HHMM>-<slug>/
├── 01-summary.md
├── 02-current-state.md
├── 03-gaps-bugs-risks.md
└── 04-improvement-suggestions.md
```

**Feature report:**

```
.agents/scratch/issue-analysis/<YYYY-MM-DD-HHMM>-<slug>/
├── 01-summary.md
├── 02-current-state.md
├── 03-design-and-decisions.md
└── 04-recommended-approach.md
```

## Finding categories

**Bug kind.** Search by **failure class**, then categorize each finding:

- **Gap:** missing handling, an unimplemented requirement, absent validation, an untested edge case.
- **Bug:** incorrect logic, a broken invariant, a race, an off-by-one, wrong error handling.
- **Risk:** a perf cliff, a security hole, a data-integrity hazard, hidden coupling, a scalability
  limit.

**Feature kind.** Survey by **readiness to build**, then categorize each finding:

- **Decision:** a design choice with options and a recommendation.
- **Integration point:** a specific place where code must change or hook in.
- **Risk / Unknown:** a hazard, a dependency, or something that needs a spike.
- **Open question:** a requirement ambiguity to resolve before coding.

## Severity scale (bug / investigation)

- **Critical:** data loss, a security breach, or a correctness failure on a common path. Fix it
  before you ship.
- **High:** wrong behavior or a serious risk on a real path. The code ships broken without the fix.
- **Medium:** an edge-case bug, a notable risk, or a gap that bites under specific conditions.
- **Low:** a minor gap, cleanup, or hardening. It is worth a note, but it does not block.

Order the findings by severity. Break a tie by category, in the order **Bug → Risk → Gap**.

## Reversibility scale (feature)

Feature findings are not graded by how much code they touch. They are graded by
**cost-to-reverse**. That scale maps onto the planning tiers, so the report feeds `write-plan`
directly.

- **Architecture:** the data model, a public API, a service boundary, dependency lock-in. It is hard
  to undo. Resolve it and grill it before any code.
- **Module-shape:** a new struct, endpoint, or internal helper, the folder layout, a private
  signature. One recommendation plus a one-line alternative is enough.
- **Local:** naming, a single-file edit, an internal detail. Decide it in passing.

Order the findings by reversibility. Break a tie by category, in the order **Decision → Integration
point → Risk-Unknown → Open question**.

## Confidence (both kinds)

**Confidence** has three values. High means verified in code. Medium means likely, with some
inference. Low means suspected, and it needs checking. For a feature, confidence measures how sure
you are of the claim about the *existing* code the finding rests on.

## 01-summary.md  (shared skeleton)

The fields and `Issue in one paragraph` are shared. The **Findings index** columns and the
**Documents** block come from the kind's template file.

```md
# Issue Analysis — <issue title or short ref>

- **Issue:** <#N / URL / "pasted description">
- **Kind:** bug | feature
- **Date:** <YYYY-MM-DD>
- **Scope:** small | large  (fan-out: none | N subagents)

## Issue in one paragraph

<bug: goal + expected behavior / acceptance criteria, distilled.
 feature: what the feature must do + acceptance criteria + explicit non-goals.>

## Findings index

<the kind's index table — see BUG_TEMPLATES.md or FEATURE_TEMPLATES.md>

## Documents

<the kind's Documents block — see BUG_TEMPLATES.md or FEATURE_TEMPLATES.md>

This report stops at analysis — nothing here has been implemented.
```

## 02-current-state.md  (shared)

```md
# Current State

## Affected surface

| File | Role |
|------|------|
| `path/to/file.go:42` | what it does / why it's relevant |

## How it works today

<bug: the relevant flow / data model / control path, narrated against the issue's goal.
 feature: the seams the feature plugs into, the patterns similar features already follow here,
 and the reuse candidates (existing helpers/abstractions to lean on).
Enough context that doc 3's findings stand on their own.>
```
