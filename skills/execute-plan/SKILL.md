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

Consumes the output of [write-plan]. The plan is the source of truth — do not re-derive the
design from chat or re-investigate settled decisions. A plan target is one of two shapes:

- **Single plan** — a `*.md` file. Execute it with the per-plan loop (steps 3–7).
- **Epic** — a directory holding `00-epic.md` plus numbered `NN-<slug>.md` sub-plans. Run the
  epic loop (step 2), which executes each sub-plan through the same per-plan loop.

## Workflow

1. **Locate the target and identify its shape.** If the user named a file or directory, use it.
   Otherwise list `<repo-root>/.agents/scratch/plans/` — both `*.md` files and subdirectories — and,
   if more than one candidate, ask which. A directory (or any target containing `00-epic.md`) is an
   **epic**; a lone `*.md` is a **single plan**. Read the relevant file(s) in full before acting.

2. **Epic loop (epic targets only).** Open `00-epic.md` and read its **Sub-plans** index and
   **Sequencing & dependencies**.
   - **Pick the next sub-plan:** the first one still marked `[ ]` whose dependencies are already
     `[x]`. Respect the sequencing — never start a sub-plan whose blockers are unfinished.
   - **Confirm the start — always, once.** One confirmation covers both the sub-plan and its
     starting phase: state which sub-plan you intend to run, which phase it starts at (fresh
     sub-plan → Phase 1; resumed → its first `[ ]` phase), and what's already done, then **wait for
     explicit approval**. Don't follow it with step 3's separate phase confirm — that would ask the
     same question twice.
   - Execute that sub-plan via the per-plan loop (steps 3–7), reading it as its own source of
     truth. Step 3's confirm is already covered; re-confirm mid-plan only if the markers you find
     contradict what was announced.
   - **On sub-plan completion:** flip its box to `[x]` in `00-epic.md`'s Sub-plans index, fill that
     sub-plan's sections in the shared epic deliverable (step 8), then return here for the next
     sub-plan. Re-confirm each one — do not chain sub-plans unprompted.
   - When every sub-plan is `[x]`, run the epic's **Global verification** (step 7), finish the
     epic-level deliverable sections (step 8), then stop.

3. **Confirm the starting phase — always (single plans).** Check the Phased rollout for existing
   progress markers (see step 5) and identify the first `[ ]` phase. State which phase you intend
   to start at and what's already done, then **wait for explicit approval before touching code.**
   Never begin executing on your own, even when resuming an obviously half-finished plan. In an
   epic, step 2's confirmation already named the starting phase — skip this confirm and proceed.

4. **Surface blockers first.** If the plan's Open questions section has items tagged `(blocking)`,
   ask them before touching code; `(non-blocking)` items are noted and settled mid-flight. For
   untagged questions (older plans), treat anything that would change the work as blocking. Do not
   guess past a blocker.

5. **Execute one phase at a time.** For the current phase only:
   - Make the edits the phase describes, in the files its **Files** field lists. Follow `CLAUDE.md`
     for *how* to write the code — TDD triggers, comments, error handling, language idiom. Do not
     restate those rules here.
   - **Respect the phase's boundary.** A file outside the phase's **Files** list, or named in its
     **Don't touch** field, stays untouched. If the work can't be done without straying, stop and
     report it — that's a plan mismatch, not a judgment call.
   - Run that phase's relevant pre-done checks from `CLAUDE.md` (build + test for the affected
     language).
   - **Honor the Gate.** Run the Gate's command and compare against the expected result it states —
     never declare a gate passed off inspection alone. For a `(manual)` gate, report exactly what
     the user should observe. Then stop and wait for approval before the next phase. Never run two
     phases past a gate in one go.

6. **Mark progress and record what landed.** After a phase passes its gate, do both, in this order:
   - Flip its heading marker from `[ ]` to `[x]` (plans from write-plan are born with `[ ]` on each
     phase heading; if a heading lacks one, add `[x]` when the phase is done). This — plus the epic
     index boxes — is what makes a half-finished job resumable after a context reset.
   - Append that phase's entry to the deliverable file (see **Deliverable** below), plus any
     deviation the phase turned up. Write it now, while it's fresh — a deviation reconstructed
     later from the diff is a guess.

