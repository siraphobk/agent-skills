---
name: self-improve
allowed-tools: Read Write Edit Grep Glob
description: Retrospective on the current session that turns it into concrete config changes. Reviews what worked and what needed correcting — especially corrections given more than once — then proposes the exact text to add and the exact file to add it to (user-level instructions, a policy rule, a memory fragment, a new or existing skill, project instructions, or project-private memory), ranked, each backed by a quoted moment. Resolves those destinations per agent, and hands back paste-ready text for anything the running agent cannot write. Waits for per-item approval; never edits config on its own. Use when the user says "review this session", "summarize and review our session", "what did we learn", "let's do a retro", "self-improve", "how can we work better", "what should you remember from this", or asks where a lesson from this session should be saved. NOT for saving a single fact the user hands you, and NOT for logging finished work — this sweeps a whole session for patterns.
---

# Self-Improve

A session retro ends in config changes, not feelings. This skill gives you a
ranked proposal table and the literal text to write. Then it stops until the
user approves each item. This skill is the batch half of the
repeated-correction rule. That rule fires the moment a correction repeats. This
skill reviews the whole session for the corrections that the rule missed.

Destinations differ per agent, and one agent can do less than the other. This
file decides *what class* of change a lesson deserves.
[AGENT-STRATEGIES.md](AGENT-STRATEGIES.md) says where that class lives.

## Workflow

1. **Read the session again. Do not recall it.** Read the actual turns. Recall
   flatters you. The transcript does not. Collect evidence under these
   headings. Record the moment that proves each one.

   | Evidence type | What to look for |
   |---|---|
   | Corrections | "no", "actually", "don't do that", or a request rephrased after a wrong answer. Mark the ones that repeated. |
   | Mid-turn interrupts | Each interrupt means you went where the user did not want. |
   | Rework | A file edited twice for one reason. A draft redone after feedback you could have asked for first. |
   | Confusion | "explain again", "what do you mean". The output shape missed. This is not a user problem. |
   | Friction | Denied permissions, retried commands, or a skill that did not trigger when it should have. |
   | Wins | An approach the user accepted in explicit words. A locked win is worth as much as a fixed miss. |

2. **Filter the evidence. Most of it does not earn a change.** A config change
   fixes a *class* of behavior. A one-time slip does not.

   | Signal | Verdict |
   |---|---|
   | Correction given 2+ times (this session or a past one) | **Must propose** |
   | User stated a lasting preference ("always…", "from now on…") | **Must propose** |
   | One-off correction with a stated reason | Propose |
   | Confirmed win worth repeating | Propose |
   | One-off, task-specific, no reason given | Drop. Say that you noted it. |
   | You were careless once and caught it | Drop. This is not a config gap. |

3. **Detect the agent.** The agent decides where each proposal can go. Cursor
   cannot write two of the destination classes. Follow the detection table in
   [AGENT-STRATEGIES.md](AGENT-STRATEGIES.md). **Ask the user when the signals
   disagree.** A write into the wrong tool's config fails with no sign. Nothing
   errors, and the instruction never loads.

4. **Check what the config already says.** Read the target file first. That is
   the file `AGENT-STRATEGIES.md` names for that class in the agent you
   detected. Read the skill in question too. If the config already covers the
   lesson, quote the existing line. Then say that the config was right and that
   you did not follow it. If the config covers the lesson in part, propose an
   **edit to that line**, not a new line.

5. **Route each item that survives to a class.** See *Routing* below for the
   class. Then see `AGENT-STRATEGIES.md` for its location. Name the level, user
   or project, for every item. Mark each class your agent cannot write.

6. **Present the proposal, then stop.** Give one ranked table. Then give the
   literal text for each item.

   | # | Evidence (what happened) | Change | Destination | Level |
   |---|---|---|---|---|

   Turn each **Destination** into the real location for the detected agent.
   Write `(manual)` next to each destination the agent cannot write. Under the
   table, give the exact text to add for each item. For an edit, give the exact
   before and after of the line. Keep the table to **5** items. A retro that
   proposes fifteen changes gets none of them applied. Put everything else in a
   one-line "noted, not proposed".

7. **Apply only the approved items, one at a time.** "Yes to 1 and 3" means 1
   and 3. Then:
   - **Memory fragment** → If a dedicated memory skill is installed, give the
     write to that skill. It owns the write. If no memory skill is installed,
     do the write yourself. This class needs two files, not one. Write the
     fragment, then write one index line that points to it. A fragment with no
     index line never loads. The first file alone achieves nothing, and nothing
     warns you.
   - **Policy rule** → Write the rule file **and** its index entry. A rule with
     no index entry never loads.
   - **Instructions or skill edits** → Edit the file directly.
   - **Hook or automation** → Give the work to the `update-config` skill.
   - **A class this agent cannot write** → Write nothing. Print the exact block.
     Print where the user must paste it, as `AGENT-STRATEGIES.md` shows. Never
     use a narrower destination just to give the text a home.

   Report every path you touched. Report every item you returned as manual.

## Routing

This table names classes, not paths. [AGENT-STRATEGIES.md](AGENT-STRATEGIES.md)
turns each class into a path for the agent you detected.

| Kind of lesson | Destination class | Level |
|---|---|---|
| Response style or workflow default, true in every repo | user-level instructions | user |
| Non-negotiable MUST / never | policy rule + index entry | user |
| Learned knowledge, trap, or convention that may evolve | memory fragment + index line | user |
| Repeatable multi-step procedure | a new skill | user |
| An existing skill that behaves wrong | that skill's `SKILL.md` | user |
| Repo-specific, worth sharing with the team | project instructions | project |
| Repo-specific, private to you | project-private memory | project |
| "Whenever X happens, do Y" automation | automation hook via `update-config` | either |

If you add a class to this table, add a row to **both** agent tables in
`AGENT-STRATEGIES.md`. Do this in the same edit, even when the answer is "not
writable".

## Constraints

| Constraint | What it means |
|---|---|
| Evidence, or the change does not ship | Every change cites a real moment. No inferred pattern, and no "you might prefer". |
| Never edit before approval | The table is the gate. Approval of one item never carries to another item. |
| An update beats an addition | A near-duplicate rule is worse than no rule. The two rules drift, and neither one wins. |
| Propose behavior, not virtue | "Be more careful" is not actionable. "Read the file before you claim a symbol is absent" is checkable. |
| Do not propose what the repo already records | This covers code structure, git history, and the project instructions file. |
| Stop after the retro | The skill ends after the approved writes. Do not continue into other work. |

See [EXAMPLES.md](EXAMPLES.md) for a worked proposal at the right density.
