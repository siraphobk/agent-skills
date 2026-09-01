---
name: github-pr-review
allowed-tools: Read Write Grep Glob Task Bash(gh *) Bash(git *) Bash(mkdir *)
description: Deep, step-by-step code review of a GitHub Pull Request. Checks out the PR (current dir or a worktree under .worktrees/), collects project docs and PR/issue context, shows an understanding brief, then reviews in a correctness → maintainability → performance order and gives findings graded by severity. Large PRs switch to a chunked, blast-radius-ordered mode with per-chunk findings and optional spec/ADR conformance checking. Use when the user invokes this skill directly or says "let's review a PR on github", "review this PR", "do a code review on PR <n>", or similar intent to review a GitHub pull request.
---

# GitHub PR Review

You run this deep, step-by-step PR review together with the user. **Stop at every gate. Never
continue until the user says go.**

- Use **`gh`** to read the PR body, the issues, the diff, and the files. The commands are
  `gh pr view`, `gh issue view`, and `gh pr diff`.
- Use **`git`** for local code work. That covers the checkout, the diffs, and the file reads.

Get the PR first. If the user did not give a number or a URL, ask for one. Find `owner`/`repo`
with `git remote get-url origin`.

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

Search near the PR, not the whole monorepo:
- Use `gh pr diff {number} --name-only` to find the directories the PR changes.
- For each changed dir, search inside it. Then search each parent dir **up to the repo root**.
  Search for `*.md`, `README*`, `docs/`, `ADR*`, `CONTEXT.md`, and service `README` files. Always
  include the repo-root docs `AGENTS.md`, `CLAUDE.md`, and top-level `docs/`.
- List the **names only** first. Discard the names that do not matter. Then read **only** the few
  files that look useful.
- Then **ask the user** for any related docs the search would miss. A governing **feature spec or
  ADR often lives in a separate docs repo**. The file search cannot reach that repo. If such a doc
  governs this change, plan a conformance check (see [BIG_PR.md](BIG_PR.md) → Spec / ADR
  conformance).

## Step 3: Understand the PR

- Read the PR: `gh pr view {number} --json number,title,body,state,author,headRefName,baseRefName,headRefOid`
- Read every linked or mentioned issue: `gh issue view {issue_number} --json number,title,body,comments`. Note the acceptance criteria of each issue.
- **Read the review already on the PR before you write your own:**
  `gh api repos/{owner}/{repo}/pulls/{number}/comments` and `.../reviews`. Existing comments
  change what you write. **Reply in an existing thread** when your finding lands on the same line
  or the same topic. Do not open a new thread there. Say plainly when an existing comment is
  wrong. A question addressed to you there is a reply you owe, whatever your findings are.
- Summarize what the PR **says** it does. Add the **testable criteria** the PR must meet.

## Step 4: Ready gate (understanding brief)

Show a short brief. Then **wait for the user to say go clearly**:

| Section | What to show |
|---|---|
| **Intent** | 1–3 sentences on what the PR does. |
| **Acceptance criteria** | The criteria from the linked issues. |
| **Docs consulted** | The names of the docs. |
| **Planned scope** | Files ranked as read in full, skim the diff, or skip as generated. |
| **Conformance** | A note that you will check the code against the governing doc. |
| **Open questions** | Anything unclear about intent or scope, to settle now. |

Show the **Conformance** row only when a spec or ADR governs the change. For a large PR, show
**Planned scope** as the **chunk carve-up** (see Step 5 → Big PRs).

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

**Big PRs use chunked mode.** Switch to chunked mode when the diff is large or crosses
subsystems. Large means more than about 10 files or about 800 changed lines. The chunked,
blast-radius-first flow lives in [BIG_PR.md](BIG_PR.md). That flow has four parts:

1. Carve the PR into coherent chunks. Review shared infra first.
2. Review each chunk in the same correctness → maintainability → performance order.
3. Write per-chunk findings into the review file after each chunk, with `path:line` or
   `path:range` anchors.
4. Add a conformance table when a spec or ADR applies. That table can re-rank severity.

[BIG_PR.md](BIG_PR.md) also offers an optional multi-agent fan-out as an independent second
opinion. **The verify gate there is mandatory.** The fan-out produces convincing false positives.
Never ship a candidate that you did not confirm against the code yourself.

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

**A migration needs a specialist.** Migration files are `migrations/`, `*.sql`, and Go or Rust
files that change the schema. If the diff touches one, report it at the Ready gate and **offer**
the `migration-safety` agent. That agent grades five things: lock acquisition on big tables,
deploy order, rollback viability, data-loss risk, and index strategy. It returns a go or no-go.
You need the explicit go of the user before you spawn it (`rules/spawning-subagents.md`). If the
user declines, review the migration yourself against those same five headings. A migration
carries the largest blast radius in a PR. Never accept one after a skim only.

## Step 6: Deliver findings

Use [TEMPLATE.md](TEMPLATE.md). The default is **chat first**. Show the report with each finding
and its `file:line`. Then **review the findings with the user one by one**. The user accepts or
drops each finding before anything leaves the session.

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

> The `/code-review` skill of the repo is an option for a fast, automatic diff pass instead of
> this step-by-step flow. Mention that skill. Do not transfer the work to it on your own.
