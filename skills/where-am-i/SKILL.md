---
name: where-am-i
argument-hint: "[brief|full]"
allowed-tools: Read Bash(git *) Bash(uname *) Bash(hostname *) Bash(uptime *) Bash(id *) Bash(date *) Bash(ls *) Bash(cat *) Bash(find *) Bash(wc *) Bash(head *) Bash(sort *) Bash(sed *) Bash(stat *)
description: Orient yourself in one session when several are open at once. Reports a three-sentence summary of the work in progress, then where it is happening — project, git branch, worktree, dirty files, ahead/behind — plus which machine you are on (hostname, OS) and how much runway is left (context used, 5-hour and weekly quota). Two levels; brief gives the crucial facts, full adds sibling worktrees, neighbouring checkouts that are also dirty, recent scratch artifacts, and full machine and agent detail. Prints to chat and writes nothing. Use when the user says "where am I", "what am I doing", "what is this session", "status report", "catch me up", "remind me what I was working on", "which machine is this", "how much context is left", or comes back to a session cold after working elsewhere. NOT for handing work to the next agent (use `write-handoff`) — that writes a file for a fresh agent to resume from; this reports live state back to a human.
---

# Where Am I

A person who returns to one of several open sessions asks four questions. What
was I doing, in which checkout, on which machine, and how much runway is left.
This skill answers those four questions. It reads state and prints a report. It
changes nothing.

## Workflow

1. **Pick the level.** `brief` is the default and covers the crucial facts.
   `full` adds everything. Take the level from the argument, or from wording
   like "everything" or "the full picture". Do not ask. Pick a level, and say
   which one you used.

2. **Probe the environment.** Run the commands in [PROBES.md](PROBES.md). Run
   the `brief` set first. Run the `full` set also when you picked that level.
   Batch the commands into as few calls as you can, so the report feels
   instant. A probe that fails makes a field unavailable. Do not guess the
   value, and do not retry the probe.

3. **Read the agent's own state.** Read the context used, the remaining token
   budget, the model, and the quota. Get the context from the session
   transcript with the formula in
   [AGENT-STRATEGIES.md](AGENT-STRATEGIES.md), which also holds the per-agent
   file locations. Get the quota from the usage snapshot in PROBES.md. Report
   only the values that those two sources or the harness gave you. When the
   snapshot is missing or stale, say that the quota is unknown, and name the
   command that shows it.

4. **Write the summary from the conversation, not from the code.** The hard cap
   is three sentences. Say what the task is, where it stands right now, and
   what is next or blocked. The material is already in the session. Do not read
   the repo again to rebuild it. When the session is genuinely empty (fresh
   start, no work yet), say that in one sentence. Do not pad the summary to
   three sentences.

5. **Render from [TEMPLATES.md](TEMPLATES.md).** Match the shape for the level
   you picked. Drop any line whose value is unavailable. Do not print an empty
   field. The quota line is the exception. Print the quota even when it is
   unknown.

6. **End with one next step.** Write a single line that names the concrete next
   action in the session's own terms. Give the command to run, the file to
   open, or the decision that waits for the user. Never write "continue the
   work".

## What each level covers

| Field | `brief` | `full` |
|---|---|---|
| Header: project · branch · host | ✓ | ✓ |
| Work summary, three sentences | ✓ | ✓ |
| Branch, upstream ahead/behind | ✓ | ✓ |
| Git status | dirty file count | file list, stashes, last commit |
| Worktree | flagged only when not the main one | path, and every worktree of the repo |
| Machine | hostname + OS | + kernel, uptime, user, working directory |
| Agent | context used | + model, remaining budget, session identity |
| Quota, 5-hour and weekly | ✓ | ✓ with reset times |
| Neighbouring dirty checkouts | — | ✓ |
| Recent scratch artifacts | — | ✓ |
| Next step | ✓ | ✓ |

## Constraints

### What you report

- **Never invent a number.** Context, quota, ahead/behind, dirty counts, and
  timestamps all come from a command or from something the harness stated. A
  plausible figure is worse than "unavailable". The reader uses this report to
  decide what to do next.
- **Three sentences means three.** The reader reads the summary, and a
  paragraph defeats it. Put the detail in the fields below the summary.
- **Say when a field is unavailable. Do not hide it.** A dropped quota line
  reads as "quota fine". Print the field with "unknown" and the one-line
  reason.
- **Give stale data an age.** Report every value from a cached file with its
  age. A quota snapshot from hours ago describes an hour that is over.

### What you do

- **Stay read-only, always.** Do not write, commit, fetch, or switch branches.
  Nothing in this skill may change the checkout that it describes.
- **Do not investigate the codebase again.** Do not search the code. Do not
  read the source to find what the session did. If the conversation does not
  say, the summary says that it does not.
- **Print to chat only.** This skill writes no files, not even scratch files.
  Use `write-handoff` when the user wants the state saved for a fresh agent.
- **Bound the neighbour scan.** `full` searches a fixed few levels below the
  parent of the repo root. It prunes the trees that hold no checkouts, so it
  reaches nested worktrees and stays fast. Never walk the whole home directory
  to find checkouts.

Nothing feeds this skill. It reads live state. Use `write-handoff` when the
answer to "what next" is "I'm out of context". A good handoff starts from this
report.
