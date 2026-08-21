# Worked example — the proposal shape

One real-shaped run of [SKILL.md](SKILL.md) on `feat-812/webhook-retries`: a Go service branch,
1,412 lines across 19 files, forked from `main`. This is the density Phase 3 has to hit — a
reviewer should be able to say yes or no to it without opening the diff themselves.

---

## Phase 1 output — what I learned

- **Plan found:** `.agents/scratch/plans/2026-03-04-webhook-retries.md`, plus issue #812. The goal
  is at-least-once webhook delivery with exponential backoff, capped at 5 attempts.
- **Deliberately out of scope**, per the plan: a dead-letter queue and the admin UI for replaying
  failures. Both are follow-ups, so nothing on this branch should reference them.
- **One mid-branch change of direction:** commit `a3f19c2` moved retry state from an in-memory map
  to a `webhook_attempts` table, so the earlier commits touching `dispatcher.go` are partly undone
  by later ones. History is tangled — cherry-picking whole commits will not work for the core.

## Phase 3 output — the proposed split

### The PRs

| # | Branch | Base | Title | Files | ~Lines | What the reviewer checks |
|---|--------|------|-------|-------|--------|--------------------------|
| 1 | `feat-812/webhook-retries--extract-client` | `main` | `refactor: extract webhookClient from dispatcher` | `dispatcher.go`, `client.go` (new), `dispatcher_test.go` | ~180 | Pure move — no behaviour change. Confirm the extracted methods are byte-identical to what was inlined. |
| 2 | `feat-812/webhook-retries--schema` | PR 1 | `feat: add webhook_attempts table` | `migrations/0042_*.sql`, `store/schema.go` | ~120 | Indexes and nullability only. Is `(webhook_id, attempt_no)` unique, and is the migration reversible? |
| 3 | `feat-812/webhook-retries--backoff` | PR 2 | `feat: add exponential backoff calculator` | `retry/backoff.go`, `retry/backoff_test.go` | ~210 | Table-driven tests on the jitter bounds and the 5-attempt cap. Unreferenced by anything yet. |
| 4 | `feat-812/webhook-retries--dispatch` | PR 3 | `feat: retry failed deliveries via attempt log` | `dispatcher.go`, `store/attempts.go`, `dispatcher_test.go`, `store/attempts_test.go` | ~390 | The real logic. Does a crash between send and log-write double-send? Flag is off, so this is dead code in production. |
| 5 | `feat-812/webhook-retries--wiring` | PR 4 | `feat: wire retry worker into the scheduler` | `cmd/worker/main.go`, `config.go`, `config_test.go` | ~150 | Startup ordering and the config default. Worker starts but the flag gates its work. |
| 6 | `feat-812/webhook-retries--enable` | PR 5 | `feat: enable webhook retries by default` | `config.go`, `docs/webhooks.md` | ~30 | One-line default flip plus docs. The only PR that changes what users see. |

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

### Method per PR, and why

- **PRs 1, 2, 3 — cherry-pick.** Commits `7c1a08e`, `d40b2f1`, and `9ee4c37..b1207aa` are already
  clean single-layer commits. Cherry-picking keeps their messages and makes a later
  `--update-refs` restack painless.
- **PR 4 — copy files.** `a3f19c2` reversed the earlier in-memory approach, so replaying those
  commits would land code the branch later deleted. Copy `dispatcher.go` and `store/attempts.go` at
  their final state from the original branch instead.
- **PRs 5, 6 — copy files.** `config.go` is touched by three separate commits scattered through the
  branch; taking its end state is simpler than picking three commits and resolving conflicts.

### Files that need a hunk-level split

- **`config.go`** — three separate blocks:
  - the `WebhookRetries` struct field and its env binding → **PR 5**
  - the `MaxAttempts` / `BaseDelay` tuning fields → **PR 5**
  - the `Default: true` on the flag → **PR 6** (this hunk *is* PR 6)
- **`dispatcher.go`** — the `webhookClient` extraction (lines ~40–120 on the original) goes to
  **PR 1**; the retry loop and attempt-log calls added around it go to **PR 4**. These do not
  overlap line-for-line, so `git add -p` handles it.
- **`docs/webhooks.md`** — the "Retries" section describes the feature as live, so it goes to
  **PR 6**, not to PR 4 where the code lands.

### Deletions

`store/memretry.go` (154 lines) is deleted on the original branch — the in-memory state that
`a3f19c2` replaced. It gets an explicit `git rm` on **PR 4**, the rung that introduces its
replacement. Deleting it earlier breaks the build on PRs 1–3.

### Why each PR is safe to merge alone

`WEBHOOK_RETRIES` feature flag, default **off** through PR 5, flipped to **on** in PR 6. PRs 2 and
3 need no flag — a table nothing reads and a function nothing calls are inert. PR 4's dispatcher
checks the flag before touching the attempt log, so merging it changes nothing in production.

### Open questions

1. **`store/attempts.go` line 88** re-reads the webhook row inside the retry loop. I cannot tell
   from the plan or the commits whether that is a deliberate freshness check or a leftover from the
   in-memory version. It changes whether PR 4 needs the row-lock hunk. Which is it?
2. **PR 4 is ~390 lines**, at the top of the target range. It could split into "attempt log store"
   and "dispatcher uses it", but the dispatcher tests cover both and I would have to break them
   apart. I lean toward leaving it whole. Your call.
3. **The migration in PR 2 has no down-migration** on the original branch. Do you want me to add
   one as part of PR 2, or is forward-only the house rule here?

---

## Too coarse vs. right

The failure mode is a proposal that reads as reasonable but tells the reviewer nothing they can
check. Each pair below is the same row.

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

An open question that does not name a file, a line, and the decision it blocks is not a question —
it is an apology. Ask something the user can answer in one sentence.
