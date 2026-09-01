# Worked example: the proposal shape

This is one real-shaped run of [SKILL.md](SKILL.md) on `feat-812/webhook-retries`. The branch is a
Go service branch, 1,412 lines across 19 files, forked from `main`. Phase 3 must reach this
density. A reviewer should be able to say yes or no to it. The reviewer should not have to open the
diff.

---

## Phase 1 output: what I learned

- **I found a plan:** `.agents/scratch/plans/2026-03-04-webhook-retries.md`, plus issue #812. The
  goal is at-least-once webhook delivery with exponential backoff, capped at 5 attempts.
- **The plan puts two items out of scope on purpose:** a dead-letter queue, and the admin UI that
  replays failures. Both are follow-ups, so nothing on this branch should reference them.
- **The branch changed direction once in the middle.** Commit `a3f19c2` moved retry state from an
  in-memory map to a `webhook_attempts` table. Later commits therefore partly undo the earlier
  commits on `dispatcher.go`. The history is tangled. A cherry-pick of whole commits will not work
  for the core.

## Phase 3 output: the proposed split

### The PRs

| # | Branch | Base | Title | Files | ~Lines | What the reviewer checks |
|---|--------|------|-------|-------|--------|--------------------------|
| 1 | `feat-812/webhook-retries--extract-client` | `main` | `refactor: extract webhookClient from dispatcher` | `dispatcher.go`, `client.go` (new), `dispatcher_test.go` | ~180 | A pure move, with no behaviour change. Confirm the extracted methods are byte-identical to the inlined code. |
| 2 | `feat-812/webhook-retries--schema` | PR 1 | `feat: add webhook_attempts table` | `migrations/0042_*.sql`, `store/schema.go` | ~120 | Indexes and nullability only. Is `(webhook_id, attempt_no)` unique, and is the migration reversible? |
| 3 | `feat-812/webhook-retries--backoff` | PR 2 | `feat: add exponential backoff calculator` | `retry/backoff.go`, `retry/backoff_test.go` | ~210 | Table-driven tests on the jitter bounds and the 5-attempt cap. Nothing references this code yet. |
| 4 | `feat-812/webhook-retries--dispatch` | PR 3 | `feat: retry failed deliveries via attempt log` | `dispatcher.go`, `store/attempts.go`, `dispatcher_test.go`, `store/attempts_test.go` | ~390 | The real logic. Does a crash between send and log-write double-send? The flag is off, so this is dead code in production. |
| 5 | `feat-812/webhook-retries--wiring` | PR 4 | `feat: wire retry worker into the scheduler` | `cmd/worker/main.go`, `config.go`, `config_test.go` | ~150 | Startup order and the config default. The worker starts, but the flag blocks its work. |
| 6 | `feat-812/webhook-retries--enable` | PR 5 | `feat: enable webhook retries by default` | `config.go`, `docs/webhooks.md` | ~30 | A one-line change of the default, plus docs. This is the only PR that changes what users see. |

### The stack

```
main
 └── 1  extract-client      refactor only, safe to merge alone
      └── 2  schema         additive migration, nothing reads it yet
           └── 3  backoff    pure function + tests, called by nobody
                └── 4  dispatch     core logic, behind WEBHOOK_RETRIES=off
                     └── 5  wiring   worker registered, gated by the flag
                          └── 6  enable   flips the default to on
```

### The split method for each PR, and why

- **PRs 1, 2, and 3 use a cherry-pick.** Commits `7c1a08e`, `d40b2f1`, and `9ee4c37..b1207aa` are
  already clean single-layer commits. A cherry-pick keeps their messages. It also makes a later
  `--update-refs` restack easy.
- **PR 4 copies files.** `a3f19c2` reversed the earlier in-memory approach. A replay of those
  commits would land code that the branch later deleted. Copy `dispatcher.go` and
  `store/attempts.go` from the original branch at their final state instead.
- **PRs 5 and 6 copy files.** Three separate commits across the branch touch `config.go`. To take
  its end state is simpler than to pick three commits and resolve conflicts.

### Files that need a hunk-level split

- **`config.go`** has three separate blocks:
  - the `WebhookRetries` struct field and its env binding → **PR 5**
  - the `MaxAttempts` / `BaseDelay` tuning fields → **PR 5**
  - the `Default: true` on the flag → **PR 6** (this hunk *is* PR 6)
- **`dispatcher.go`** holds two blocks. The `webhookClient` extraction (lines ~40 to 120 on the
  original) goes to **PR 1**. The retry loop and the attempt-log calls around it go to **PR 4**.
  These blocks do not overlap line-for-line, so `git add -p` handles them.
- **`docs/webhooks.md`** holds a "Retries" section that describes the feature as live. It goes to
  **PR 6**, not to PR 4 where the code lands.

### Deletions

The original branch deletes `store/memretry.go` (154 lines). It holds the in-memory state that
`a3f19c2` replaced. It gets an explicit `git rm` on **PR 4**, the rung that adds its replacement.
An earlier deletion breaks the build on PRs 1 to 3.

### Why each PR is safe to merge alone

The `WEBHOOK_RETRIES` feature flag stays **off** through PR 5. PR 6 turns it **on**. PRs 2 and 3
need no flag. A table that nothing reads and a function that nothing calls are both inert. The
dispatcher in PR 4 checks the flag before it writes to the attempt log. A merge of PR 4 therefore
changes nothing in production.

### Open questions

1. **`store/attempts.go` line 88** re-reads the webhook row inside the retry loop. The plan and the
   commits do not tell me the reason for it. It is either a deliberate freshness check or a
   leftover from the in-memory version. The answer changes whether PR 4 needs the row-lock hunk.
   Which is it?
2. **PR 4 is ~390 lines**, at the top of the target range. It could split into "attempt log store"
   and "dispatcher uses it". The dispatcher tests cover both parts, so I would have to separate the
   tests. I lean toward one whole PR. Your call.
3. **The migration in PR 2 has no down-migration** on the original branch. Do you want me to add
   one as part of PR 2, or is forward-only the house rule here?

---

## Compare a too-coarse row with a right one

A proposal can read as reasonable and still give the reviewer nothing to check. That is the failure
mode. Each pair below shows the same row twice.

| | |
|---|---|
| ✗ | **Reviewer summary:** "Database changes." |
| ✓ | **Reviewer summary:** "Indexes and nullability only. Is `(webhook_id, attempt_no)` unique, and is the migration reversible?" |
| ✗ | **Method:** "Copy the files over." |
| ✓ | **Method:** "Copy files — `a3f19c2` reversed the earlier in-memory approach, so replaying those commits would land code the branch later deleted." |
| ✗ | **Hunk split:** "`config.go` is shared between PRs." |
| ✓ | **Hunk split:** "`config.go` — struct field + env binding → PR 5; `Default: true` → PR 6." |
| ✗ | **Open question:** "Some parts were unclear." |
| ✓ | **Open question:** "`store/attempts.go:88` re-reads the webhook row inside the retry loop — deliberate freshness check, or leftover? It decides whether PR 4 needs the row-lock hunk." |

An open question must name a file, a line, and the decision that it blocks. Without those three, it
is not a question. It is an apology. Ask something that the user can answer in one sentence.
