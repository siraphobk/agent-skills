---
name: github-pr-review
allowed-tools: Read Write Grep Glob Task Bash(gh *) Bash(git *) Bash(mkdir *)
description: Deep, step-by-step code review of a GitHub Pull Request. Checks out the PR (current dir or a worktree under .worktrees/), collects project docs and PR/issue context, shows an understanding brief, then reviews in a correctness → maintainability → performance order and gives findings graded by severity. Large PRs switch to a chunked, blast-radius-ordered mode with per-chunk findings and optional spec/ADR conformance checking. Use when the user invokes this skill directly or says "let's review a PR on github", "review this PR", "do a code review on PR <n>", or similar intent to review a GitHub pull request.
---

# GitHub PR Review

A deep, step-by-step PR review you run together with the user. **Stop at every gate — never
move ahead until the user says go.**

- Reads (PR body, issues, diff, files) use **`gh`** — `gh pr view`, `gh issue view`, `gh pr diff`.
- Local code work (checkout, diffs, file reads) uses **`git`**.

Get the PR first. If the user didn't give a number or URL, ask for one. Find `owner`/`repo`
from `git remote get-url origin`.

## Step 0 — Find the repo

The PR's `owner/repo` **must match** the current clone's `origin`. If it doesn't (or you're
not in a git repo), **stop** and tell the user. Don't quietly review some other repo.

Drop to the **read-only fallback (mode C)** only when the user can't or won't clone the repo.
In that mode you review straight from `gh pr diff` and `gh pr view`:
- No checkout, no local code, no doc search, no reading full files.
- Tell the user plainly that a diff-only review is shallower.

## Step 1 — Checkout

Ask: **current dir** or **worktree**. See [CHECKOUT.md](CHECKOUT.md) for the exact steps
(dirty tree, when to stash, worktree setup and teardown, restoring, fallback). Follow it — don't
make up your own git commands. Every later step runs against the checked-out PR code.

## Step 2 — Collect project docs

Search around the PR, not the whole monorepo:
- From `gh pr diff {number} --name-only`, find the directories the PR changes.
- For each changed dir, look inside it and **keep going up to the repo root** for `*.md`,
  `README*`, `docs/`, `ADR*`, `CONTEXT.md`, and service `README`s. Always include repo-root
  docs (`AGENTS.md`, `CLAUDE.md`, top-level `docs/`).
- List **names only** first, throw out the ones that don't matter, then read **only** the few
  that look useful.
- Then **ask the user** for any related docs the search would miss — a governing **feature spec
  or ADR often lives in a separate docs repo** the file search can't reach. If one governs this
  change, plan a conformance check (see [BIG_PR.md](BIG_PR.md) → Spec / ADR conformance).

## Step 3 — Understand the PR

- Read the PR: `gh pr view {number} --json number,title,body,state,author,headRefName,baseRefName,headRefOid`
- Open and read every linked or mentioned issue: `gh issue view {issue_number} --json number,title,body,comments`; note its acceptance criteria.
- **Read the review already on the PR before writing your own:**
  `gh api repos/{owner}/{repo}/pulls/{number}/comments` and `.../reviews`. Existing comments
  change what you write — where your finding lands on the same line or the same topic, **reply
  in that thread** rather than opening a new one, and say plainly when an existing comment is
  wrong. A question addressed to you there is a reply you owe regardless of your findings.
- Sum up what the PR **says** it does, plus the **testable criteria** it has to meet.

## Step 4 — Ready gate (understanding brief)

Show a short brief, then **wait for the user to clearly say go**:
- **Intent** — 1–3 sentences on what the PR does.
- **Acceptance criteria** — from the linked issues.
- **Docs consulted** — names.
- **Planned scope** — files ranked into: read in full, skim the diff, or skip as generated. For
  a large PR, present this as the **chunk carve-up** (see Step 5 → Big PRs).
- **Conformance** — if a spec/ADR governs the change, note you'll check the impl against it.
- **Open questions** — anything unclear about intent or scope to settle now.

Don't look at the diff until the user says go.

## Step 5 — Review

Sort the files first to spend tokens well: pull `gh pr diff {number} --name-only` and rank by
review value (domain/app logic > controllers > tests > config).
- **Always read domain/app logic in full.**
- **Always skip generated code** (gqlgen `graph/`, `*.pb.go`, `pkg/` codegen, lock and
  vendored files) — say that it changed, but don't review it.
