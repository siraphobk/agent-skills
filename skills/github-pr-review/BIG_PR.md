# Big-PR mode: chunked review

Use this mode for a PR too large to hold in one pass. Everything in `SKILL.md` still applies.
That includes the gates, the correctness → maintainability → performance hierarchy, and the
batched posting. This file adds the machinery that keeps a review of a large diff on track.

## When to switch to this mode

Any one of these:
- The diff spans more than ~10 files or ~800 changed lines.
- A single `gh pr view` or `gh pr diff` call returns output too large to read. The harness saves
  that output to a file and gives a warning. See the pivot below.
- The change crosses subsystems, such as shared infra plus several consumers.

Tell the user that you switch to chunked mode. Say roughly how you will carve the PR into chunks.

## Pivot: do not fetch big diffs through gh

When the `gh pr view` or `gh pr diff` output overflows, do not fight it. You already have the PR
checked out locally (Step 1). Work from the clone:

```
git diff --name-only <base>...<head>     # file list
git diff <base>...<head> -- <paths>      # per-chunk diff
```

Read the changed files **locally and in full**. This skill reviews whole files, not only hunks.
Use `gh` only for PR and issue metadata, and at the end for the post. If the PR body itself
overflows, fetch it with `gh pr view <n> --json body --jq '.body'`. You can also read the saved
overflow file that the harness wrote.

## Carve the PR into chunks

Group the changed files into **coherent review units**, not arbitrary slices. Good places to
split:
- **By subsystem or module.** One domain module, one infra package, or one wiring layer.
- **By blast radius.** Review **shared infrastructure first**. That is interfaces, base
  libraries, and anything many callers depend on. Then review the feature logic. Then review the
  wiring and config that joins them. A break in shared infra invalidates everything downstream,
  so find it early.

Create one tracked task per chunk with `TaskCreate`. Progress then survives a long review and any
context compaction. A typical carve:

| Chunk | Rationale |
|-------|-----------|
| Shared infra (interfaces, base libs) | highest blast radius, so review it first |
| Core feature logic (domain/app) | the actual behavior |
| Repository / persistence | query correctness, tenant scoping |
| Wiring / config / serve | feature-flagging, DI, interceptor order |

## Per-chunk loop

Work through the chunks in order. Write the result of each chunk directly into the review file.
Do not hold it all in chat. A big review scrolls away and risks compaction. Each chunk gets:

- **Files reviewed:** an explicit list. The reader needs to know the boundary.
- **What changed:** 2–4 lines.
- **Correctness / maintainability / performance:** what you verified as correct, not only what is
  broken. State the invariants you checked, so a re-reviewer can trust them.
- **Findings:** each finding gets a **`path:line` or `path:start-end`** anchor, so another
  engineer goes directly to it. Give every finding a severity tag.

Mark the task done. Then start the next chunk. Explain every cross-chunk interaction explicitly.
For example, the infra chunk sets a balancer default. That default is safe only because the
publisher overrides it in the feature chunk. Say so, and give both refs.

## Spec / ADR conformance

A feature spec, a design doc, or an ADR can govern the change. You find it in Step 2, or you ask
the user. It often lives in a *separate* docs repo. When such a doc governs the change, make
conformance a first-class artifact:

1. Build a table: **requirement → impl `path:line` → ✓ / ✗ / partial**. Cover the wire contract,
   the invariants, and any MUST/SHOULD clauses.
2. **Verify that named anchors still exist.** A doc that names a file, a function, a flag, or a
   field makes a claim about a past state. Confirm that claim against the checked-out code before
   you trust it.
3. **Re-assess severity against the doc.** This step works in both directions, and it has the
   highest value:
   - A documented backstop or an accepted limitation can **downgrade** a finding. For example, a
     consumer TTL recheck means a dropped event is delayed revocation, not permanent staleness.
     A "blocker" then becomes a should-change.
   - A violated MUST can **upgrade** a nit to a blocker.
   - A flag can gate the feature. Then separate **"merge blocker"** from **"blocker to enabling
     in prod"**. Say which one you mean.

Be honest in the re-rank. When nothing survives as a blocker, say "no blockers" plainly.

## Cross-repo consumer check

A PR can **remove, rename, or move an interface**. That means an HTTP route, a port, a proto
field, an env var, or a config key. The things that break then usually live in another repo. Find
them before you rank severity. It is the difference between a nit and an outage.

1. **Name the interface. Then grep the consuming repos for it.** Those are deployment charts,
   sibling services, and client SDKs. For a chart, check the probe paths, the container ports,
   and the Service `targetPort`. Also check any per-service config template the chart gives the
   app.
2. **Decide which side wins.** A default built into the template of the app itself is dead where
   the deployer overrides it. It is live where the deployer does not. That one fact can change a
   finding between "inert in prod" and "full outage". Establish it before you write a severity.
3. **A manifest inside the app repo is not proof of deployment.** Scaffolding such as
   `config/manager/manager.yaml` often sits beside the real chart in another repo. Check which
   one the cluster reads. Do that before you credit a PR for an update to it, or fault the PR for
   no update.
4. **Ask whether a paired PR exists.** If it does exist, review both PRs and state the merge
   order in the verdict. If it does not exist, that absence *is* the finding.


## How to post big-PR findings

Use the same batched flow as `SKILL.md` Step 6. The shape rules in [TEMPLATE.md](TEMPLATE.md) →
*Posting keeps this exact shape* apply in full. Each inline comment is the **whole finding**,
generated from the saved report. A `**<ID> · <Severity> · <tags>**` line leads it. A big finding
set is the case where a hand-written payload fails. Script the split, and assert that every ID
resolved before you post.

**Prune, do not shorten.** The user may ask you to post only blockers and should-fix findings,
and to skip the nits. Honor that request. Drop whole findings, and never trim the survivors. Keep
the dropped findings in the saved review file as a compact table, so nothing is lost. A surviving
finding may reference dropped content. Copy that content into the surviving finding, because no
comment may point at an ID the author cannot see.

Anchor each comment at its `path:line` on the RIGHT side of the diff. In a new file, every line
is addable. **Validate every anchor against the diff hunks of the PR before you build the
payload.** One bad `path` or one out-of-hunk `line` rejects the entire review. When a finding is
about an unchanged file, anchor it to the changed line that *causes* the problem. Name the real
`file:line` in the body.
