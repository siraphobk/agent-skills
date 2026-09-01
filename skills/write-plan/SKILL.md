---
name: write-plan
allowed-tools: Read Write Edit Grep Glob Bash(mkdir *) Bash(date *)
description: Draft an implementation plan (feature, fix, refactor) or findings writeup and save it under `.agents/scratch/plans/` — a single timestamped file for a cohesive change, or an epic directory (`00-epic.md` + numbered sub-plans) when the job spans multiple independently-executable workstreams. Consumes an analyze-issue report when one exists, carrying its `F-NN` finding IDs into the plan. Draft is shown in chat for approval before any file is written. Use when the user says "plan this feature/fix", "draft a plan", "create an implementation plan", "plan this epic", "break this into sub-plans", "save/document this as a plan", or otherwise asks to persist a plan or analysis to disk. NOT for analyzing an issue (use analyze-issue) or executing a plan (use execute-plan).
---

# Plan

## Workflow

1. **Collect the inputs.** Take the goal, the constraints, and any code findings
   already in chat. Read the `analyze-issue` report when one exists, which is a
   directory under `.agents/scratch/issue-analysis/` that the user names or
   points at. Its `03-gaps-bugs-risks.md` and `04-improvement-suggestions.md` are
   the raw material, and `02-current-state.md` seeds the **Now** lines of
   Approach. Ask which findings (`F-NN`) the plan must address when that is not
   settled. Investigate no further, because the material must already exist in
   chat or in the report. Ask one or two questions when there is not enough to
   draft from. Stop and say so when the job is a findings writeup with nothing to
   record.

2. **Assess the scope.** Decide which output fits, and prefer the simpler one:
   - **Single plan** *(default, most jobs)*: one cohesive change a single phased
     rollout can carry, inside one bounded context or area.
   - **Epic** *(only when warranted)*: the job covers **multiple
     independently-executable workstreams**, meaning separate bounded contexts or
     lifecycles. A rollout that would grow into many phases across unrelated areas
     also counts. Each workstream becomes its own standalone sub-plan, with its
     own goal, files, verification, and execution.
   - **Reuse the scope estimate from an analyze-issue report when one exists.**
     The *areas* in the report are the candidate workstreams. Several distinct
     areas with independent rollouts make an epic. One area makes a single plan,
     whatever the number of phases.
   - **The check:** a long phased rollout *in one area* is still one plan. Only
     multiple independent workstreams justify an epic. Prefer a single plan when
     the case is borderline, and say why.
   - **Gate. Confirm the shape.** For a single plan, say so in one line and
     continue. For an epic, present the sub-plan list, one title and one-line goal
     for each, plus the sequencing and dependencies. **Wait for go** before you
     draft the full plans. This is the cheap place to catch a bad split.

3. **Determine the path:**
   - **Single:** `<repo-root>/.agents/scratch/plans/YYYY-MM-DD-<kebab-case-topic>.md`.
   - **Epic:** a directory `<repo-root>/.agents/scratch/plans/YYYY-MM-DD-<kebab-case-epic>/`.
     It holds `00-epic.md` (overview) plus one `NN-<kebab-case-subplan>.md` per
     sub-plan. Number the sub-plans in execution order.
   - Date source: `currentDate` from global memory, or `date +%Y-%m-%d` when it
     is absent.
   - Slug: lowercase, kebab-case, 6 words or fewer, derived from the topic.

4. **Check the path:** create `.agents/scratch/plans/` or the epic directory with
   `mkdir -p` when it is missing. Ask whether to overwrite, append, or pick a new
   slug when the target already exists.

5. **Draft in chat. Do not call Write yet.** Omit a section only when honest work
   leaves it genuinely empty.
   - **Pin the file list first.** Each phase names every path it touches, so fix
     the paths before you draft. Read the files you cite to confirm the paths and
     line ranges, and find the callers you would otherwise name only as "and
     related". These targeted reads make the phases executable, and they are not a
     second investigation of the design.
   - **Single:** draft the plan body from the template in
     [TEMPLATES.md](TEMPLATES.md).
   - **Epic:** draft the epic overview (`00-epic.md`) first, then each sub-plan
     from the same template. For a large epic, draft the sub-plans one at a time.
     Keep each one reviewable.

6. **Wait for explicit approval** ("go", "save it", "looks good"). Revise in chat
   and confirm again when the user asks for edits. Never write before approval.

7. **Write after approval.** For an epic, write every file, the overview and all
   sub-plans. Report the absolute path of the file, or of the epic directory. Then
   give the recap, described in the next section. Do not restate the plan section
   by section. The user just read the draft. The recap is a different document.

## The recap

Close with a recap after you report the path. Write it for a reader with zero
context, who never saw the investigation and forgot the chat. The plan file is
for the executor. The recap is for the human. It answers two questions, in this
order:

1. **What we are doing.** Give the ground before the figure. Describe the system
   as it is today, then the problem, then the shape of the fix. Explain each piece
   of domain jargon the plan depends on in a sentence or two. Say what the mapping
   table is, and say which config wins when two of them collide. The recap is
   where terms get explained, not the plan.
