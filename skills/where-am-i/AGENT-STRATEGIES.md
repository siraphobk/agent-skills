# Reading context used, per agent

`SKILL.md` and `PROBES.md` decide *what* to report. This file says where the number
comes from, per agent, and what to do where it cannot be had.

**This file is allowed to name agent-specific paths**, because that is its whole job.
`validate.sh` exempts it by full path — the filename alone is not enough, so do not copy
these locations back into the neutral files.

## Detecting the agent

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

Pick the file by session id when the harness exposes one. Otherwise take the most
recently modified `.jsonl` in that directory — the running session writes on every turn,
so it is the newest, though two sessions in one directory make this a guess worth naming
as one.

**The formula.** Take the **last** entry with `type` of `assistant` that carries a
`message.usage`, and add three of its fields:

```
context used = input_tokens + cache_creation_input_tokens + cache_read_input_tokens
```

Three things about that formula are easy to get wrong:

- **The last entry, never a sum.** Every request re-sends the whole context, so the newest
  entry already *is* the current size. Adding entries up counts the same tokens once per
  turn and produces a number many times too large.
- **Skip sidechain entries.** An entry with `isSidechain` set to true is a subagent's turn,
  and its context is a different window entirely. Taking it reports the subagent's size as
  the session's.
- **Compaction needs no special case.** The first request after a compact carries the
  smaller context, so reading the newest entry tracks it for free.

**The percentage.** Report the raw token count always. Add a percentage only when the
running agent knows its own context window size — windows differ per model, so a
hardcoded divisor is wrong the moment the session is on a different one. When the window
is unknown, print the raw count alone rather than a percentage of a guess.

## Cursor

There is no documented transcript file to read. Report context used as unavailable, with
the reason in the same line, and do not substitute a figure from anywhere else.

## Keeping this file honest

- Both agents get a section, even when the answer is "cannot be read" — a missing section
  reads as an oversight rather than a limit.
- Adding an agent here means adding its path to `HOST_PATH_EXEMPT` in `scripts/validate.sh`
  only if a *new file* is involved; this one is already exempt.
