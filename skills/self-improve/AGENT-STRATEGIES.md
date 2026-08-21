# Where each destination class actually lives, per agent

`SKILL.md` decides *what class* of thing a lesson is. This file says where that class
lives, and — for the two classes Cursor cannot write — what to do instead.

**This is the only file in the repo allowed to name agent-specific paths.** `validate.sh`
exempts it by path. Do not copy these locations back into `SKILL.md`.

## Detecting the agent

| Observation | Conclusion |
|---|---|
| `~/.claude` exists, no `.cursor/` in the project | Claude Code |
| `.cursor/` in the project, or `~/.cursor` exists | Cursor |
| both, or neither | **ask** — one line: "Which agent am I running in, Claude Code or Cursor?" |

Never guess when the signals disagree. Writing a proposal into the wrong tool's config
file is silent — nothing errors, the instruction simply never loads.

## Claude Code

| Destination class | Location |
|---|---|
| User-level instructions | `~/.claude/CLAUDE.md` |
| Policy rule + index entry | `~/.claude/rules/<topic>.md`, plus a bullet in the Rules list of `~/.claude/CLAUDE.md` |
| Memory fragment + index line | the memory directory a memory skill owns, else `~/.agent-skills/<encoded-root>/memory/` |
| A new skill | `<skills-dir>/<name>/SKILL.md` |
| Project instructions | the project's `CLAUDE.md` or `AGENTS.md` |
| Project-private memory | `~/.claude/projects/<encoded-root>/memory/` |
| Automation hook | `settings.json`, via the `update-config` skill |

**Project-private memory is a built-in, not a folder we picked.** Claude Code loads
`~/.claude/projects/<encoded-root>/memory/` on its own. Writing that class anywhere else
still writes a file — it just never gets read again.

## Cursor

| Destination class | Location |
|---|---|
| User-level instructions | **not writable** — see below |
| Policy rule + index entry | **not writable** — see below |
| Memory fragment + index line | `~/.agent-skills/<encoded-root>/memory/` |
| A new skill | `.cursor/skills/<name>/SKILL.md`, or `~/.cursor/skills/` for a global one |
| Project instructions | `AGENTS.md` at the project root, or `.cursor/rules/<topic>.mdc` with `alwaysApply: true` |
| Project-private memory | `.cursor/rules/<topic>.mdc`, and tell the user to gitignore it |
| Automation hook | `settings.json`, via the `update-config` skill |

### The two classes Cursor cannot write

Cursor keeps User Rules in `Customize → Rules` in the settings UI, not in a file. There is
no path to write, so **write nothing and hand back the text**:

```
proposal 2/4 → USER RULES (manual — Cursor has no writable user-level file)

Paste into: Customize → Rules → User Rules

    When correcting code, state the reason before showing the diff.
```

**Do not downgrade a user-level rule into a project rule to make it land somewhere.**
Writing `.cursor/rules/<topic>.mdc` with `alwaysApply: true` looks like success and is
not: a rule meant to hold everywhere would then apply to one repo, and the user would
have to rediscover the gap in every other project. Report the limit instead.

The same applies to a policy rule. It is the same manual paste, worded as a MUST/never.

## Keeping this file honest

- A destination class appears in **both** agent tables, even when the answer is
  "not writable" — a missing row reads as an oversight.
- When a class is unwritable, the row says so and the section below says what to hand
  back. Never leave the reader to infer the fallback.
- `SKILL.md`'s Routing table is the list of classes. If a class is added there, add a row
  to both tables here in the same edit.