- If the PR is still too big, show the ranked list and suggest a scope. Don't quietly cut
  files out.
- For files you read deeply, read the **whole file**, not just the unified diff.

**Big PRs → chunked mode.** When the diff is large (>~10 files / ~800 lines) or crosses
subsystems, switch to the chunked, blast-radius-first flow in [BIG_PR.md](BIG_PR.md): carve
the PR into coherent chunks (shared infra first), review each in the same correctness →
maintainability → performance order, write per-chunk findings with `path:line`/`path:range`
anchors into the review file as you go, and — when a spec/ADR applies — add a conformance
table that can re-rank severity. An optional multi-agent fan-out is available there as an
independent second opinion, **with a mandatory verify gate** (it produces convincing false
positives — never ship a candidate you haven't confirmed against the code yourself).

Rank every finding by this **value hierarchy** — a lower tier never beats a higher one:

1. **Correctness** (the hard line) — logic bugs, error/nil handling, races, edge cases, broken
   domain invariants, not meeting the acceptance criteria. **Test coverage belongs here:**
   - Does branching or domain logic have tests?
   - Does a bug-fix PR add a regression test?
   - A missing regression test is usually 🟡 Should-fix, and 🔴 Blocker when the code is
     invariant-heavy or domain logic.
   - Glue or wiring code without tests is fine — don't nag about it.
2. **Maintainability** — the next person should grasp it easily. Naming, layering (keep
   business logic out of resolvers/controllers — see repo `AGENTS.md`), coupling, readable
   flow, matching the repo's style.
3. **Performance** — only once the two above hold. Look for real problems (N+1/dataloaders,
   hot-path allocations, bad query patterns). **If the PR doesn't list perf as a goal, don't
   blow up small optimizations** — Nit at most, never a blocker.

**Security** sits on its own: authz (OpenFGA), input validation, injection. Treat it as a
correctness/safety bug — 🔴 Blocker no matter where it falls in the hierarchy.

**Migrations get a specialist.** If the diff touches migration files (`migrations/`, `*.sql`,
schema-changing Go/Rust files), flag it at the Ready gate and **offer** the `migration-safety`
agent — it grades lock acquisition on big tables, deploy order, rollback viability, data-loss
risk, and index strategy, and returns a go/no-go. Spawning it needs the user's explicit go
(`rules/spawning-subagents.md`); if they decline, review the migration yourself against those
same five headings. A migration is the highest-blast-radius thing a PR can carry — never let one
through on a skim.

## Step 6 — Deliver findings

Use [TEMPLATE.md](TEMPLATE.md). Default to **chat first**: show the report, each finding with
its `file:line`, then **go through the findings with the user** — they accept or drop each one
before anything leaves the session.

**Saving:** chat only by default. Offer to write `.agents/scratch/reviews/pr-<number>.md` if
asked. In worktree mode, **offer to save without being asked** (chat can scroll away).

**Post to GitHub** only when the user clearly says go, as one **batched review**:
1. Show the full set of comments in chat first; get the go.
2. **Check every anchor is in the diff.** GitHub rejects an inline comment whose `path` is not
   among the PR's changed files, or whose `line` falls outside a diff hunk — so verify against
   `gh api repos/{owner}/{repo}/pulls/{number}/files` *before* building the payload. When a
   finding is about an unchanged file, anchor it to the changed line that **causes or claims**
   the problem and name the real `file:line` in the body; if no such line exists, move the
   finding into the review body instead.
3. **Build and post the review in one call.** The `gh api` payload shape, the head-SHA lookup,
   the `side`/`event` fields, and the separate reply/edit calls all live in
   [TEMPLATE.md](TEMPLATE.md) → *Posting keeps this exact shape*. Build the payload with a
   script that splits the saved report on its `#### <ID>` headers — hand-writing that JSON does
   not scale past a few findings.

**Never `APPROVE` on your own** — that click is the user's. `COMMENT` is the default event;
use `REQUEST_CHANGES` only when there's ≥1 Blocker **and** the user opts in.

> For a fast, automatic diff pass instead of this step-by-step flow, the repo's `/code-review`
> skill is an option — mention it, don't hand off to it on your own.
