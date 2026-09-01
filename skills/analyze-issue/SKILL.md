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

Explore the code, find what matters, then recommend an approach. The result is a report. In `quick`
mode the result is a chat answer instead. The result is **not** code changes. **Do not implement
anything.** This skill stops at analysis.

The skill handles **two issue kinds**. Step 0 sets the kind. The process is the same for both kinds.
Only the lens set, the finding categories, and the report's docs 3–4 change.

- **bug / investigation:** find gaps, bugs, and risks in existing code. Suggest a fix approach.
- **feature:** survey where a new feature connects to the code. Report the decisions, the
  integration points, and the unknowns.

## When to use this skill and when not to

- **Use this skill** for a pre-change survey of the existing code tied to an issue. Both kinds
  apply.
- **Use `diagnose`** for one known, reproducible bug or performance regression. That skill
  reproduces the bug and fixes it.
- **Use `code-review` or `github-pr-review`** to review a diff, a branch, or a PR. Those skills read
  changed code. This skill reads the existing code that an issue identifies.

## Mode and kind (arguments)

The invocation can carry up to two words, in any order. A **mode** word (`quick`, `default`, or
`deep`) sets the depth of the investigation. A **kind** word (`bug` or `feature`) selects the lens
set and the report variant. With no mode word, the mode is `default`. With no kind word, detect the kind in
Step 0. Ask about an unrecognized word. Do not guess.

**[GATES.md](GATES.md) is the single source** for what each mode does, what each gate presents,
and who can change what. Read it before Step 0. The steps below only mark *where* a gate fires.

## Step 0: Get the issue

Accept any source:

- **GitHub issue** (`#N` or a URL). The user may also want to claim or start the issue (assign,
  branch, comment). In that case, use the `/github-issue-pickup` skill and reuse the issue it
  returns. Otherwise only read the issue. Get `owner` and `repo` from `git remote get-url origin`.
  Then run `gh issue view <N> --json number,title,body,labels,comments`.
- **Pasted text** or a **local file path**. Use it without change.

Distill the issue into three things: the **goal**, the **expected behavior or acceptance criteria**,
and the **keywords or area names** you will search by. The issue may be too vague to show *where* to
search. Then ask one clarifying question **before you map the surface**, and continue.

**Determine the kind** unless an argument gave it. Read it from the labels, the issue template, or
the verbs. The signal table is in [GATES.md](GATES.md). The signals may conflict or be absent. Then
state your best guess. The user confirms it or changes it **at Gate 1**, and you stop there anyway.

## Step 1: Map the affected surface

Use Glob, Grep, and Read to locate the code tied to the issue. Look for entrypoints, modules, data
models, callers, and tests. Produce a short **surface map**. The map lists the key files. For each
file it says what the file does and why the file is relevant.

**Gate 1 fires here.** See [GATES.md](GATES.md).

## Step 2: Size the scope and decide the fan-out

- **Small** (about 5 files or fewer, a single module): analyze it yourself in one pass. Use no
  subagents.
- **Large** (many files, several modules, or a cross-cutting concern): use **lens fan-out**. Start
  one `general-purpose` subagent per lens from the kind's lens set in [CHECKLIST.md](CHECKLIST.md).
  Use the applicable lenses in `default` and every lens in `deep`. Each subagent scans the **whole**
  surface through that single lens. This finds more than a split by module.
- **Matrix** (`deep` with more than one distinct area): use one subagent per area and lens pair.
  `deep` always runs at least a full lens fan-out. It escalates to a matrix only when several areas
  justify it. Never use a matrix on a single-area surface.

Follow the **subagent contract and the per-lens model guidance in [CHECKLIST.md](CHECKLIST.md)**.
Pass each agent the issue context, the surface map, and its lens. Pass the area as well in a matrix.
Each agent returns concise findings, in the [TEMPLATES.md](TEMPLATES.md) format. Launch independent
subagents in the same batch. **You** then dedupe the findings. **You normalize severity (bug) or
reversibility (feature) across agents.** Then you assemble the report. See Steps 4–5.

