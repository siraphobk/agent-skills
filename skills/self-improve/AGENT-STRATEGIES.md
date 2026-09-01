# Where each destination class lives, per agent

`SKILL.md` decides *what class* of thing a lesson is. This file says where that class
lives. For the two classes Cursor cannot write, this file says what to do instead.

**Only this file may name agent-specific paths.** `validate.sh` exempts this file by
path. Do not copy these locations into `SKILL.md`.

## Detect the agent

| Observation | Conclusion |
|---|---|
| `~/.claude` exists, no `.cursor/` in the project | Claude Code |
| `.cursor/` in the project, or `~/.cursor` exists | Cursor |
| both, or neither | **ask**. Use one line: "Which agent am I running in, Claude Code or Cursor?" |

Never guess when the signals disagree. A proposal written into the wrong tool's config
file fails with no sign. Nothing errors, and the instruction never loads.

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
`~/.claude/projects/<encoded-root>/memory/` on its own. If you write that class anywhere
else, you still write a file. Nothing reads that file again.

## Cursor

| Destination class | Location |
|---|---|
| User-level instructions | **not writable**. See below. |
| Policy rule + index entry | **not writable**. See below. |
| Memory fragment + index line | `~/.agent-skills/<encoded-root>/memory/` |
| A new skill | `.cursor/skills/<name>/SKILL.md`, or `~/.cursor/skills/` for a global one |
| Project instructions | `AGENTS.md` at the project root, or `.cursor/rules/<topic>.mdc` with `alwaysApply: true` |
| Project-private memory | `.cursor/rules/<topic>.mdc`, and tell the user to gitignore it |
| Automation hook | `settings.json`, via the `update-config` skill |

### Cursor cannot write two of the classes

Cursor keeps User Rules in `Customize → Rules` in the settings UI, not in a file. There is
no path to write. **Write nothing and return the text to the user**:

```
proposal 2/4 → USER RULES (manual — Cursor has no writable user-level file)

Paste into: Customize → Rules → User Rules

    When correcting code, state the reason before showing the diff.
```

**Do not change a user-level rule into a project rule just to give it a home.** A write to
`.cursor/rules/<topic>.mdc` with `alwaysApply: true` looks like success. It is not. A rule
that must hold everywhere would then apply to one repo. The user would find the same gap
again in every other project. Report the limit instead.

The same applies to a policy rule. Use the same manual paste, in the words of a MUST or
never rule.

## Keep this file honest

- A destination class appears in **both** agent tables, even when the answer is
  "not writable". A missing row reads as an oversight.
- When a class is not writable, the row says so. The section below says what to return to
  the user. Never make the reader guess the fallback.
- The Routing table in `SKILL.md` is the list of classes. If someone adds a class there,
  add a row to both tables here in the same edit.
