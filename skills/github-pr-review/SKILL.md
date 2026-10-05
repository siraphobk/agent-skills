---
name: github-pr-review
allowed-tools: Read Write Grep Glob Task WebFetch Bash(gh *) Bash(git *) Bash(mkdir *)
description: Reviews a GitHub Pull Request with the user. Collects related documentation, issues, and discussions before an understanding gate, then checks correctness, maintainability, performance, and verification evidence. Standard mode delivers severity-ranked findings. Guided mode builds a concept map and explains one concept per turn through its objective, implementation, verification, and assessment. Large PRs use coherent review chunks. Use for "review this PR", "review PR <n>", "walk me through this PR", or "help me understand this PR". NOT for pre-implementation analysis (use analyze-issue) or general code-smell searches (use find-smells).
argument-hint: "[PR number or URL] [standard|guided]"
---

# GitHub PR Review

Review the PR with the user. Stop at every gate until the user gives explicit approval.

`standard` is the default. Select `guided` when the user asks for a walkthrough or help to understand the PR.
An explicit style takes precedence over phrasing. Read [GUIDED.md](GUIDED.md) before Step 2 in guided mode.
Review style does not change checkout modes, review scope, severity rules, or posting approval.

Use `gh` for GitHub metadata and `git` for checkout mechanics. Read local files and use `WebFetch` for linked documentation.

Get the PR first. Ask for a number or URL only if missing. Find `owner`/`repo` with `git remote get-url origin`.

## Step 0: Find the repo

The PR `owner/repo` **must match** the `origin` of the current clone. **Stop** and tell the user
if it does not match. Stop also if you are not in a git repo. Never review a different repo in
silence.

Use the **read-only fallback (mode C)** only when the user cannot clone the repo, or refuses to.
In that mode you review directly from `gh pr diff` and `gh pr view`:
- Mode C has no checkout, no local code, no doc search, and no full file reads.
- Tell the user plainly that a diff-only review is shallower.

## Step 1: Checkout

Ask the user for **current dir** or **worktree**. See [CHECKOUT.md](CHECKOUT.md) for the exact
steps. That file covers the dirty tree, when to stash, worktree setup and teardown, how to
restore, and the fallback. Follow it. Do not invent your own git commands. Every later step runs
against the checked-out PR code.

## Step 2: Collect project docs

Gather context before detailed review. Use repository instructions already supplied by the host.
In mode C, skip documentation discovery and report unavailable context at the Ready gate.
- Use `gh pr diff {number} --name-only` to locate affected directories, not to read implementation hunks.
- List document names in affected directories, their parents, and root documentation. Read relevant sections, not unrelated documentation.
- Find feature specifications, architecture decisions, API contracts, domain rules, service guides, and operational documentation.
- Follow relevant references from documents and PR metadata, including accessible external documentation and related repositories.
- Record source paths or URLs, requirement references, conflicts, and access limits. Do not assume documentation matches the implementation.
- Gather available context before asking the user. Ask only when an inaccessible gap prevents a sound review.

Context is sufficient when objectives, expected behavior, constraints, non-goals, and verification criteria are clear.
Record remaining gaps at the Ready gate. Never invent requirements to complete the brief.

## Step 3: Understand the PR

- Read the PR: `gh pr view {number} --json number,title,body,state,author,headRefName,baseRefName,headRefOid`
- Read every linked or mentioned issue: `gh issue view {issue_number} --json number,title,body,comments`. Note the acceptance criteria of each issue.
- Read existing inline comments and reviews with `gh api repos/{owner}/{repo}/pulls/{number}/comments` and `.../reviews`.
  Account for existing discussion. Reply in an existing thread for the same topic, subject to posting approval.
  Identify incorrect comments and questions addressed to you before preparing findings.
- Read related issue discussions and linked design decisions. Separate documented requirements, PR claims, and inferred intent.
- Summarize the claimed objective and testable criteria. Identify important failure behavior and evidence needed to verify each criterion.

## Step 4: Ready gate (understanding brief)

Show a short brief. Then **wait for the user to say go clearly**:

| Section | What to show |
|---|---|
| **Intent** | Objective, expected behavior, constraints, and non-goals, with sources. |
| **Acceptance criteria** | Testable requirements and important failure behavior. Label inferred criteria. |
| **Docs consulted** | Source paths or URLs and relevant requirement references. |
| **Planned scope** | Files to read, skim, or skip as generated. For large PRs, show coherent chunks. |
| **Concepts** | In guided mode, a provisional concept map, dependencies, and walkthrough order. |
| **Verification** | Evidence needed for each objective, including runtime scenarios where relevant. |
| **Conformance** | Governing specification or architecture decision, when one applies. |
| **Open questions** | Conflicting sources, access limits, and gaps. Identify which gaps block judgment. |

