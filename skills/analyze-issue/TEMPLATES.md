# Report Templates — shared ground

The report is a directory with exactly **four** files. Findings live in doc 3, recommendations in
doc 4, linked by **finding ID** (`F-01`, `F-02`, …) so each finding can be explored later on its own.

Docs **01–02 are shared** (skeleton below). Docs **03–04 differ by kind** — pick the kind in
Step 0 of [SKILL.md](SKILL.md), then follow that kind's file:

- bug / investigation → [BUG_TEMPLATES.md](BUG_TEMPLATES.md)
- feature → [FEATURE_TEMPLATES.md](FEATURE_TEMPLATES.md)

Each kind file also gives the **Findings index columns** and the **Documents block** to drop into
`01-summary.md` for that kind.

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

**Bug kind** — search by **failure class**, then categorize each finding as:
- **Gap** — missing handling, unimplemented requirement, absent validation, untested edge case.
- **Bug** — incorrect logic, broken invariant, race, off-by-one, wrong error handling.
- **Risk** — perf cliff, security hole, data-integrity hazard, hidden coupling, scalability limit.

**Feature kind** — survey by **readiness to build**, then categorize each finding as:
- **Decision** — a design choice with options + a recommendation.
- **Integration point** — a specific place code must change or hook in.
- **Risk / Unknown** — a hazard, dependency, or thing needing a spike.
- **Open question** — a requirement ambiguity to resolve before coding.

## Severity scale (bug / investigation)

- **Critical** — data loss, security breach, or correctness failure on a common path. Fix before shipping.
- **High** — wrong behavior or a serious risk on a real path; ships broken without it.
- **Medium** — edge-case bug, notable risk, or gap that bites under specific conditions.
- **Low** — minor gap, cleanup, or hardening that's worth noting but not blocking.

Order findings by severity; ties broken by category **Bug → Risk → Gap**.

## Reversibility scale (feature)

Feature findings aren't graded by blast radius — they're graded by **cost-to-reverse**, which maps
onto the planning tiers so the report feeds `write-plan` directly:

- **Architecture** — data model, public API, service boundary, dependency lock-in. Hard to undo;
  resolve and grill before any code.
- **Module-shape** — new struct/endpoint/internal helper, folder layout, a private signature. One
  recommendation + a one-line alt is enough.
- **Local** — naming, a single-file edit, an internal detail. Decide in passing.

Order findings by reversibility; ties broken by category **Decision → Integration point →
Risk-Unknown → Open question**.

## Confidence (both kinds)

**Confidence** — High (verified in code) / Medium (likely, some inference) / Low (suspected, needs
checking). For a feature it measures how sure you are of the claim about the *existing* code a
finding rests on.

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
