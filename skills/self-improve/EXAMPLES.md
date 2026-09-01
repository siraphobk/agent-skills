# self-improve worked example

This example sets the density of a proposal. The evidence is a moment the reader
recognizes. The changes are small enough to paste. Each home names the exact file.

This run detected **Claude Code**. The destinations below name the class and the file.
[AGENT-STRATEGIES.md](AGENT-STRATEGIES.md) turned each class into a directory. In Cursor,
items 1 and 3 would become manual pastes for the user.

## The session

The session ran two hours on a Go billing bug. The user corrected the assistant
three times about code shown before an explanation. The user corrected the
assistant once about a migration run with no question first. The user also
accepted a "check the live cluster first" suggestion. The assistant grepped for
a symbol, found nothing, and said the symbol was absent. That claim was wrong.

## The proposal, as presented

> Five items, ranked. I write nothing until you say which ones to apply.

| # | Evidence (what happened) | Change | Destination | Level |
|---|---|---|---|---|
| 1 | Three times you said "explain first, then the code", at turns 12, 26, 41 | Sharpen the existing explanation-first bullet to name code blocks explicitly | user-level instructions, `CLAUDE.md` (edit) | user |
| 2 | Grep for `chargeWallet` returned nothing. I said "no caller exists". Two callers existed, in a generated file. | New cautionary fragment: an empty grep is not evidence | a memory fragment + index line | user |
| 3 | "Never run a migration without asking me", at turn 33, stated as always-on | New hard rule + index bullet | policy rule, `db-migrations.md` | user |
| 4 | At turn 19 you confirmed a read of the live cluster over the Helm chart | Lock the win into the existing k8s fragment | memory fragment, `cautionary/k8s-live-not-chart.md` (edit) | user |
| 5 | `go test ./billing/...` needed `TESTDB_URL` set. I searched for it twice. | Record the env var this repo's tests need | project memory | project |

**Noted, not proposed:** you preferred `wallet` over `balance` in one function
name. That is a one-off, task-specific choice, not a standing preference.

### The exact edit for item 1

Your user-level instructions file, under Response Style:

```
- **Explanation-first:** Before showing code for any decision or non-trivial
  change, explain the reasoning in 6th grader vocab first — what and why — then
  attach the code. Don't lead with a code block and a one-line caption.
```

Before the edit, the bullet stopped at "…then attach the code." The new sentence
names the part that the assistant missed again and again.

### The exact new file for item 3

A new policy rule, `db-migrations.md`:

```md
# Database Migration Rules

## Hard Rules

**Never run a migration without explicit approval.**
- No `migrate up`, `migrate down`, or framework equivalent unless the user asks
  in the same turn.
- Writing a migration file is fine. Running it is not.
- On a shared or production database, confirm even when asked — name the target.

## Override Condition

Suspended when the user names the command and the target in the same turn.
```

Add one bullet to the Rules index of your user-level instructions file:

```
- **`db-migrations.md`** — never run a migration unprompted; writing one is fine.
```

## Why this proposal worked

- **Every row names a turn.** A reader can check "Turns 12, 26, 41". A reader
  cannot check "you seemed to prefer".
- **Item 1 edits a line. It does not add one.** The rule already existed. The
  gap was that the rule stopped one sentence too early.
- **Item 3 got a rule, and item 2 got a memory fragment.** "Never do X" is
  policy. "greps lie in this specific way" is knowledge that may evolve.
- **Item 5 went to project-private memory, not a user-level fragment.** It is
  true of one repo.
- **The report still names the dropped item.** One line is enough, so the user
  can overrule the drop.

## An "already covered" row

When the config already says it, do not propose a change. Show the existing line:

> **Not proposed.** You asked me twice not to commit unprompted.
> `rules/git-commit.md` already says it: *"Do not run `git commit` (any form)
> unless the user explicitly asks for a commit in the same turn."* The gap was
> that I did not follow the rule. No config change would have prevented it.