2. **What is going to happen.** Give one ASCII map of the phases. Each line reads
   phase → outcome, in real domain nouns. Follow the map with a short narrative of
   why the phases exist in that order. Say which phases are preparation, which one
   is the heart, and what each one buys.

End on the boundary. Say what is still not fixed after this plan, and name the
follow-up that owns it. That line is a statement, not an offer.

Keep the recap a narrative in plain sentences. A recap that only rephrases the
section headings of the plan has failed. Its value is that it rebuilds the context
the plan file compresses on purpose.

## Templates

The full templates and a worked example live in
**[TEMPLATES.md](TEMPLATES.md)**. Read that file before you draft. Copy the
complete structure from there. It gives the sections for a single plan, for a
sub-plan, and for an epic overview. It also says what goes in each section, and
when to omit one.

**execute-plan parses the phase format. Keep the heading line exact.** Each
phase heading opens with a `[ ]` box. execute-plan flips that box to `[x]` when
the gate passes. The heading also names the ACs that the phase advances. The
entries in the `Sub-plans` index carry the same `[ ]` box. TEMPLATES.md gives
the exact shape of both.

**AC numbers are local to each file.** The phases in a sub-plan cite the ACs of
that sub-plan. They never cite the ACs of the epic overview.

## Constraints

### Make the plan stand alone

- **The plan must stand alone.** execute-plan reads the plan as the only source
  of truth, and may run it in a fresh context with no chat history. Never refer
  to "the code above", to "as we discussed", or to anything that exists only in
  this conversation. Write the real paths, names, and decisions into the plan. A
  plan a fresh reader cannot execute is not done.
- **Do not invent code paths or findings.** Every `file_path:line` and every
  claim about the current state must come from the conversation or from the
  analyze-issue report. Confirm anything from neither source with a read before
  you show the draft. Every cited path must exist, except the ones marked
  `(new)`. Recall is not verification, and a grep that matched nothing does not
  prove the symbol is absent.
- **Answer open questions before you list them.** An Open question is what is
  *left* after you try to answer it, not a list of everything undecided. First
  read the file, run the command, and check the history. A question you answer
  becomes a decision in Approach, so change its C-NN when the answer changes it.
  This work is what makes the plan executable, not a second investigation of the
  design.

### Write phases an agent can execute

- **Phases must be executable on their own.** A phase is under-specified when a
  fresh agent cannot do it without a second read of Approach. Approach explains
  *why*. The phase carries enough detail to do the work.
- **Name symbols, not areas.** Write `billing/webhook.go:handleEvent`, never "the
  webhook handler". A new function gets a signature when a later phase must call
  it.
- **List every file a phase touches in that phase.** Do not write "and related
  callers". Find those callers while you plan, and name them.
- **One phase is one commit-sized change.** Split the phase when it touches more
  than about 5 files. Split it as well when it holds two unrelated concerns.
- **Length follows the work.** The extra detail belongs in the phase specs, not in
  longer design prose. Never pad a phase to look thorough.

### Prove the plan with gates and verification

- **A gate runs. It does not narrate.** A gate is a command plus its expected
  result. A gate that is only prose lets an agent declare a pass without a run of
  anything. Mark the genuine exceptions `(manual)`.
- **Verification proves every acceptance criterion.** An AC that no line covers is
  untestable, so rewrite it. The other cause is that the plan is missing work.
- **Scope every AC and every verification line to what the phase touches.** A
  criterion like "no `X` remains anywhere under `cmd/`" contradicts the plan's own
  Non-goals as soon as one service is excluded, and the grep then flags files
  nobody was asked to change. Name the directories or files the phase declares,
  not the whole tree.
- **Every phase gets a gate when the plan drives implementation.** A phased
  rollout with no gate per phase defeats the purpose. Merge a phase into its
  neighbor when it truly has nothing checkable. Gates are optional for pure
  findings writeups.

### Keep the file format

- **Do not reformat the progress markers.** execute-plan finds the `[ ]` boxes on
  phase headings and epic `Sub-plans` entries by exact match, then flips them to
  `[x]`. Keep the format exactly as the templates show it. A move or a restyle of
  a box breaks resume-after-reset, and nothing warns you.
- **Do not add extra sections.** Examples are Risks, Alternatives, Migration
  notes, and References. Add one only when the user explicitly asks for it.
- **Omit empty sections.** Drop a section that would hold only "N/A" or filler.
  Drop Non-goals only when no nearby work could enter the plan. Drop Acceptance
  criteria and Verification only for a pure findings writeup with nothing to
  execute. An implementation plan without those two is incomplete, not lean.

### Keep one job per save, and stop at the file

- **Do not choose an epic too readily.** Default to a single plan. Only multiple
  independently-executable workstreams justify an epic, and many phases in one
  plan do not. Write a single plan when you are in doubt.
- **Write one output per save.** A single job gives one plan file, or one epic
  directory. Unrelated jobs are not workstreams of one goal, so ask which job to
  write first. Never put unrelated jobs into one epic.
- **The scope of this skill ends at file creation.** Do not start work on the
  plan after that, unless the user asks.
- **Recommend the next step.** After you write the files, recommend the
  `execute-plan` skill, which runs the plan phase by phase and gate by gate, and
  an epic sub-plan by sub-plan. Only recommend it. Implementation begins when
  the user asks.
