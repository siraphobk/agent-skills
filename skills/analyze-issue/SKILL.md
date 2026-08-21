---
name: analyze-issue
allowed-tools: Read Grep Glob Write Task Bash(gh *) Bash(git *) Bash(mkdir *)
description: >
  Pre-implementation analysis of the code tied to an issue, for two kinds. Bug/investigation:
  explore the current state, find gaps, bugs, and risks, and suggest a fix approach for each.
  Feature: survey where the feature plugs in, the patterns to follow, the design decisions,
  integration points, and risks. It writes no code. In default/deep modes it writes a 4-file report
  under .agents/scratch/issue-analysis/ and fans out lens-based subagents on a large surface; quick
  mode answers in chat only. Use before starting work on an issue — when the user says "analyze this
  issue", "explore the codebase for this issue", "assess the current state of <X>", "what gaps/risks
  exist for issue <N>", "how should I build this feature", or wants a pre-change survey. NOT for
  diagnosing a single reproducible bug (use diagnose) or reviewing a diff / branch / PR (use
  code-review or github-pr-review). Optional args: mode "quick"|"default"|"deep" and kind
  "bug"|"feature", order-independent.
argument-hint: "[quick|default|deep] [bug|feature]"
---

# Analyze Issue

Explore → find what matters → recommend an approach. The deliverable is a report (or a chat answer
in `quick` mode), **not** code changes. **Do not implement anything** — this skill stops at
analysis.

The skill handles **two issue kinds**, set in Step 0. The orchestration is identical for both —
only the lens set, the finding categories, and the report's docs 3–4 change:

- **bug / investigation** — find gaps/bugs/risks in existing code, suggest a fix approach.
- **feature** — survey where a new feature plugs in: decisions, integration points, unknowns.

## When to use / not use

- **Use this** for a pre-change survey of the existing code tied to an issue (either kind).
- **Use `diagnose`** for one known, reproducible bug or perf regression — it reproduces and fixes.
- **Use `code-review` / `github-pr-review`** to review a diff, branch, or PR — changed code, not
  the existing surface an issue points at.

## Mode & kind (arguments)

The invocation may carry up to two words, order-independent: a **mode** (`quick` | `default` |
`deep`) setting investigation depth, and a **kind** (`bug` | `feature`) selecting the lens set and
report variant. No mode word → `default`. No kind word → detect it in Step 0. An unrecognized
word → ask, don't guess.

**[GATES.md](GATES.md) is the single source** for what each mode does, what each gate presents,
and who can change what. Read it before Step 0 — the steps below only mark *where* a gate fires.

## Step 0 — Get the issue

Accept any source:
- **GitHub issue** (`#N` or a URL): if the user also wants to claim/start the issue (assign,
  branch, comment), defer to the `/github-issue-pickup` skill and reuse the issue it surfaces.
  Otherwise just read it: resolve `owner`/`repo` from `git remote get-url origin`, then
  `gh issue view <N> --json number,title,body,labels,comments`.
- **Pasted text** or a **local file path**: use it as-is.

Distill the issue into: the **goal**, the **expected behavior / acceptance criteria**, and the
**keywords / area names** you'll search by. If the issue is too vague to know *where* to search,
ask one clarifying question **before mapping**, then proceed.

