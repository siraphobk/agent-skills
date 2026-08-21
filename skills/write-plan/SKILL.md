---
name: write-plan
allowed-tools: Read Write Edit Grep Glob Bash(mkdir *) Bash(date *)
description: Draft an implementation plan (feature, fix, refactor) or findings writeup and save it under `.agents/scratch/plans/` — a single timestamped file for a cohesive change, or an epic directory (`00-epic.md` + numbered sub-plans) when the job spans multiple independently-executable workstreams. Consumes an analyze-issue report when one exists, carrying its `F-NN` finding IDs into the plan. Draft is shown in chat for approval before any file is written. Use when the user says "plan this feature/fix", "draft a plan", "create an implementation plan", "plan this epic", "break this into sub-plans", "save/document this as a plan", or otherwise asks to persist a plan or analysis to disk. NOT for analyzing an issue (use analyze-issue) or executing a plan (use execute-plan).
---

# Plan

## Workflow

1. **Synthesize the inputs.** Pull the goal, constraints, and any code findings already in chat. If an `analyze-issue` report exists for this job (a directory under `.agents/scratch/issue-analysis/`, named in chat or pointed at by the user), read it — the findings in `03-gaps-bugs-risks.md` and `04-improvement-suggestions.md` are the plan's raw material, and `02-current-state.md` seeds the **Now** lines of the Approach section. Ask which findings (`F-NN`) the plan should address if that isn't already settled. Do not re-investigate beyond that — the material should already exist in chat or in the report. If there isn't enough to draft from, ask one or two clarifying questions first (or stop and say so, if it's purely a findings writeup with nothing to capture).

2. **Assess scope — single plan or epic.** Decide which deliverable fits, biasing toward the simpler one:
   - **Single plan** *(default — most jobs)*: one cohesive change a single phased rollout can carry, within one bounded context / area.
   - **Epic** *(only when warranted)*: the job spans **multiple independently-executable workstreams** — separate bounded contexts or lifecycles, or a rollout that would balloon into many phases across unrelated areas. Each workstream becomes its own standalone sub-plan with its own goal, files, verification, and execution.
   - **If an analyze-issue report exists, reuse its scope estimate instead of re-deriving:** the report's *areas* are the candidate workstreams. Multiple distinct areas with independent rollouts → epic; one area → single plan, no matter how many phases.
   - **The guard:** a long phased rollout *in one area* is still one plan — many phases alone don't justify an epic; multiple independent workstreams do. When borderline, prefer single and say why.
   - **Gate — confirm the shape.** If single, say so in one line and continue. If epic, present the proposed breakdown — the sub-plan list (title + one-line goal each) and their sequencing/dependencies — and **wait for go** before drafting the full plans. This is the cheap place to catch an over- or under-scoped split.

3. **Determine the path:**
   - **Single:** `<repo-root>/.agents/scratch/plans/YYYY-MM-DD-<kebab-case-topic>.md`.
   - **Epic:** a directory `<repo-root>/.agents/scratch/plans/YYYY-MM-DD-<kebab-case-epic>/` holding `00-epic.md` (overview) plus one `NN-<kebab-case-subplan>.md` per sub-plan, numbered in execution order.
   - Date source: `currentDate` from global memory if present; otherwise `date +%Y-%m-%d`.
   - Slug: lowercase, kebab-case, ≤ 6 words, derived from the topic.

4. **Check the path:**
   - Create `.agents/scratch/plans/` (or the epic directory) with `mkdir -p` if missing.
   - If the target file/directory already exists, ask whether to overwrite, append, or pick a new slug.

5. **Draft in chat — do not call Write yet.** Omit a section only if it would be genuinely empty after honest synthesis.
   - **Pin the file list first.** Each phase names every path it touches, so resolve them before drafting: read the files you cite to confirm the paths and line ranges, and look up the callers you'd otherwise wave at as "and related". Targeted reads to nail down paths and symbols are expected here — that's not re-investigating the design, it's what makes the phases executable.
   - **Single:** draft the plan body using the template in [TEMPLATES.md](TEMPLATES.md) (skeleton in *Templates* below).
   - **Epic:** draft the epic overview (`00-epic.md`) first, then each sub-plan using the same template. For a large epic, drafting sub-plans one at a time for review is fine — keep each reviewable.

6. **Wait for explicit approval** ("go", "save it", "looks good"). If the user requests edits, revise in chat and re-confirm. Never write before approval.

7. **Write** after approval. For an epic, write every file (overview + all sub-plans). Report the absolute path — the file, or the epic directory. Do not summarize the content back — they just read the draft.

## Templates

The full templates and a worked example live in **[TEMPLATES.md](TEMPLATES.md)** —
read it before drafting and copy the complete structure from there. The
skeletons below are inline so you know the shape at a glance; the file has the
per-section guidance (what goes in each, when to omit).

**Single plan / each sub-plan** — these sections, in order:

```md
# <Plan Title>
## Goal              — the change and what "done" looks like; name F-NN if from a report
## Non-goals         — nearby work this plan leaves alone, one line why each
## Acceptance criteria — numbered AC-NN, checkable facts not tasks
## Approach          — overall design + tradeoffs, then one C-NN Now/Change block per change
## Phased rollout    — numbered, revertible phases (format below)
## Verification      — copy-pasteable check per AC (omit if analytical)
## Open questions    — each tagged (blocking) / (non-blocking)
```

