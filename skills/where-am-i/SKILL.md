---
name: where-am-i
argument-hint: "[brief|full]"
allowed-tools: Read Bash(git *) Bash(uname *) Bash(hostname *) Bash(uptime *) Bash(id *) Bash(date *) Bash(ls *) Bash(cat *) Bash(find *) Bash(wc *) Bash(head *) Bash(sort *) Bash(sed *) Bash(stat *)
description: Orient yourself in one session when several are open at once. Reports a three-sentence summary of the work in progress, then where it is happening — project, git branch, worktree, dirty files, ahead/behind — plus which machine you are on (hostname, OS) and how much runway is left (context used, 5-hour and weekly quota). Two levels; brief gives the crucial facts, full adds sibling worktrees, neighbouring checkouts that are also dirty, recent scratch artifacts, and full machine and agent detail. Prints to chat and writes nothing. Use when the user says "where am I", "what am I doing", "what is this session", "status report", "catch me up", "remind me what I was working on", "which machine is this", "how much context is left", or comes back to a session cold after working elsewhere. NOT for handing work to the next agent (use `write-handoff`) — that writes a file for a fresh agent to resume from; this reports live state back to a human.
---

# Where Am I

Answers the four questions a person has when they tab back into one of several
running sessions: what was I doing, in which checkout, on which machine, and how
much runway is left. It reads state and prints a report — it changes nothing.

## Workflow

1. **Pick the level.** `brief` is the default and covers the crucial facts.
   `full` adds everything. Take it from the argument, or from wording like
   "everything" / "the full picture". Don't ask — pick and say which you used.

2. **Probe the environment.** Run the commands in [PROBES.md](PROBES.md) — the
   `brief` set first, and the `full` set too when that level was picked. Batch
   them into as few calls as you can; this should feel instant. A probe that
   fails is a field marked unavailable, never a guess and never a retry loop.

3. **Read the agent's own state.** Context used, remaining token budget, model,
   and quota. Context comes off the session transcript by the formula in
   [AGENT-STRATEGIES.md](AGENT-STRATEGIES.md), which is where the per-agent file
   locations live; quota comes from the usage snapshot in PROBES.md. Report
   nothing neither of those nor the harness actually gave you, and when the
   snapshot is missing or stale say the quota is unknown and name the command
   that shows it.

4. **Write the summary from the conversation, not the code.** Three sentences,
   hard cap: what the task is, where it stands right now, what is next or
   blocked. The material is already in the session — do not re-read the repo to
   reconstruct it. When the session is genuinely empty (fresh start, no work
   yet), say that in one sentence instead of padding three.

5. **Render from [TEMPLATES.md](TEMPLATES.md).** Match the shape for the level
   you picked. Drop any line whose value is unavailable rather than printing an
   empty field, except quota — an unknown quota is worth saying out loud.

6. **End with one next step.** A single line naming the concrete next action, in
   the session's own terms: the command to run, the file to open, the decision
   waiting on the user. Never "continue the work".

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

- **Never invent a number.** Context, quota, ahead/behind, dirty counts and
  timestamps all come from a command or from something the harness stated. A
  plausible-looking figure is worse than "unavailable", because the whole point
  of this report is deciding what to do next from it.
- **Read-only, always.** No writes, no commits, no fetches, no branch switches.
  Nothing in this skill may change the checkout it is describing.
- **Three sentences means three.** The summary is the part that gets read; a
  paragraph defeats it. Detail belongs in the fields below it.
- **Don't re-investigate the codebase.** No searching, no reading source to work
  out what the session was doing. If the conversation doesn't say, the summary
  says it doesn't.
- **Say when a field is unavailable, don't hide it.** A dropped quota line reads
  as "quota fine". Print the field with "unknown" and the one-line reason.
- **Stale data gets an age.** Any value read from a cached file is reported with
  how old it is. A quota snapshot from hours ago describes an hour that is over.
- **Chat only.** This skill writes no files, not even scratch. If the user wants
  the state persisted for a fresh agent to pick up, that is `write-handoff`.
- **Bound the neighbour scan.** `full` searches a fixed few levels below the
  parent of the repo root and prunes the trees that hold no checkouts, so it
  reaches nested worktrees without getting slow. Never walk the whole home
  directory hunting for checkouts.

Nothing feeds this skill; it reads live state. When the answer to "what next" is
"I'm out of context", hand off with `write-handoff` — this report is the input a
good handoff is written from.