In guided mode, derive the provisional map from context and file names. Confirm it against implementation after approval.
Stop for blocking context gaps. Proceed with non-blocking gaps only after the user accepts the stated limits.

Do not read the diff until the user says go.

## Step 5: Review

Sort the files first, to spend tokens well. Get the file list with `gh pr diff {number}
--name-only`. Rank the files by review value: domain/app logic > controllers > tests > config.
- **Always read domain/app logic in full.**
- **Always skip generated code.** That is gqlgen `graph/`, `*.pb.go`, `pkg/` codegen, lock files,
  and vendored files. Say that it changed, but do not review it.
- If the PR is still too big, show the ranked list and suggest a scope. Never remove files from
  the scope in silence.
- For files you read deeply, read the **whole file**, not only the unified diff.

In guided mode, follow the concept loop in [GUIDED.md](GUIDED.md). Explain one concept, then wait for explicit continuation.
Keep the value hierarchy below. A walkthrough changes explanation and pacing, not review rigor.

**Big PRs use chunks.** Apply [BIG_PR.md](BIG_PR.md) above about 10 files, 800 changed lines, or across subsystems.
Group files by purpose and dependencies. Guided mode uses concept checkpoints within those chunks.

Rank every finding by this **value hierarchy**. A lower tier never beats a higher tier.

1. **Correctness** is the hard line. It covers logic bugs, error and nil handling, races, edge
   cases, broken domain invariants, and unmet acceptance criteria. **Test coverage belongs here:**
   - Does branching or domain logic have tests?
   - Does a bug-fix PR add a regression test?
   - A missing regression test is usually 🟡 Should-fix. It is 🔴 Blocker when the code is
     invariant-heavy or domain logic.
   - Glue or wiring code without tests is fine. Do not complain about it.
2. **Maintainability** means the next person understands the code easily. Check naming, layering,
   coupling, readable flow, and the style of the repo. Layering means you keep business logic out
   of resolvers and controllers (see the repo `AGENTS.md`).
3. **Performance** matters only after the two tiers above hold. Search for real problems: N+1 and
   dataloaders, hot-path allocations, and bad query patterns. **If the PR does not list perf as a
   goal, do not exaggerate small optimizations.** Grade them as a Nit at most, never as a Blocker.

**Security** is a separate concern: authz (OpenFGA), input validation, injection. Treat a
security problem as a correctness and safety bug. Grade it 🔴 Blocker wherever it sits in the
hierarchy.

**Migration changes require a full review.** Migration files are `migrations/`, `*.sql`, and Go
or Rust files that change the schema. If the diff touches one, report it at the Ready gate and
review it against these five headings: lock acquisition on large tables, deployment order,
rollback viability, data-loss risk, and index strategy. Never accept one after a skim only.

## Step 6: Deliver findings

Use [TEMPLATE.md](TEMPLATE.md). The default is **chat first**. Show the report with each finding
and its `file:line`. Then **review the findings with the user one by one**. The user accepts or
drops each finding before anything leaves the session.
In guided mode, include the objective assessment from [TEMPLATE.md](TEMPLATE.md). Distinguish observed evidence from unverified claims.

**How to save:** chat only by default. Offer to write `.agents/scratch/reviews/pr-<number>.md`
when the user asks. In worktree mode, **offer to save without a request from the user**. Chat can
scroll away.

**Post to GitHub** only when the user says go clearly. Post one **batched review**:
1. Show the full set of comments in chat first. Then get the go.
2. **Check that every anchor is in the diff.** GitHub rejects an inline comment when its `path` is
   not one of the changed files of the PR. GitHub also rejects it when its `line` is outside a
   diff hunk. So verify each anchor against `gh api repos/{owner}/{repo}/pulls/{number}/files`
   *before* you build the payload. When a finding is about an unchanged file, anchor it to the
   changed line that **causes or claims** the problem. Name the real `file:line` in the body. If
   no such changed line exists, move the finding into the review body instead.
3. **Build and post the review in one call.** See [TEMPLATE.md](TEMPLATE.md) → *Posting keeps
   this exact shape*. It holds the `gh api` payload shape and the head-SHA lookup. It also holds
   the `side` and `event` fields, and the separate reply and edit calls. Build the payload with a
   script that splits the saved report on its `#### <ID>` headers. Hand-written JSON does not
   scale past a few findings.

**Never use `APPROVE` on your own.** That click belongs to the user. `COMMENT` is the default
event. Use `REQUEST_CHANGES` only when there is at least 1 Blocker **and** the user agrees.