**Determine the kind** (unless given as an arg) from labels, issue template, or verbs — the
signal table is in [GATES.md](GATES.md). If the signals conflict or are absent, state your best
guess and let the user confirm or flip it **at Gate 1** (you're stopping there anyway).

## Step 1 — Map the affected surface

Use Glob / Grep / Read to locate the code tied to the issue: entrypoints, modules, data models,
callers, tests. Produce a short **surface map** — key files and what each does / why it's relevant.

**Gate 1 fires here** — see [GATES.md](GATES.md).

## Step 2 — Size the scope, decide fan-out

- **Small** (~5 files or fewer, a single module): analyze it yourself in one pass. No subagents.
- **Large** (many files, multiple modules, or a cross-cutting concern): **fan out by lens** —
  one `general-purpose` subagent per lens from the kind's lens set in [CHECKLIST.md](CHECKLIST.md)
  (applicable lenses in `default`, every lens in `deep`), each scanning the **whole** surface
  through that single lens. This finds more than splitting by module.
- **Matrix** (`deep` with more than one distinct area): subagents per (area × lens). `deep` floors
  at full lens fan-out and only escalates to matrix when multiple areas justify it — never matrix on
  a single-area surface.

Follow the **subagent contract and per-lens model guidance in [CHECKLIST.md](CHECKLIST.md)**: pass
each agent the issue context, the surface map, and its lens (and area); findings come back concise
in the [TEMPLATES.md](TEMPLATES.md) format. Launch independent subagents in the same batch. **You**
then dedupe, **normalize severity (bug) or reversibility (feature) across agents**, and assemble —
see Steps 4–5.

**Gate 2 fires here** (large scope, and always `deep`) — present the fan-out plan in the format
[GATES.md](GATES.md) shows and wait for go before spawning anything.

## Step 3 — Hunt findings

Run the lenses for the issue's kind from [CHECKLIST.md](CHECKLIST.md) over the surface, at the
breadth your mode dictates. The lens is how you *find* a finding; you then *categorize* it.

Categorize each finding once you find it — **bug** into Gap / Bug / Risk, **feature** into
Decision / Integration point / Risk-Unknown / Open question. Definitions are in
[TEMPLATES.md](TEMPLATES.md) alongside the ordering scales.

Ground every finding in a `file:line` and what the code actually does (a pure requirement / open
question may cite the issue text instead). No claim without a reference. Tie findings back to the
issue's goal where relevant.

## Step 4 — Recommend an approach

For each finding, give a concrete, actionable recommendation: for a bug, what to change and why;
for a feature, which option to take (or the hook-in / resolution path) and why. Approach or
pseudocode is fine; **do not write the full implementation**. When fanning out, subagents propose
the recommendation for their own findings; you reconcile duplicates and conflicts.

## Step 5 — Deliver

**`quick` mode:** answer in chat — the relevant lenses you ran, a findings table, and the
recommendation per finding inline. Write no files. Offer to hand off to `write-plan` if the user
wants it saved.

**`default` / `deep` modes:** write the report. Assemble the 4 files by **editing the returned
findings** — do not re-read the code you already fanned out over.

**Gate 3 fires here** (large scope, and always `deep`) — see [GATES.md](GATES.md). Small scope skips
straight to writing.

Create `.agents/scratch/issue-analysis/<YYYY-MM-DD-HHMM>-<slug>/` with exactly **four** files.
Docs 1–2 are shared; docs 3–4 use the variant for the issue's kind. The shared skeleton and the
ordering scales are in [TEMPLATES.md](TEMPLATES.md); docs 3–4 come from the kind's file —
[BUG_TEMPLATES.md](BUG_TEMPLATES.md) or [FEATURE_TEMPLATES.md](FEATURE_TEMPLATES.md).

Findings (doc 3) and recommendations (doc 4) stay apart, linked by **finding ID** (`F-01`,
`F-02`, …) so each can be explored later on its own. Then show the findings table and the report
path in chat.

## Notes

- **Ordering scale and field definitions** live in [TEMPLATES.md](TEMPLATES.md) — bug findings
  order by severity, feature findings by reversibility. The orchestrator owns the final scale:
  normalize the provisional values subagents return so it means the same thing report-wide.
- **No findings** is a valid result — say so plainly rather than inventing low-value ones.
- When fanning out, **you** own the final dedupe/merge; subagents detect and report, you reconcile
  and write.
- **Handoff:** if a finding is a reproducible bug the user wants fixed *now*, hand off to the
  `diagnose` skill (it builds a repro loop and fixes one bug). This skill stays at analysis.
- **Next step:** after delivering the report (or quick-mode answer), recommend the `write-plan`
  skill — **point it at the report directory and name which findings (`F-NN`) the plan should
  address**. It reads doc 4 (`04-improvement-suggestions.md` for a bug, `04-recommended-approach.md`
  for a feature) as the plan's raw material, seeds the Approach section's **Now** lines from `02-current-state.md`, and
  reuses the scope estimate in `01-summary.md` for its single-plan-vs-epic call. From there
  `execute-plan` carries the plan out gate by gate. The full chain is **analyze-issue →
  write-plan → execute-plan**. Recommend it; don't invoke it automatically.
