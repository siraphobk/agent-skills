---
name: self-improve
allowed-tools: Read Write Edit Grep Glob
description: Retrospective on the current session that turns it into concrete config changes. Reviews what worked and what needed correcting — especially corrections given more than once — then proposes the exact text to add and the exact file to add it to (user-level instructions, a policy rule, a memory fragment, a new or existing skill, project instructions, or project-private memory), ranked, each backed by a quoted moment. Resolves those destinations per agent, and hands back paste-ready text for anything the running agent cannot write. Waits for per-item approval; never edits config on its own. Use when the user says "review this session", "summarize and review our session", "what did we learn", "let's do a retro", "self-improve", "how can we work better", "what should you remember from this", or asks where a lesson from this session should be saved. NOT for saving a single fact the user hands you, and NOT for logging finished work — this sweeps a whole session for patterns.
---

# Self-Improve

A session retro that ends in config changes, not feelings: a ranked proposal
table plus the literal text to write, then a stop until the user approves item by
item. This is the batch half of the repeated-correction rule — that rule fires the
moment a correction repeats; this skill sweeps the whole session for the ones that
slipped past.

Destinations differ per agent, and one of them can do less than the other. This
file decides *what class* of change a lesson deserves;
[AGENT-STRATEGIES.md](AGENT-STRATEGIES.md) says where that class lives.

## Workflow

1. **Re-read the session — don't recall it.** Walk the actual turns. Recall
   flatters; the transcript doesn't. Collect evidence under these headings, each
   with the moment that proves it:
   - **Corrections** — "no", "actually", "don't do that", a request rephrased
     after a wrong answer. Mark which ones repeated.
   - **Mid-turn interrupts** — each one means you were heading somewhere they
     didn't want.
   - **Rework** — a file edited twice for the same reason; a draft redone after
     feedback that could have been known up front.
   - **Confusion** — "explain again", "what do you mean". An output-shape miss,
     not a user problem.
   - **Friction** — denied permissions, retried commands, a skill that didn't
     trigger when it should have.
   - **Wins** — an approach the user explicitly accepted. Locking one in is
     worth as much as fixing a miss.

2. **Filter — most of what you found does not earn a change.** A config change
   fixes a *class* of behavior. A one-time slip does not.

   | Signal | Verdict |
   |---|---|
   | Correction given 2+ times (this session or a past one) | **Must propose** |
   | User stated a lasting preference ("always…", "from now on…") | **Must propose** |
   | One-off correction with a stated reason | Propose |
   | Confirmed win worth repeating | Propose |
   | One-off, task-specific, no reason given | Drop — say you noted it |
   | You were careless once and caught it | Drop — not a config gap |

3. **Detect the agent.** Which one you are in decides where every proposal can go,
   and two destination classes are unwritable in Cursor. Follow the detection table
   in [AGENT-STRATEGIES.md](AGENT-STRATEGIES.md) and **ask when the signals
   disagree** — writing into the wrong tool's config fails silently, since nothing
   errors and the instruction simply never loads.

4. **Check what's already there.** Read the target first — whichever file
   `AGENT-STRATEGIES.md` names for that class in the agent you detected, plus the
   skill in question. Already covered → quote the existing line and say "already
   covered — the miss was following it, not the config". Partly covered → propose an
   **edit to that line**, not a new one.

5. **Route each survivor to a class.** See *Routing* below for the class, then
   `AGENT-STRATEGIES.md` for its location. Name the level — user or project — for
   every item, and mark any class your agent cannot write.

6. **Present, then stop.** One ranked table, then the literal text per item:

   | # | Evidence (what happened) | Change | Destination | Level |
   |---|---|---|---|---|

   Resolve each **Destination** to the real location for the detected agent, and
   write `(manual)` on any the agent cannot write. Under the table, for each item:
   the exact text to add or the exact before/after of the line to edit. Cap the
   table at **5** — a retro proposing fifteen changes gets none applied. Everything
   else goes in a one-line "noted, not proposed".

7. **Apply only what's approved, item by item.** "Yes to 1 and 3" means 1 and 3.
   Then:
   - **Memory fragment** → if a dedicated memory skill is installed, hand off to it;
     it owns the write. Otherwise do it yourself, and it is two files, not one:
     the fragment, then one index line pointing at it. An unindexed fragment never
     loads, so writing only the first file silently achieves nothing.
   - **Policy rule** → write the rule file **and** its index entry. A rule nobody
     indexes never loads.
   - **Instructions / skill edits** → edit directly.
   - **Hook / automation** → hand off to the `update-config` skill.
   - **A class this agent cannot write** → write nothing. Print the exact block and
     where the user must paste it, as `AGENT-STRATEGIES.md` shows. Never substitute
     a narrower destination to make it land somewhere.
   Report every path touched, and every item handed back as manual.

## Routing

Classes, not paths — [AGENT-STRATEGIES.md](AGENT-STRATEGIES.md) resolves each one for
the agent you detected.

| Kind of lesson | Destination class | Level |
|---|---|---|
| Response style or workflow default, true in every repo | user-level instructions | user |
| Non-negotiable MUST / never | policy rule + index entry | user |
| Learned knowledge, trap, or convention that may evolve | memory fragment + index line | user |
| Repeatable multi-step procedure | a new skill | user |
| An existing skill behaving wrong | that skill's `SKILL.md` | user |
| Repo-specific, worth sharing with the team | project instructions | project |
| Repo-specific, private to you | project-private memory | project |
| "Whenever X happens, do Y" automation | automation hook via `update-config` | either |

Adding a class here means adding a row to **both** agent tables in
`AGENT-STRATEGIES.md` in the same edit, even when the answer is "not writable".

## Constraints

- **Evidence or it doesn't ship.** Every change cites a real moment. No inferred
  patterns, no "you might prefer".
- **Never edit before approval.** The table is the gate, and approving one item
  never carries to another.
- **Update beats add.** A near-duplicate rule is worse than no rule — the two
  drift and neither wins.
- **Propose behavior, not virtue.** "Be more careful" is unactionable. "Read the
  file before claiming a symbol is absent" is checkable.
- **Don't propose what the repo already records** — code structure, git history,
  content already in the project's instructions file.
- **Retro, then stop.** Ends after the approved writes; don't roll into other work.

See [EXAMPLES.md](EXAMPLES.md) for a worked proposal at the right density.