**Phase format is parsed by execute-plan — keep the heading line exact.** Each
heading opens with a `[ ]` box (flipped to `[x]` on gate pass) and names the ACs
it advances. The four fields under it are what the executing agent works from:

```md
1. **[ ] Phase 1 — <name>** (AC-1, fixes F-01)
   **Files:** <every path touched, `(new)` on ones it creates>
   **Does:** apply C-NN — <the work, naming symbols not areas>
   **Don't touch:** <nearby code that stays as-is, and why — omit if nothing is at risk>
   **Gate:** `<command>` → <expected result>
```

**Epic overview (`00-epic.md`)** — these sections:

```md
# <Epic Title>
## Goal                      — outcome across every sub-plan
## Non-goals                 — adjacent work no sub-plan covers (omit if none)
## Acceptance criteria       — epic-level AC-NN, integration-scale
## Current state             — context spanning sub-plans (omit if none shared)
## Sub-plans                 — ordered index, each with a `[ ]` box (format below)
## Sequencing & dependencies — what blocks what / what's parallel
## Global verification       — integration-level proof, tagged per epic AC
## Open questions            — epic-level, tagged (blocking) / (non-blocking)
```

AC numbering is local to each file — a sub-plan's phases cite that sub-plan's
ACs, never the epic overview's.

The `Sub-plans` index entries also carry a parsed `[ ]` box, and each sub-plan
file opens with a backlink above its title:

```md
## Sub-plans
1. `01-<slug>.md` — <one-line goal>  [ ]
2. `02-<slug>.md` — <one-line goal>  [ ]
```
```md
> Part of the [<epic title>](00-epic.md) epic.
# <Sub-plan Title>
```

## Constraints

- **The plan must stand alone.** execute-plan reads the plan as the sole source of truth and may run it in a fresh context with no chat history. So no references to "the code above", "as we discussed", or anything that only exists in this conversation — inline the actual file paths, names, and decisions. If a fresh reader couldn't execute it, it's not done.
- **Do not invent code paths or findings.** Every `file_path:line` reference and every claim about current state must come from the conversation, the analyze-issue report, or be verified by a read before the draft is shown. Every path the draft cites must exist — confirm each one, except those marked `(new)`. Recall is not verification, and a grep that matched nothing is not proof the symbol is absent.
- **Resolve open questions before listing them.** An Open question is what's *left* after you've tried to answer it — not a list of everything undecided. Read the file, run the command, check the history first. Only what genuinely can't be settled that way goes in the section; anything you resolve becomes a decision in Approach instead. This is in scope for the same reason pinning the file list is — it's not re-investigating the design, it's what makes the plan executable. If the answer changes a C-NN, change it.
- **Phases must be executable on their own.** A phase a fresh agent can't carry out without re-reading Approach is under-specified. Approach explains *why*; the phase carries enough to do the work.
- **Name symbols, not areas.** `billing/webhook.go:handleEvent`, never "the webhook handler". New functions get a signature when a later phase has to call them.
- **Every file a phase touches is listed in that phase.** No "and related callers" — find them while planning and name them.
- **Gates run, they don't narrate.** A gate is a command plus its expected result. A prose-only gate lets an agent declare a pass without running anything. Mark the genuine exceptions `(manual)`.
- **Every acceptance criterion is proved in Verification.** An AC no line covers is either untestable — rewrite it — or the plan is missing work.
- **One phase, one commit-sized change.** More than ~5 files, or two unrelated concerns in one phase, means split it.
- **Length follows the work.** The added detail belongs in the phase specs, not in longer design prose. Never pad a phase to look thorough.
- **Don't reformat the progress markers.** The `[ ]` boxes on phase headings (and on epic Sub-plans entries) are parsed and flipped to `[x]` by execute-plan via exact match. Keep the format exactly as the templates show it — moving or restyling them silently breaks resume-after-reset.
- **Do not add extra sections** (Risks, Alternatives, Migration notes, References, etc.) unless the user explicitly asked for them.
- **Omit empty sections.** If a section would only contain "N/A" or filler, drop it entirely. Don't pad. Non-goals goes only when nothing nearby could get pulled in; Acceptance criteria and Verification go only for a pure findings writeup with nothing to execute — an implementation plan without them is incomplete, not lean.
- **Don't over-epic.** Default to a single plan. An epic is justified only by multiple independently-executable workstreams — not by one plan merely having many phases. When in doubt, ship one plan.
- **Every phase gets a gate when the plan drives implementation.** A phased rollout without per-phase gates defeats the purpose for forward-looking work. If a phase truly has nothing checkable, collapse it into a neighbor. For pure findings writeups, gates are optional.
- **One deliverable per save.** A single job → one plan file or one epic directory. If the user is mixing genuinely unrelated jobs (not workstreams of one goal), ask which to write first — don't bundle unrelated jobs into one epic.
- **Skill scope ends at file creation.** Do not start implementing the plan afterwards unless asked.
- **Next step:** after writing, recommend the `execute-plan` skill to carry the plan out phase by phase, gate by gate (for an epic, sub-plan by sub-plan). Recommend it; don't invoke it automatically — implementation only begins when the user asks.
