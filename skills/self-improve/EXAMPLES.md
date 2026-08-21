# self-improve — worked example

Calibration for the proposal density: evidence a reader recognizes, changes
small enough to paste, and a home named down to the file.

This run detected **Claude Code**. Destinations below name the class and the file;
[AGENT-STRATEGIES.md](AGENT-STRATEGIES.md) is what resolved each one to a directory.
In Cursor, items 1 and 3 would be handed back as manual pastes instead.

## The session

Two hours on a Go billing bug. The user corrected the assistant three times about
showing code before explaining it, once about running a migration without asking,
and accepted a "check the live cluster first" suggestion. The assistant also
grepped for a symbol, found nothing, and declared it absent — wrongly.

## The proposal, as presented

> Five items, ranked. Nothing is written until you say which.

| # | Evidence (what happened) | Change | Destination | Level |
|---|---|---|---|---|
| 1 | Three times you said "explain first, then the code" — turns 12, 26, 41 | Sharpen the existing explanation-first bullet to name code blocks explicitly | user-level instructions, `CLAUDE.md` (edit) | user |
| 2 | Grep for `chargeWallet` returned nothing, I said "no caller exists" — there were two, in a generated file | New cautionary fragment: an empty grep is not evidence | a memory fragment + index line | user |
| 3 | "Never run a migration without asking me" — turn 33, stated as always-on | New hard rule + index bullet | policy rule, `db-migrations.md` | user |
| 4 | You confirmed reading the live cluster over the Helm chart — turn 19 | Lock the win into the existing k8s fragment | memory fragment, `cautionary/k8s-live-not-chart.md` (edit) | user |
| 5 | `go test ./billing/...` needed `TESTDB_URL` set; I hunted for it twice | Record the env var this repo's tests need | project memory | project |

**Noted, not proposed:** you preferred `wallet` over `balance` in one function
name — one-off, task-specific, not a standing preference.

### Item 1 — exact edit

Your user-level instructions file, under Response Style:

```
- **Explanation-first:** Before showing code for any decision or non-trivial
  change, explain the reasoning in 6th grader vocab first — what and why — then
  attach the code. Don't lead with a code block and a one-line caption.
```

Before: the bullet stopped at "…then attach the code." The added sentence is the
part that kept getting missed.

### Item 3 — exact new file

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

Plus one bullet in the Rules index of your user-level instructions file:

```
- **`db-migrations.md`** — never run a migration unprompted; writing one is fine.
```

## What made this proposal work

- **Every row names a turn.** "Turns 12, 26, 41" is checkable; "you seemed to
  prefer" is not.
- **Item 1 edits a line instead of adding one.** The rule already existed — the
  gap was that it stopped one sentence too early.
- **Item 3 got a rule, item 2 got a memory fragment.** "Never do X" is policy;
  "greps lie in this specific way" is knowledge that may evolve.
- **Item 5 went to project-private memory, not a user-level fragment.** It's true of one repo.
- **The dropped item is still reported.** One line, so the user can overrule.

## An "already covered" row

When the config already says it, don't propose — show it:

> **Not proposed** — you asked me twice not to commit unprompted. That's already
> `rules/git-commit.md`: *"Do not run `git commit` (any form) unless the user
> explicitly asks for a commit in the same turn."* The gap was me following it,
> not the rule's wording. No config change would have prevented it.
