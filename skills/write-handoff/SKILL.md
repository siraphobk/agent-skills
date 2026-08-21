---
name: write-handoff
disable-model-invocation: true
allowed-tools: Read Write Bash(git rev-parse *) Bash(mkdir *) Bash(date *)
description: Summarize the current session into a lean, AI-only handoff doc so the next agent can resume cold in a fresh context. Captures the task, what's done / in progress / next, plus pointers to useful files, memories, links, and skills — by reference, never raw dumps, to keep context small. Saves a timestamped file under ~/.agent-skills/<encoded-repo-root>/handoffs/, outside the git repo, auto-scoped to the project so the next session finds it. Use when the user says "hand off this work", "create a handoff", "write a handoff doc", "summarize this for the next agent", "I'm running low on context", "wrap up for a new session", or otherwise wants to pass the current task to another agent. NOT for persisting an implementation plan (use write-plan) — this captures live session state, not a plan to execute.
---

# Write Handoff

A handoff doc is read by the **next AI agent**, not a human. Write it terse and
structured for fast pickup. Its job is to let a fresh agent resume in a new
session with minimal context — so reference everything, embed almost nothing.

## Workflow

1. **Synthesize the session.** Pull the task, what's done, what's in progress,
   and what's next straight from the conversation. Don't re-investigate the
   codebase — the material is already in chat. If the session is too thin to
   hand off, say so and stop.

2. **Gather pointers, not content.** For each item the next agent will need,
   capture a reference, not the thing itself:
   - **Files:** `path/to/file.go:42` plus one line on why it matters.
   - **Memories:** `[[memory-slug]]` from MEMORY.md or recalled this session.
   - **Links:** URLs, issue/PR numbers, docs — with a why.
   - **Skills:** from the available-skills list, only ones that genuinely fit
     the next steps. Name them and say when to use each.

3. **Draft from [TEMPLATE.md](TEMPLATE.md).** Fill the sections; omit any that
   would be empty. Keep prose tight — this doc exists to shrink context, so a
   bloated handoff is a failed handoff. Stamp the `Created` field with a real
   clock time — run `date '+%Y-%m-%d %H:%M'` and use that; never write a vague
   placeholder like "(session)".

4. **Gate — ask for additions, then confirm.** Show the draft in chat and ask
   the user to add anything the next agent should know that isn't already
   captured (gotchas, decisions, half-finished reasoning). Wait for their input
   and approval before writing the file.

5. **Write the file.** Key the path to the git repo root, encoded the same way
   the memory dir is (slashes → dashes):

   ```bash
   root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
   dir=~/.agent-skills/$(printf '%s' "$root" | sed 's#/#-#g')/handoffs
   mkdir -p "$dir"
   file=$dir/handoff-$(date +%Y%m%d-%H%M%S).md
   ```

   Write the approved draft to `$file` and report the full path. Tell the user
   the next session picks it up by opening that file — the newest one in `$dir`
   is always the current handoff, which is why the name is timestamped.

## Constraints

- **Audience is an AI, not a human.** No greetings, no recap padding, no
  praise. Dense, scannable, structured. Optimize for a cold agent picking it up
  fast, not for human readability.
- **Reference, never embed.** Point to files by `path:line`, memories by
  `[[slug]]`, work by link. Do NOT paste raw code, full logs, file contents, or
  command output unless a short snippet is the only way to convey a non-obvious
  state — and then keep it to the few lines that matter.
- **Only what's real.** Every `file:line`, `[[memory]]`, and skill name must
  come from this session or be verified before the draft is shown. Don't invent
  paths or suggest skills that don't exist in the available list.
- **Omit empty sections.** Drop any section that would only hold filler. A lean
  doc beats a complete-but-padded one.
- **Don't save in the project dir.** The file always goes under
  `~/.agent-skills/<encoded-root>/handoffs/`, never inside the repo — it must
  not get committed.
- **Scope ends at file creation.** Don't keep working the task after writing.
  The handoff is the deliverable; the next session does the rest.
