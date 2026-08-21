# Big-PR mode — chunked review

For PRs too large to hold in one pass. Everything in `SKILL.md` still applies (the gates, the
correctness → maintainability → performance hierarchy, the batched posting). This file adds the
machinery for reviewing a large diff without losing the thread.

## When to switch to this mode

Any one of these:
- The diff spans more than ~10 files or ~800 changed lines.
- A single `gh pr view` or `gh pr diff` call returns output too large to read
  (the harness saves it to a file and warns) — see the pivot below.
- The change crosses subsystems (shared infra + several consumers).

Tell the user you're switching to chunked mode and roughly how you'll carve the PR up.

## Pivot: stop pulling big diffs through gh

When `gh pr view` or `gh pr diff` output overflows, don't fight it — you already have the PR
checked out locally (Step 1). Work from the clone:

```
git diff --name-only <base>...<head>     # file list
git diff <base>...<head> -- <paths>      # per-chunk diff
```

Read the changed files **locally and in full** (the skill reviews whole files, not just hunks).
Use `gh` only for PR/issue metadata and, at the end, for posting. If the PR body itself overflows,
fetch it with `gh pr view <n> --json body --jq '.body'` or read the saved overflow file the harness wrote.

## Carve the PR into chunks

Group changed files into **coherent review units**, not arbitrary slices. Good seams:
- **By subsystem / module** — one domain module, one infra package, one wiring layer.
- **By blast radius** — review **shared infrastructure first** (interfaces, base libraries,
  anything many callers depend on), then the feature logic, then the wiring/config that ties it
  together. A break in shared infra invalidates everything downstream, so find it early.

Create one tracked task per chunk (`TaskCreate`) so progress survives a long review and any
context compaction. A typical carve:

| Chunk | Rationale |
|-------|-----------|
| Shared infra (interfaces, base libs) | highest blast radius — review first |
| Core feature logic (domain/app) | the actual behavior |
| Repository / persistence | query correctness, tenant scoping |
| Wiring / config / serve | feature-flagging, DI, interceptor order |

## Per-chunk loop

For each chunk, in order, write the result straight into the review file (don't hold it all in
chat — big reviews scroll away and risk compaction). Each chunk gets:

- **Files reviewed:** explicit list (the reader needs to know the boundary).
- **What changed:** 2–4 lines.
- **Correctness / maintainability / performance:** what you verified holds, not just what's
  broken — state the invariants you checked so a re-reviewer can trust them.
- **Findings:** each with a **`path:line` or `path:start-end`** anchor so another engineer jumps
  straight to it. Severity-tag every one.

Mark the task done and move to the next chunk. Resolve cross-chunk interactions explicitly (e.g.
a balancer default in the infra chunk is only safe because the publisher overrides it in the
feature chunk — say so, with both refs).

## Spec / ADR conformance

When a feature spec, design doc, or ADR governs the change (found in Step 2, or ask the user —
it's often in a *separate* docs repo), make conformance a first-class artifact:

1. Build a table: **requirement → impl `path:line` → ✓ / ✗ / partial**. Cover the wire contract,
   invariants, and any MUST/SHOULD clauses.
2. **Verify named anchors still exist** — a doc that names a file, function, flag, or field is a
   claim about a past state; confirm it against the checked-out code before trusting it.
3. **Re-assess severity against the doc.** This cuts both ways and is the highest-value step:
   - A documented backstop or accepted limitation can **downgrade** a finding (e.g. a consumer
     TTL recheck means a dropped event is delayed revocation, not permanent staleness → a
     "blocker" becomes a should-change).
   - A violated MUST can **upgrade** a nit to a blocker.
   - Separate **"merge blocker"** from **"blocker to enabling in prod"** when the feature is
     behind a flag — say which one you mean.

Be honest in the re-rank: when nothing survives as a blocker, say "no blockers" plainly.

## Cross-repo consumer check

When a PR **removes, renames, or moves an interface** — an HTTP route, a port, a proto field,
an env var, a config key — the things that break usually live in another repo. Find them before
ranking severity: it is the difference between a nit and an outage.

1. **Name the interface, then grep the consuming repos for it.** Deployment charts, sibling
   services, client SDKs. For charts specifically: probe paths, container ports, Service
   `targetPort`, and any per-service config template the chart hands the app.
2. **Work out which side wins.** A default baked into the app's own template is dead where the
   deployer overrides it and live where it doesn't. That one fact can flip a finding between
   "inert in prod" and "full outage" — establish it before you write a severity.
3. **A manifest inside the app repo is not proof of deployment.** Scaffolding like
   `config/manager/manager.yaml` often sits next to the real chart in another repo. Check which
   one the cluster reads before crediting a PR for updating it — or faulting it for not.
4. **Ask whether a paired PR exists.** If it does, review both and state the merge order in the
   verdict. If it doesn't, that absence *is* the finding.

## Optional: multi-agent fan-out (independent second opinion)

For big or high-risk PRs, after your own chunked pass, you *may* run the repo's `/code-review`
finder angles as **parallel subagents** over the diff (line-by-line, removed-behavior,
cross-file tracer, reuse, simplification, efficiency, altitude). Treat it as a recall booster and
false-positive stress test — **not** the primary review.

**Hard rule — every candidate passes a verify gate before it reaches the report.** The fan-out
produces *convincing* false positives: in practice it has flagged a non-existent "missed
invalidation" because it trusted a misleadingly-named variable, and a phantom cross-tenant bug
from an unchecked RLS assumption. For each scary candidate, go read the actual code and confirm
or refute it yourself (quote the line that settles it). Only confirmed/plausible findings ship.

Caveats to weigh before spawning:
- It's token-heavy (each angle re-derives context you already hold). Don't reach for it on a
  small PR, and don't spawn agents unless the user is on board.
- It mostly **corroborates** a careful manual pass; the unique new findings tend to be nits.
- Record refuted candidates too — "verified X is *not* a bug, because <line>" is valuable and
  stops the same false alarm next time.

## Posting big-PR findings

Same batched flow as `SKILL.md` Step 6, and the shape rules in [TEMPLATE.md](TEMPLATE.md) →
*Posting keeps this exact shape* apply in full: each inline comment is the **whole finding**
generated from the saved report, led by `**<ID> · <Severity> · <tags>**`. A big finding set is
the case where hand-writing the payload breaks down — script the split, and assert every ID
resolved before posting.

**Prune, don't shorten.** The user may ask to post only blockers + should-fix and skip nits —
honor that by dropping whole findings, never by trimming the survivors. Keep the dropped ones in
the saved review file as a compact table so nothing is lost, and fold any content a surviving
finding referenced into that finding so no comment points at an ID the author cannot see.

Anchor each comment at its `path:line` on the RIGHT side of the diff (new files: every line is
addable). **Validate every anchor against the PR's diff hunks before building the payload** —
one bad `path` or out-of-hunk `line` rejects the entire review. When a finding is about an
unchanged file, anchor it to the changed line that *causes* the problem and name the real
`file:line` in the body.
