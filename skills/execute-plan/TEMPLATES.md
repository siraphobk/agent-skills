# Deliverable Template

The record [SKILL.md](SKILL.md) writes as each phase lands. Sections that stay empty at the end
get a bare "None.", not deletion — an empty *Deviations* is itself a useful fact.

## Path

- **Single plan:** `<repo-root>/.agents/scratch/deliverables/<plan-file-name>.md`.
- **Epic:** one file for the whole epic — `<repo-root>/.agents/scratch/deliverables/<epic-dir-name>.md`
  — with every sub-plan's entries inside it. Not one file per sub-plan.
- `mkdir -p` the directory on first write.

## Shape

````md
# Delivered — <plan title>

Plan: `.agents/scratch/plans/<file-or-dir>`
Branch: `<current branch>`

## Summary

2–4 bullets, outcome-level — what a reviewer needs to know, not the mechanics.
Written at the end (step 8). Feeds the PR summary.

## Acceptance criteria

One line per AC: met / not met, and the check that proves it.

- AC-1 met — `go test ./billing/...` → PASS
- AC-2 met — (manual) second POST returned 200, ledger stayed at 1 row

## Changes by phase

Appended per phase, at gate-pass (step 6).

### [x] Phase 1 — <name>
Files: `path/a_test.go` (new)
Gate: `<command>` → <what actually happened>

## Deviations from the plan

Where reality differed: a moved file, an extra caller, an approach that didn't work, a
line range that shifted. One line each, appended when it happens. "None." if the run was clean.

## Not done / follow-ups

Non-blocking open questions left open, work punted mid-run, non-goals that came up anyway.

## Verification output

The Verification commands and their real output. Feeds the PR test plan.
````

## Epic layout

Same sections, one file. Prefix per-sub-plan entries with the sub-plan number so
they stay sorted and traceable, and group the acceptance criteria under a sub-plan heading — AC
numbering is local to each plan file, so bare `AC-1` lines from two sub-plans would collide:

```md
## Acceptance criteria
**01-<slug>**
- AC-1 met — <check>

**02-<slug>**
- AC-1 met — <check>

## Changes by phase
### [x] 01 · Phase 1 — <name>
### [x] 02 · Phase 1 — <name>
```

The epic's **Summary** covers the whole epic and is written after the last sub-plan; **Verification
output** holds each sub-plan's own verification plus the epic's Global verification, labeled.
