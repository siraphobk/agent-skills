# Feature Report — docs 3–4

Use with the shared skeleton and the reversibility/confidence scales in
[TEMPLATES.md](TEMPLATES.md). Findings (doc 3) and recommendations (doc 4) are linked by
**finding ID** (`F-01`, `F-02`, …).

## 01-summary.md — feature bits

Drop these into the shared `01-summary.md` skeleton.

**Findings index** (Reversibility replaces Severity; `—` for an open question with no code anchor):

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

One section per finding, ordered by reversibility (Architecture first). No implementation — only
the design problem and the options. Recommendation lives in doc 4.

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

One section per finding ID, matching doc 3. The recommended option and why — **no full
implementation**. This is the raw material `write-plan` consumes.

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
