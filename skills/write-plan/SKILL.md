---
name: write-plan
allowed-tools: Read Write Edit Grep Glob Bash(git *) Bash(mkdir *) Bash(date *)
description: Draft an implementation plan (feature, fix, refactor) or findings writeup and save it under `.agents/scratch/plans/` — a single timestamped file for a cohesive change, or an epic directory (`00-epic.md` + numbered sub-plans) when the job spans multiple independently-executable workstreams. Consumes an analyze-issue report when one exists, carrying its `F-NN` finding IDs into the plan. Draft is shown in chat for approval before any file is written. Use when the user says "plan this feature/fix", "draft a plan", "create an implementation plan", "plan this epic", "break this into sub-plans", "save/document this as a plan", or otherwise asks to persist a plan or analysis to disk. NOT for analyzing an issue (use analyze-issue) or executing a plan (use execute-plan).
---

# Plan

Turn settled goals and findings into an executable plan. Save only after approval.
Use [TEMPLATES.md](TEMPLATES.md) for sections, field definitions, progress markers,
and worked examples. Read it before you draft.

## Workflow

1. **Collect the inputs.** Use the goal, constraints, and findings from chat or
   the report the user names. Read that exact report path.
   When an analyze-issue report exists, retain the selected `F-NN` finding IDs
   and use its Current state section to seed Approach.
   Ask which findings to include only when the requested scope leaves that undecided.
   Stop when a findings writeup has nothing to record.

2. **Verify what execution needs.** Reuse settled design decisions.
   Verify paths, callers, commands, and assumptions needed to make the plan executable.
   Use targeted reads and searches. Inspect scripts and configuration to verify proposed commands.
   Use read-only Git commands when history can answer a specific question.
   Record answers as decisions in Approach. Ask only about unresolved decisions.
   If evidence contradicts a settled decision, explain the conflict before changing the design.
   Do not expand this work into a new issue analysis or implement the plan.

3. **Choose the output shape.**
   - **Single plan is the default.** Use it for one coherent change, even with many phases.
   - **Use an epic only for multiple independently executable workstreams toward one goal.**
     Distinct report areas with separate rollouts can identify these workstreams.
     Each sub-plan needs its own goal, files, verification, and dependencies.
   - For a single plan, state the choice and continue.
     For an epic, present each sub-plan title and goal, with sequencing and dependencies.
     Wait for approval of this split before drafting the full plans.
   - Prefer a single plan when the distinction is unclear. State why.
     Do not combine unrelated jobs into an epic.

4. **Choose and check the path.**
   - **Single:** `<repo-root>/.agents/scratch/plans/YYYY-MM-DD-<kebab-case-topic>.md`.
   - **Epic:** `<repo-root>/.agents/scratch/plans/YYYY-MM-DD-<kebab-case-epic>/`.
     Use `00-epic.md` and `NN-<kebab-case-subplan>.md`, numbered in execution order.
   - Use the current session date, or `date +%Y-%m-%d` when it is unavailable.
     Derive a lowercase kebab-case slug of six words or fewer from the topic.
   - Check for an existing target before drafting.
     If it exists, ask whether to overwrite, append, or choose a new slug.

5. **Draft in chat.** Use the templates without creating files yet.
   Confirm every cited path and line range. Find callers and list their paths,
   rather than writing "and related callers".
   For an epic, draft the overview first, then each sub-plan.
   Draft large sub-plans one at a time so each remains reviewable.

6. **Wait for explicit approval.** Approval includes "go", "save it", or "looks good".
   Revise in chat when the user requests changes, then obtain approval of that revision.

7. **Save the approved output.** Create the parent directory with `mkdir -p` if needed.
   Write the single plan, or the epic overview and every approved sub-plan.
   Report the absolute file or directory path, then give the brief recap below.
   Stop after saving. Execution belongs to `execute-plan` and requires a user request.

## Recap

State the problem, the intended outcome, and why the phase order matters.
Do not repeat each plan section. Include an ASCII dependency diagram only when
three or more nodes need a visual explanation.
State important exclusions. Name follow-up work only when it already exists.
The recap must not introduce definitions or decisions absent from the saved plan.

## Constraints

### Keep the plan self-contained

- The complete plan must support execution without chat history.
  Include necessary definitions, assumptions, precedence rules, paths, and decisions.
  Phases may refer to Approach for rationale. They still need explicit actions
  and dependencies, as defined in TEMPLATES.md.
- Ground current-state claims in supplied evidence or targeted repository reads.
  Mark planned paths that do not exist as `(new)`.
  An empty search result alone does not prove a symbol is absent.
- List an open question only after targeted checks cannot answer it.
  Tag it as blocking or non-blocking using the template.

### Keep scope and verification aligned

- Every implementation phase needs a gate. Keep related changes together until
  the phase reaches a checkable stopping point.
- Scope acceptance criteria and checks to the declared work.
  Do not require changes to areas excluded by Non-goals.
  Verification must cover every acceptance criterion, including outcomes spanning phases.
- Put implementation detail in phase actions, not repeated design prose.
  Do not pad a phase or split it solely because of file count.

### Preserve the output contract

- Follow TEMPLATES.md for section order, field definitions, omission rules, and progress markers.
  Add sections only when the user requests them.
- Write one plan or one epic per save. Ask which unrelated job to handle first
  if the requested output combines separate goals.
- Do not write before approval or start implementation after saving.
