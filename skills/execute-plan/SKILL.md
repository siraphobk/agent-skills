---
name: execute-plan
allowed-tools: Read Write Edit Grep Glob Bash
description: >
  Execute an existing plan from .agents/scratch/plans/ phase by phase, enforcing each phase's Gate
  and the Verification section before declaring work done. Handles a single plan file or an epic
  directory (00-epic.md plus numbered sub-plans, run in dependency order). Reads the plan as the
  source of truth, runs the per-language pre-done checks from CLAUDE.md, and flips progress markers
  so long tasks survive a context reset. Records what shipped — files, gate results, deviations,
  follow-ups — to .agents/scratch/deliverables/ as each phase lands, which github-pr-create uses for
  the PR body. Stops at commit/push boundaries and halts on blocking Open questions instead of
  guessing. Use when the user says "execute the plan", "run the plan", "implement the plan", "run
  the epic", "start on the plan", "continue the plan", "resume the plan", or points at a
  file/directory under .agents/scratch/plans/ and asks to implement it. NOT for planning (use
  write-plan) or for ad-hoc edits with no plan.
---

# Execute a Plan

This skill uses the output of [write-plan]. The plan is the source of truth. Do not re-derive the
design from chat. Do not re-investigate settled decisions. A plan target has one of two shapes:

- **Single plan**: a `*.md` file. Execute it with the per-plan loop (steps 3–7).
- **Epic**: a directory that holds `00-epic.md` plus numbered `NN-<slug>.md` sub-plans. Run the
  epic loop (step 2). That loop executes each sub-plan through the same per-plan loop.

## Workflow

1. **Locate the target and identify its shape.** Use the file or directory the user named. If the
   user named none, list `<repo-root>/.agents/scratch/plans/`, both `*.md` files and subdirectories.
   If more than one candidate exists, ask which one. A directory, or any target that contains
   `00-epic.md`, is an **epic**. A lone `*.md` file is a **single plan**. Read the relevant files in
   full before you act.

2. **Epic loop (epic targets only).** Open `00-epic.md`. Read its **Sub-plans** index and its
   **Sequencing & dependencies** section.
   - **Pick the next sub-plan.** Take the first one still marked `[ ]` whose dependencies are
     already `[x]`. Obey the sequencing. Never start a sub-plan whose blockers are unfinished.
   - **Confirm the start, always, one time.** One confirmation covers both the sub-plan and its
     start phase. State which sub-plan you intend to run. State which phase it starts at. A fresh
     sub-plan starts at Phase 1. A resumed sub-plan starts at its first `[ ]` phase. State what is
     already done. Then **wait for explicit approval**. Do not add step 3's separate phase confirm
     after it. That asks the same question two times.
   - Execute that sub-plan with the per-plan loop (steps 3–7). Read the sub-plan as its own source
     of truth. Step 3's confirm is already covered. Confirm again mid-plan only if the markers you
     find contradict what you announced.
   - **After a sub-plan is complete:** flip its box to `[x]` in the **Sub-plans** index of
     `00-epic.md`. Then fill that sub-plan's sections in the shared epic deliverable (step 8). Then
     return here for the next sub-plan. Confirm each sub-plan. Do not chain sub-plans without a
     prompt.
   - When every sub-plan is `[x]`, run the epic's **Global verification** (step 7). Then complete
     the epic-level deliverable sections (step 8). Then stop.

3. **Confirm the start phase, always (single plans).** Check the Phased rollout for existing
   progress markers (see step 5). Identify the first `[ ]` phase. State which phase you intend to
   start at, and what is already done. Then **wait for explicit approval before you touch code.**
   Never start execution on your own, even when you resume a plan that is clearly half finished. In
   an epic, step 2's confirmation already named the start phase. Skip this confirm and continue.

4. **Report blockers first.** If the plan's Open questions section has items tagged `(blocking)`,
   ask them before you touch code. You note the `(non-blocking)` items and settle them during the
   run. For untagged questions in older plans, treat anything that would change the work as
   blocking. Do not guess past a blocker.

5. **Execute one phase at a time.** Do the following for the current phase only:
   - Make the edits the phase describes, in the files its **Files** field lists. Follow `CLAUDE.md`
     for *how* to write the code: TDD triggers, comments, error handling, language idiom. Do not
     restate those rules here.
   - **Obey the phase's boundary.** Do not touch a file outside the phase's **Files** list. Do not
     touch a file named in its **Don't touch** field. If you cannot do the work inside that
     boundary, stop and report it. That is a plan mismatch, not a judgment call.
   - Run that phase's relevant pre-done checks from `CLAUDE.md`, which are the build and the test
     for the affected language.
   - **Obey the Gate.** Run the Gate's command. Compare the output against the expected result the
     Gate states. Never declare a gate passed from inspection alone. For a `(manual)` gate, report
     exactly what the user must observe. Then stop and wait for approval before the next phase.
     Never run two phases past a gate at one time.

