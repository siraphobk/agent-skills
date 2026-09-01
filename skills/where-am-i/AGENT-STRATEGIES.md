# How to read context used, per agent

`SKILL.md` and `PROBES.md` decide *what* to report. This file says where the number
comes from, per agent. It also says what to do when you cannot get the number.

**This file is allowed to name agent-specific paths**, because that is its whole job.
`validate.sh` exempts it by full path. The filename alone is not enough. Do not copy
these locations into the neutral files.

## How to detect the agent

| Observation | Conclusion |
|---|---|
| `~/.claude` exists, no `.cursor/` in the project | Claude Code |
| `.cursor/` in the project, or `~/.cursor` exists | Cursor |
| both, or neither | Report context as unavailable and say why. Never guess |

## Claude Code

The session transcript is a JSONL file under:

```
~/.claude/projects/<cwd with every / replaced by ->/<session-id>.jsonl
```

Pick the file by session id when the harness exposes one. If not, take the most
recently modified `.jsonl` file in that directory. The running session writes on every
turn, so its file is the newest. Two sessions in one directory make this choice a
guess, so name it as a guess.

**The formula.** Take the **last** entry with `type` of `assistant` that carries a
`message.usage`, and add three of its fields:

```
context used = input_tokens + cache_creation_input_tokens + cache_read_input_tokens
```

Three things about that formula are easy to get wrong:

- **Use the last entry, never a sum.** Every request re-sends the whole context, so the
  newest entry already *is* the current size. A sum of the entries counts the same
  tokens once per turn. It produces a number many times too large.
- **Skip sidechain entries.** An entry with `isSidechain` set to true is a subagent's
  turn, and its context is a different window. If you take that entry, you report the
  subagent's size as the session size.
- **Compaction needs no special case.** The first request after a compact carries the
  smaller context. The newest entry therefore shows the smaller number for free.

**The percentage.** Always report the raw token count. Add a percentage only when the
running agent knows its own context window size. Windows differ per model, so a
hardcoded divisor is wrong as soon as the session runs on a different model. When the
window is unknown, print the raw count alone. Do not print a percentage of a guess.

## Cursor

There is no documented transcript file to read. Report the context used as unavailable,
and give the reason on the same line. Do not substitute a figure from another source.

## How to keep this file honest

- Both agents get a section, even when the answer is "cannot be read". A missing section
  reads as an oversight and not as a limit.
- When you add an agent here, add its path to `HOST_PATH_EXEMPT` in `scripts/validate.sh`.
  Do this only if the agent needs a *new file*. This file is already exempt.
