# Smell Report: <target>

> Show this in chat first. Save it only when the user asks, to
> `.agents/scratch/reviews/YYYY-MM-DD-smells-<slug>.md`. Drop a section that
> is empty. Do not fill it with padding.

## Context

- **Target:** `<path>`, or `diff`, or `branch <name>` against `<base>`
- **Files read:** <n> in full. Skipped as generated: <list, or "none">
- **Language notes applied:** <Go, Rust, …>
- **Change in progress, if any:** <the change the user named. This sets 🔴>

## Summary

| Group | Findings | Ignored |
|---|---|---|
| Bloaters | <n> | <n> |
| Object-Orientation Abusers | <n> | <n> |
| Change Preventers | <n> | <n> |
| Dispensables | <n> | <n> |
| Couplers | <n> | <n> |

| Severity | Count |
|---|---|
| 🔴 Fix now | <n> |
| 🟡 Fix soon | <n> |
| 🔵 Nit | <n> |

## Findings

Order the findings by severity, then by group. Give each finding an ID from
its group letter and a number: `B` bloater, `O` object-orientation abuser,
`C` change preventer, `D` dispensable, `K` coupler. Every finding has the
five parts below, in this order. No part is optional except the alternative.

#### B1 — <Smell name> in `<function or type>` · 🟡

**Where:** `path/to/file.go:12-58`, `path/to/other.go:9`

**Smell.** <One or two sentences. Which sign from the catalog the code
matches, and the evidence. Give the number: lines, parameters, files.>

**Technique.** <Name> (`https://refactoring.guru/<slug>`). <One sentence on
why this technique and not another one the catalog lists. Name one
alternative at most.>

**Why it matters here.** <One or two sentences. What the next change costs
with the smell in place. Say why it is not a higher severity when that is not
obvious.>

**Sketch.** Use the language of the target. For a document, use a text
outline of the files and sections.

```go
// before
<about ten lines>
```

```go
// after
<about ten lines>
```

## Seen and ignored

A smell that matched a sign but also matched an ignore line. The reader then
does not find it again as new.

| Where | Smell | Ignore reason |
|---|---|---|
| `path:line` | Switch Statements | Inside a factory function |

## What is good

<Optional. One to three bullets on shapes worth keeping. Skip it when there
is nothing to say.>

## Applied

> `apply` mode only. Add one row as each finding lands.

| ID | Steps done | Tests | Files changed |
|---|---|---|---|
| B1 | Extract Method x3 | pass | `path/to/file.go` |