6. **Mark progress and record what landed.** After a phase passes its gate, do both of these, in
   this order:
   - Flip its heading marker from `[ ]` to `[x]`. Plans from write-plan are born with `[ ]` on each
     phase heading. If a heading has no marker, add `[x]` when the phase is done. This marker, plus
     the epic index boxes, is what makes a half-finished job resumable after a context reset.
   - Append that phase's entry to the deliverable file (see **Deliverable** below). Append any
     deviation the phase found. Write it now, while it is fresh. A deviation rebuilt later from the
     diff is a guess.

7. **Run Verification.** After a plan's last phase, run its Verification section word for word. Run
   the concrete commands and checks it lists. Its lines are tagged with the **Acceptance criteria**
   they prove. Report each AC as met or not met. Treat an AC with no passing line as not met. For an
   epic, each sub-plan's own Verification runs when that sub-plan is complete. The **Global
   verification** in `00-epic.md` runs exactly one time, after the last sub-plan, against the epic's
   own ACs. Report results honestly. If something fails, say so and give the output. Do not declare
   the work done on an unrun check or a failing check.

8. **Complete the deliverable.** Fill its **Summary**, **Acceptance criteria** and **Verification
   output** sections from the run that just completed. Close **Not done / follow-ups** with any
   non-blocking open question that is still unanswered. Report the deliverable path. For an epic, do
   this one time per sub-plan, for that sub-plan's sections. Fill the epic-level Summary and Global
   verification after the last sub-plan.

9. **Stop at the boundary.** Leave changes staged or unstaged, per the git-commit and git-push
   rules. Do not commit, do not push, and do not open a PR unless the user asks in the same turn.
   Offer `github-pr-create` as a next step, because it reads the deliverable. Offer any
   work-logging skill you have. Offer only. Do not invoke either one.

## Deliverable

The deliverable is a running record of what actually shipped. Write it **as you go**. Do not rebuild
it at the end. Two readers depend on it. The user studies what landed and what went wrong.
`github-pr-create` otherwise has to guess the PR body from the raw diff.

Paths, section shape, and the epic layout are all in [TEMPLATES.md](TEMPLATES.md). Create the file
with its header and empty sections when the first phase starts. Then fill it as you go. If the file
already exists, because this is a resumed run, **append** to it. Never overwrite it. The record of
the earlier phases is exactly what a context reset would have lost.

## Constraints

### The plan controls the scope and the pace

- **The plan governs scope.** Reality can differ from the plan, because a file moved or an
  assumption was wrong. Stop and report the mismatch. Do not improvise a redesign. Small course
  corrections inside a phase are fine. Structural changes go back to write-plan.
- **One phase per gate, one confirmation per sub-plan start.** Checkpoints are the whole point. Do
  not batch phases. Do not chain sub-plans automatically. Do not stack duplicate confirms. Each of
  those defeats the checkpoints.
- **Obey epic sequencing.** Never start a sub-plan whose dependencies are not `[x]`. If the
  Sequencing section is ambiguous, ask. Do not guess the order.
- **No plan, no skill.** If nothing is under `.agents/scratch/plans/`, say so and offer to run
  write-plan first. Do not invent a plan and execute it silently.

### The written record stays short and honest

- **Do not duplicate CLAUDE.md.** This skill owns the loop: locate, sub-plan, phase, gate, verify,
  resume. It does not own coding style, test policy, or commit rules. Those live in CLAUDE.md.
- **The plan's vocabulary never reaches the code.** Finding IDs (`F-01`), phase numbers, and
  acceptance-criterion numbers are scaffolding for *this* run. They get stripped once the work
  lands. A comment that cites them goes stale the moment the plan file is deleted. Write the reason
  itself instead. Do not write `// F-03: the sniff window is 3072 bytes`. Write `// detection only
  reads the first 3072 bytes`. Issue references (`#4314`) are fine where the repo already uses them,
  because those outlive the plan. This applies to code, to tests, and to commit messages.
- **Comments earn their place.** Add the *why* that a reader cannot get from the code. Add it one
  time, in as few lines as it takes. Rationale belongs in the plan or in the gate report. That
  covers sequencing, alternatives you weighed, and what a later phase will do. Rationale does not
  belong in a comment block above the change.
- **The deliverable records, it does not advertise.** Write what happened. Include the parts that
  went badly: a failed approach, a gate that took three tries, an AC that was not met. A record
  that lists only wins is worthless for the user and for the PR body. Never write a phase entry
  before its gate has passed.
- **The deliverable is a record, not a second plan.** Keep entries short: the phase, the files, and
  what the gate did. Design rationale stays in the plan. Do not copy it into the deliverable.
