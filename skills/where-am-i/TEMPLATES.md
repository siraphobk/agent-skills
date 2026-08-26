# Output shapes

Both levels open the same way: one header line you can read at a glance, then
the three-sentence summary, then fields. The header exists so a person scanning
three terminal tabs can tell them apart without reading further.

## brief

````
**dc-commerce** · `bug-482/stock-oversell` · fritz-desktop

Tracking down why two orders can both claim the last unit of stock. Reproduced
it with a test that fires two checkouts at the same row, and the culprit looks
like the reservation read happening outside the transaction. Next is to move
that read inside and see if the test goes green.

- **where** — linked worktree `.worktrees/bug-482--stock-oversell`, 1 ahead of `origin/main`, 4 files dirty
- **machine** — fritz-desktop, Ubuntu 24.04 (Linux 6.8.0)
- **agent** — context 62% used
- **quota** — 5h: 41% (resets in 2h10m) · week: 68% (resets Sunday)

→ Next: move the reservation read inside the transaction in `internal/order/reserve.go:88`, then rerun `go test ./internal/order/...`
````

Drop a field whose value is unavailable — except quota, which prints
`unknown — run /usage`. Only flag the worktree when this checkout is a linked
one; in a plain clone the `where` line just names the branch.

## full

Same header, same summary, then the same fields expanded, with three sections
added underneath.

````
**dc-commerce** · `bug-482/stock-oversell` · fritz-desktop

Tracking down why two orders can both claim the last unit of stock. Reproduced
it with a test that fires two checkouts at the same row, and the culprit looks
like the reservation read happening outside the transaction. Next is to move
that read inside and see if the test goes green.

**where**
- repo `/home/fritz/work/dc-commerce`, linked worktree `.worktrees/bug-482--stock-oversell`
- branch `bug-482/stock-oversell`, 1 ahead / 0 behind `origin/main`
- dirty: `internal/order/reserve.go`, `internal/order/reserve_test.go`, 2 untracked under `testdata/`
- 1 stash · last commit `a91c2f4 test: reproduce double-claim on last unit (18m ago)`

**machine**
- fritz-desktop · Ubuntu 24.04 · Linux 6.8.0 · up 3 days
- user `fritz`, cwd is the worktree root

**agent**
- context 62% used · model claude-opus-5 · session `7c5b99d1`
- quota — 5h: 41% (resets in 2h10m) · week: 68% (resets Sunday)

**other checkouts with work in them**
| Path | Branch | State |
|---|---|---|
| `../dc-commerce/.worktrees/enh-70--semi-joins` | `enh-70/semi_joins` | 7 dirty |
| `../repo-core` | `main` | 2 dirty, 3 ahead |
| `../rust-scratch` | detached at `a3f19c2` | 4 dirty |

**recent artifacts**
- `.agents/scratch/plans/2026-08-24-stock-reservation.md` (2 days ago)
- handoff written 4 hours ago in the out-of-repo handoff directory

→ Next: move the reservation read inside the transaction in `internal/order/reserve.go:88`, then rerun `go test ./internal/order/...`
````

The neighbour table only lists checkouts that are dirty or ahead. A clean one is
not a session anybody left open, and listing it hides the three that are. A row
with no branch says `detached at <short commit>` and carries no ahead/behind —
writing `HEAD` there reads as a branch by that name.

## The summary — too vague vs. right

The three sentences carry the whole report. Each one has a job: **what the task
is**, **where it stands**, **what is next or blocked**. A summary that could
describe any session on any day has failed, even though it is short and true.

**Too vague:**

> Working on a bug in the order service. Made some progress investigating the
> issue. Will continue looking into it.

Nothing here survives a tab switch — no symptom, no finding, no next action. The
reader still has to scroll the session to learn anything.

**Right:**

> Tracking down why two orders can both claim the last unit of stock. Reproduced
> it with a test that fires two checkouts at the same row, and the culprit looks
> like the reservation read happening outside the transaction. Next is to move
> that read inside and see if the test goes green.

Same length. Names the symptom, the state of the evidence, and the exact next
move — which is what makes it worth reading at all.

**When the session has no work yet,** say so in one sentence and stop. Do not
stretch a cold start into three:

> Fresh session, nothing done yet — the checkout is clean and on `main`.
