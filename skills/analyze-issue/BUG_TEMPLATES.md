# Bug / Investigation Report: docs 3–4

Use this file with the shared skeleton and the severity and confidence scales in
[TEMPLATES.md](TEMPLATES.md). A **finding ID** (`F-01`, `F-02`, …) links the findings (doc 3) to
the suggestions (doc 4).

## 01-summary.md: the bug parts

Put these into the shared `01-summary.md` skeleton.

**Findings index:**

```md
| ID | Title | Category | Severity | Confidence | Location |
|----|-------|----------|----------|------------|----------|
| F-01 | <short title> | Bug | High | High | `path:line` |
| F-02 | <short title> | Risk | Medium | Medium | `path:line` |
```

**Documents block:**

```md
- `02-current-state.md` — how the relevant code works today
- `03-gaps-bugs-risks.md` — the findings, with evidence
- `04-improvement-suggestions.md` — suggested change per finding ID
```

## 03-gaps-bugs-risks.md

Write one section per finding. Order the sections by severity, highest first. Put no fixes here.
State only what is wrong.

```md
# Gaps, Bugs & Risks

## F-NN — <title>

- **Category:** Gap | Bug | Risk
- **Severity:** Critical | High | Medium | Low
- **Confidence:** High | Medium | Low
- **Location:** `path/to/file:line`  (related: `path:line`, ...)

### What the code does today

<observed behavior, with the relevant snippet or precise reference>

### Why it's a problem

<impact: what breaks, when, who's affected; tie back to the issue's goal if relevant>

---

## F-NN — <next finding>
...
```

## 04-improvement-suggestions.md

Write one section per finding ID. The sections match doc 3. Give an approach or pseudocode only.
**Write no full implementation.**

```md
# Improvement Suggestions

## F-NN — <title>  (→ 03-gaps-bugs-risks.md)

**Suggested change:** <what to do and why. Approach or pseudocode OK.>

**Effort / notes:** <rough effort, dependencies, alternatives, open questions>

---

## F-NN — <next>
...
```
