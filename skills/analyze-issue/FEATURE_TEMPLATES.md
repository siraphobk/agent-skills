# Feature Report: docs 3–4

Use this file with the shared skeleton and the reversibility and confidence scales in
[TEMPLATES.md](TEMPLATES.md). A **finding ID** (`F-01`, `F-02`, …) links the findings (doc 3) to
the recommendations (doc 4).

## 01-summary.md: the feature parts

Put these into the shared `01-summary.md` skeleton.

**Findings index.** Reversibility replaces Severity. Use `—` for an open question with no code
anchor.

```md
| ID | Title | Category | Reversibility | Confidence | Location |
|----|-------|----------|---------------|------------|----------|
| F-01 | <short title> | Decision | Architecture | High | `path:line` |
| F-02 | <short title> | Integration point | Module-shape | High | `path:line` |
| F-03 | <short title> | Open question | — | — | (issue text) |
```

**Documents block:**

```md
- `02-current-state.md` — the seams the feature plugs into and patterns to follow
- `03-design-and-decisions.md` — the findings: options, integration points, data/API changes
- `04-recommended-approach.md` — the recommended option per finding ID, with rough sequencing
```

## 03-design-and-decisions.md

Write one section per finding. Order the sections by reversibility, Architecture first. Give no
implementation. Give only the design problem and the options. The recommendation lives in doc 4.

```md
# Design & Decisions

## F-NN — <title>

- **Category:** Decision | Integration point | Risk-Unknown | Open question
- **Reversibility:** Architecture | Module-shape | Local  (— for open questions)
- **Confidence:** High | Medium | Low
- **Location:** `path/to/file:line`  (related: `path:line`, ...)  (or "issue text" for a pure requirement)

### Context

<what in the existing code or the issue forces this finding — the seam, the constraint, the
ambiguity. Ground it in `file:line` where there is one.>

### Options  (Decision findings only)

- **A — <name>:** <approach>. Trade-off: <cost/benefit>.
- **B — <name>:** <approach>. Trade-off: <cost/benefit>.

<For Integration point: the exact place + what must change there.
 For Risk-Unknown: the hazard/dependency and what would de-risk it (often a spike).
 For Open question: what's ambiguous and who/what can answer it.>

---

## F-NN — <next finding>
...
```

## 04-recommended-approach.md

Write one section per finding ID. The sections match doc 3. Give the recommended option and why.
**Write no full implementation.** `write-plan` consumes this file as raw material.

```md
# Recommended Approach

## F-NN — <title>  (→ 03-design-and-decisions.md)

**Recommendation:** <which option to take and why, or the concrete hook-in for an integration
point, or the resolution path for a risk/open question. Approach or pseudocode OK.>

**Sequencing / notes:** <rough effort, what it depends on or blocks, what must be resolved before
coding starts>

---

## F-NN — <next>
...
```
