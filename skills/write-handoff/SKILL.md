---
name: write-handoff
disable-model-invocation: true
allowed-tools: Read Write Bash(git rev-parse *) Bash(mkdir *) Bash(date *)
description: Summarize the current session into a lean, AI-only handoff doc so the next agent can resume cold in a fresh context. Captures the task, what's done / in progress / next, plus pointers to useful files, memories, links, and skills — by reference, never raw dumps, to keep context small. Saves a timestamped file under ~/.agent-skills/<encoded-repo-root>/handoffs/, outside the git repo, auto-scoped to the project so the next session finds it. Use when the user says "hand off this work", "create a handoff", "write a handoff doc", "summarize this for the next agent", "I'm running low on context", "wrap up for a new session", or otherwise wants to pass the current task to another agent. NOT for persisting an implementation plan (use write-plan) — this captures live session state, not a plan to execute.
---

# Write Handoff

The **next AI agent** reads a handoff doc. A human does not. Write the doc
short and structured, so the next agent starts fast. The doc lets a fresh agent
continue the work in a new session with a small context. Therefore reference
everything, and embed almost nothing.

## Workflow

1. **Summarize the session.** Take the task, the finished work, the work in
   progress, and the next steps directly from the conversation. Do not
   investigate the codebase again. The material is already in the chat. If the
   session holds too little content for a handoff, say so and stop.

2. **Collect references, not content.** For each item that the next agent
   needs, write a reference to the item. Do not write the item itself.
   - **Files:** `path/to/file.go:42` and one line about why the file matters.
   - **Memories:** `[[memory-slug]]` from MEMORY.md, or a memory recalled in
     this session.
   - **Links:** URLs, issue numbers, PR numbers, and docs. Give a reason for
     each one.
   - **Skills:** only the skills from the available-skills list that truly fit
     the next steps. Name each skill and say when to use it.

3. **Draft from [TEMPLATE.md](TEMPLATE.md).** Complete each section. Omit each
   section that would be empty. Keep the prose short. The doc exists to make
   the context smaller, so a long handoff is a failed handoff. Put a real clock
   time in the `Created` field. Run `date '+%Y-%m-%d %H:%M'` and use the
   result. Never write a vague placeholder like "(session)".

4. **Gate. Ask for additions, then confirm.** Show the draft in the chat. Ask
   the user for anything more that the next agent must know, such as traps,
   decisions, or unfinished reasoning. Wait for the user's answer and approval
   before you write the file.

5. **Write the file.** Build the path from the git repo root. Encode the root
   the same way the memory directory does, and replace each slash with a dash:

   ```bash
   root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
   dir=~/.agent-skills/$(printf '%s' "$root" | sed 's#/#-#g')/handoffs
   mkdir -p "$dir"
   file=$dir/handoff-$(date +%Y%m%d-%H%M%S).md
   ```

   Write the approved draft to `$file`. Report the full path. Tell the user
   that the next session opens that file to continue the work. The newest file
   in `$dir` is always the current handoff. The name carries a timestamp for
   this reason.

## Constraints

- **The reader is an AI, not a human.** Write no greeting, no padded recap, and
  no praise. Keep the doc dense, easy to scan, and structured. Write for an
  agent that starts cold and must read fast. Do not write for a human reader.
- **Use a reference, never an embed.** Point to a file with `path:line`, to a
  memory with `[[slug]]`, and to other work with a link. Do NOT paste raw code,
  full logs, file contents, or command output. A short snippet is allowed in
  one case only. Use a snippet when nothing else can show a state that is not
  obvious. Keep the snippet to the few lines that matter.
- **Write only what is real.** Every `file:line`, `[[memory]]`, and skill name
  must come from this session. If it does not, verify it before you show the
  draft. Do not invent a path. Do not suggest a skill that is absent from the
  available list.
- **Omit empty sections.** Remove each section that would hold only filler. A
  short doc is better than a complete doc with padding.
- **Do not save the file in the project directory.** The file always goes under
  `~/.agent-skills/<encoded-root>/handoffs/`. Never put the file inside the
  repo. The file must not enter a commit.
- **The work stops when the file exists.** Do not continue the task after you
  write the file. The handoff is the result. The next session does the rest.
