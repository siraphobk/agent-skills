# Bug / Investigation Report — docs 3–4

Use with the shared skeleton and the severity/confidence scales in [TEMPLATES.md](TEMPLATES.md).
Findings (doc 3) and suggestions (doc 4) are linked by **finding ID** (`F-01`, `F-02`, …).

## 01-summary.md — bug bits

Drop these into the shared `01-summary.md` skeleton.

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

One section per finding, ordered by severity (highest first). No fixes here — only what's wrong.

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

One section per finding ID, matching doc 3. Approach or pseudocode only — **no full implementation**.

```md
# Improvement Suggestions

## F-NN — <title>  (→ 03-gaps-bugs-risks.md)

**Suggested change:** <what to do and why. Approach or pseudocode OK.>

**Effort / notes:** <rough effort, dependencies, alternatives, open questions>

---

## F-NN — <next>
...
```
