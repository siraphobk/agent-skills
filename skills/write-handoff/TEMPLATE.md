# write-handoff template

This is the skeleton that the skill drafts from. Complete each section.
**Omit each section that would be empty.** Do not keep a heading only to write
"none". Every entry is a reference, not a dump. Use `path:line`,
`[[memory-slug]]`, links, and skill names.

````md
# Handoff: <task in a few words>

- **Project:** <repo root path> @ <branch>
- **Created:** <YYYY-MM-DD HH:MM>
- **Status:** <one line — where things stand right now>

## Task

One or two sentences: the goal and what "done" looks like. Enough for a cold
agent to know what it's picking up and why.

## Done

- <completed step> — landed in `path/to/file.go:42`

## In progress

- <current step and its exact state — what's half-written, what's untested> —
  `path/to/file.go:88`

## Next

- <next concrete action, specific enough to start without asking questions>

## Useful files

- `path/to/file.ts:120` — <why the next agent will need it>

## Memories & links

- `[[memory-slug]]` — <what it covers>
- <url / issue #N / PR #N> — <why it's relevant>

## Suggested skills

- `skill-name` — <when and why to use it for this job>

## Open questions / blockers

- <unresolved decision, blocker, or assumption the next agent should verify>
````

## Worked example (calibration)

````md
# Handoff: rate-limit middleware for the orders API

- **Project:** /home/me/work/orders-svc @ feat-204/rate-limit
- **Created:** 2026-06-24 14:30
- **Status:** middleware written and wired; tests written but 2 failing on the burst case

## Task

Add a token-bucket rate limiter to the orders API, keyed per API key, backed by
Redis. Done = limiter enforces 100 req/min/key with a 20-req burst, all tests green.

## Done

- Token-bucket logic — `internal/ratelimit/bucket.go:1`
- Redis-backed store — `internal/ratelimit/store.go:30`
- Middleware wired into the router — `cmd/api/router.go:55`

## In progress

- Table tests for burst behavior — `internal/ratelimit/bucket_test.go:140`; the
  two burst cases fail because the refill clock uses wall time, not the injected
  clock. Needs the test clock threaded through `bucket.go:60`.

## Next

- Thread the injectable clock into refill, then re-run `go test ./internal/ratelimit/...`
- If green, run the API integration suite before opening the PR

## Useful files

- `internal/ratelimit/bucket.go:60` — refill path that ignores the test clock
- `internal/middleware/auth.go:24` — where the API key is resolved, reused as the limiter key

## Memories & links

- `[[redis-conn-pool-sizing]]` — pool config the store assumes
- PR #204, issue #198 — the feature request and acceptance criteria

## Suggested skills

- `diagnose` — for the failing burst tests if the clock fix doesn't resolve them
- `github-pr-create` — once tests pass, to open the PR from this branch

## Open questions / blockers

- Should the limiter fail open or closed when Redis is down? Not decided — current code fails open.
````
