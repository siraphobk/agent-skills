# Report Template

Default and deep analyses write one file:
`.agents/scratch/analysis/<YYYY-MM-DD-HHMM>-<slug>.md`.

Use the skeleton below for both issue kinds. Keep evidence and the recommendation in the same
finding section. Write no full implementation.

## Finding categories

**Bug / investigation**

- **Gap:** missing handling, an unimplemented requirement, absent validation, or an untested edge.
- **Bug:** incorrect logic, a broken invariant, a race, an off-by-one, or wrong error handling.
- **Risk:** a performance cliff, security hole, data-integrity hazard, hidden coupling, or scale limit.

**Feature**

- **Decision:** a design choice with options and a recommendation.
- **Integration point:** a specific place where code must change or connect.
- **Risk-Unknown:** a hazard, dependency, or subject that needs a spike.
- **Open question:** a requirement ambiguity to resolve before coding.

## Ordering scales

Order bug findings by **Severity**: Critical, High, Medium, then Low. Break ties by category:
Bug, Risk, then Gap.

- **Critical:** data loss, a security breach, or a common-path correctness failure. Fix before release.
- **High:** wrong behavior or a serious risk on a real path. The code ships broken without the fix.
- **Medium:** an edge-case bug, notable risk, or gap that fails under specific conditions.
- **Low:** a minor gap or hardening item that does not block release.

Order feature findings by **Reversibility**: Architecture, Module-shape, then Local. Break ties by
category: Decision, Integration point, Risk-Unknown, then Open question.

- **Architecture:** data model, public API, service boundary, or dependency lock-in. It is hard to undo.
- **Module-shape:** internal type, endpoint, helper, folder layout, or private signature.
- **Local:** naming, a single-file edit, or another internal detail.

**Confidence** has three values for both kinds. High means verified in code. Medium means likely,
with some inference. Low means suspected and needs checking. For a feature, it measures confidence
in the existing-code claim.

## Complete skeleton

```md
# Issue Analysis: <issue title or short ref>

- **Issue:** <#N / URL / "pasted description">
- **Kind:** bug | feature
- **Date:** <YYYY-MM-DD>
- **Scope:** small | large; <N files>, <N modules or areas>
- **Fan-out:** none | <N subagents>

## Issue

<Distilled goal and expected behavior or acceptance criteria.
For a feature, include explicit non-goals when the issue states them.>

## Current state

### Affected surface

| File | Role |
|------|------|
| `path/to/file.go:42` | What it does and why it is relevant |

### How it works today

<For a bug, describe the relevant flow, data model, or control path.
For a feature, describe the connection points, existing patterns, and reuse candidates.>

## Findings

<Use the index for the issue kind. Omit the index and detailed sections when no findings exist.
In that case, write only: No findings were identified.>

<!-- Bug index -->
| ID | Title | Category | Severity | Confidence | Location |
|----|-------|----------|----------|------------|----------|
| F-01 | <short title> | Bug | High | High | `path:line` |

<!-- Feature index. Use — for an open question without a code anchor. -->
| ID | Title | Category | Reversibility | Confidence | Location |
|----|-------|----------|---------------|------------|----------|
| F-01 | <short title> | Decision | Architecture | High | `path:line` |

### F-01: <bug finding title>

- **Category:** Gap | Bug | Risk
- **Severity:** Critical | High | Medium | Low
- **Confidence:** High | Medium | Low
- **Location:** `path/to/file:line` (related: `path:line`, ...)

#### What the code does today

<Observed behavior, with short evidence and a precise reference.>

#### Why it is a problem

<Impact, trigger, and affected users or systems. Tie it to the issue goal when relevant.>

#### Suggested change

<What to change and why. An approach or pseudocode is sufficient.>

#### Effort / notes

<Rough effort, dependencies, alternatives, or open questions.>

### F-01: <feature finding title>

- **Category:** Decision | Integration point | Risk-Unknown | Open question
- **Reversibility:** Architecture | Module-shape | Local | —
- **Confidence:** High | Medium | Low | —
- **Location:** `path/to/file:line` (related: `path:line`, ...) | issue text

#### Context

<The code or requirement that forces this finding. Include short evidence and a precise reference.>

#### Options

<Decision findings only. Omit this heading for other categories.>

- **A: <name>.** <Approach and trade-off.>
- **B: <name>.** <Approach and trade-off.>

#### Recommendation

<The selected option and why, the exact connection point, or the resolution path.>

#### Sequencing / notes

<Dependencies, what this blocks, and what must be resolved before implementation.>
```

Use one detailed section per finding. Use the section variant for the issue kind. Continue IDs as
`F-02`, `F-03`, and so on. A pure requirement or open question can cite the issue text.