**Gate 2 fires here** (large scope, and always `deep`). Present the fan-out plan in the format
[GATES.md](GATES.md) shows. Wait for a go before you start any subagent.

## Step 3: Hunt findings

Run the lenses for the issue's kind from [CHECKLIST.md](CHECKLIST.md) over the surface. Use the
breadth your mode dictates. The lens is how you *find* a finding. You then *categorize* it.

Categorize each finding once you find it. Put a **bug** finding into Gap, Bug, or Risk. Put a
**feature** finding into Decision, Integration point, Risk-Unknown, or Open question. The definitions
are in [TEMPLATES.md](TEMPLATES.md), next to the ordering scales.

Ground every finding in a `file:line` and in what the code actually does. A pure requirement or open
question may cite the issue text instead. Make no claim without a reference. Tie findings back to
the issue's goal where relevant.

## Step 4: Recommend an approach

Give a concrete, actionable recommendation for each finding. For a bug, say what to change and why.
For a feature, say which option to take and why. For a feature you may give the hook-in or the
resolution path instead. An approach or pseudocode is fine. **Do not write the full
implementation.** With a fan-out, each subagent proposes the recommendation for its own findings.
You reconcile duplicates and conflicts.

## Step 5: Deliver

**`quick` mode:** answer in chat. Give the relevant lenses you ran, a findings table, and the
recommendation per finding inline. Write no files. Offer a handoff to `write-plan` if the user wants
the answer saved.

**`default` and `deep` modes:** write the report. Assemble the 4 files by **editing the findings the
subagents returned**. Do not re-read the code you already scanned.

**Gate 3 fires here** (large scope, and always `deep`). See [GATES.md](GATES.md). A small scope goes
straight to the write step.

Create `.agents/scratch/issue-analysis/<YYYY-MM-DD-HHMM>-<slug>/` with exactly **four** files.
Docs 1–2 are shared. Docs 3–4 use the variant for the issue's kind. The shared skeleton and the
ordering scales are in [TEMPLATES.md](TEMPLATES.md). Docs 3–4 come from the kind's file, either
[BUG_TEMPLATES.md](BUG_TEMPLATES.md) or [FEATURE_TEMPLATES.md](FEATURE_TEMPLATES.md).

Findings (doc 3) and recommendations (doc 4) stay apart. A **finding ID** (`F-01`, `F-02`, …) links
them, so each finding can be explored later on its own. Then show the findings table and the report
path in chat.

## Notes

- **The ordering scale and the field definitions** live in [TEMPLATES.md](TEMPLATES.md). Bug
  findings are ordered by severity, and feature findings by reversibility. The orchestrator owns the
  final scale. Normalize the provisional values the subagents return, so a value means the same
  thing across the whole report.
- **No findings is a valid result.** Say so plainly. Do not invent low-value findings.
- **You own the final dedupe and merge with a fan-out.** Subagents detect and report. You reconcile
  and write.
- **Handoff:** a finding may be a reproducible bug the user wants fixed *now*. Then hand it to the
  `diagnose` skill, which builds a repro loop and fixes one bug. This skill stays at analysis.
- **Next step:** recommend the `write-plan` skill after you deliver the report or the quick-mode
  answer. **Give `write-plan` the report directory. Name the findings (`F-NN`) the plan should
  address.** `write-plan` reads doc 4 as the plan's raw material. Doc 4 is
  `04-improvement-suggestions.md` for a bug and `04-recommended-approach.md` for a feature. It seeds
  the **Now** lines of the Approach section from `02-current-state.md`. It reuses the scope estimate
  in `01-summary.md` for its
  single-plan-vs-epic call. `execute-plan` then runs the plan gate by gate. The full chain is
  **analyze-issue → write-plan → execute-plan**. Recommend it. Do not invoke it automatically.