7. **Run Verification.** After a plan's last phase, run its Verification section verbatim — the
   concrete commands/checks it lists. Its lines are tagged with the **Acceptance criteria** they
   prove; report each AC as met or not, and treat an AC with no passing line as not met. For an
   epic: each sub-plan's own Verification runs when that sub-plan completes, and `00-epic.md`'s
   **Global verification** runs exactly once, after the last sub-plan, against the epic's own ACs.
   Report results honestly: if something fails, say so with the output. Do not declare done on an
   unrun or failing check.

8. **Finish the deliverable.** Fill its **Summary**, **Acceptance criteria** and **Verification
   output** sections from the run just completed, and close out **Not done / follow-ups** with any
   non-blocking open question left unanswered. Report its path. For an epic, do this once per
   sub-plan for that sub-plan's sections, and fill the epic-level Summary and Global verification
   after the last one.

9. **Stop at the boundary.** Leave changes staged/unstaged per the git-commit and git-push rules. Do
   not commit, push, or open a PR unless the user asks in the same turn. Offer `github-pr-create`
   (it reads the deliverable) as a next step, along with any work-logging skill you have — offer
   only; don't invoke either.

## Deliverable

A running record of what actually shipped, written **as you go** — not reconstructed at the end.
Two readers depend on it: the user, studying what landed and what went sideways; and
`github-pr-create`, which otherwise has to guess the PR body from the raw diff.

Paths, section shape, and the epic layout are all in [TEMPLATES.md](TEMPLATES.md). Create the
file with its header and empty sections when the first phase starts, then fill as you go. If the
file already exists (a resumed run), **append** — never overwrite; the earlier phases' record is
exactly what a context reset would have lost.

## Constraints

- **The plan governs scope.** If reality diverges from the plan (a file moved, an assumption was
  wrong), stop and report the mismatch instead of improvising a redesign. Small in-phase course
  corrections are fine; structural changes go back to write-plan.
- **One phase per gate, one confirmation per sub-plan start.** The whole point is checkpoints.
  Batching phases, auto-chaining sub-plans, or stacking duplicate confirms all defeat it.
- **Respect epic sequencing.** Never start a sub-plan whose dependencies aren't `[x]`. If the
  Sequencing section is ambiguous, ask rather than guess the order.
- **Don't duplicate CLAUDE.md.** This skill owns the *loop* (locate → sub-plan → phase → gate →
  verify → resume). It does not own coding style, test policy, or commit rules — those live in
  CLAUDE.md.
- **The plan's vocabulary never reaches the code.** Finding IDs (`F-01`), phase numbers, and
  acceptance-criterion numbers are scaffolding for *this* run. They get stripped once the work
  lands, and a comment citing them goes stale the moment the plan file is deleted. Write the
  reason itself instead: not `// F-03: the sniff window is 3072 bytes`, but `// detection only
  reads the first 3072 bytes`. Issue references (`#4314`) are fine where the repo already uses
  them — those outlive the plan. Applies to code, tests, and commit messages alike.
- **Comments earn their place.** Add the *why* that cannot be read off the code, once, in as few
  lines as it takes. Rationale about sequencing, alternatives weighed, or what a later phase will
  do belongs in the plan or the gate report — not in a comment block above the change.
- **The deliverable records, it doesn't advertise.** Write what happened, including the parts that
  went badly — a failed approach, a gate that took three tries, an AC that came out not met. A
  record that only lists wins is worthless for both the user and the PR body. Never write a phase
  entry before its gate has actually passed.
- **The deliverable is a record, not a second plan.** Keep entries short — the phase, the files,
  what the gate did. Design rationale stays in the plan; it does not get copied over.
- **No plan, no skill.** If there's nothing under `.agents/scratch/plans/`, say so and offer to run
  write-plan first. Don't invent one and execute it silently.
