# Summary mode

Use this procedure only in `summary` mode. The main skill owns the repo check, checkout, context gathering, file ranking, and chunking.
The result is a summary that tells the user what the PR changes and why, in one read.
Summary mode is not a review. No findings does not mean approval.

## Workflow

1. **Gather context.** Complete Steps 0–3 of the main skill without change.
   Take the reason for the change from issues, docs, and discussions. The PR body is a claim, not proof.

2. **Show a short Ready gate.** Show Intent, Planned scope, and Open questions. Wait for the user to say go.

3. **Read the implementation.** Use the main skill's file ranking. Read domain and app logic in full.
   Trace each behavior change from its entry point to its effect. Separate changed behavior from unchanged support code.
   For a big PR, use the chunks from [BIG_PR.md](BIG_PR.md). Write 2–4 lines for each chunk, then merge them into one summary.
   Do not pause between chunks.

4. **Compare the claim with the code.** Find changes in the diff that the PR body does not mention.
   Find claims in the PR body that the diff does not implement.

5. **Deliver.** Use the Context and Change summary sections of [TEMPLATE.md](TEMPLATE.md). Add watch points below.

## Watch points

Do not search for defects. When you see a possible defect or risk while you read, record it.
Give each watch point one line and an anchor. Put them under a `**Watch points:**` line after `**Read first:**`.
Give no severity, because summary mode does not verify defects.
Always list a migration as a watch point, because summary mode does not do the full migration review.
Recommend a standard review when a watch point could be a correctness or security bug.

## Delivery

Chat is the default. Offer to save `.agents/scratch/reviews/pr-<number>-summary.md` when the user asks.
In worktree mode, offer to save without a request.
Never post to GitHub in summary mode.
When the user asks for a review after the summary, continue at Step 5 in standard mode. Use the context you already have.

## Worked example

This example uses a fictional PR, paths, and issue. The PR adds retries to webhook delivery.

### Too coarse

This PR refactors the webhook module and adds retries. Several files changed, and the PR adds tests.

### Right density

**Why:** Merchants lose order events when their endpoint fails once. Issue #212 reports 3% dropped deliveries during deploys.
`docs/webhooks.md:40-52` requires at-least-once delivery.

**What changed:**
- A failed delivery now retries up to 5 times with exponential backoff — `webhook/deliver.go:33-71`
- The service stores each attempt, so the count continues after a restart — `webhook/store.go:18-40`, `migrations/0042_attempts.sql`
- The dashboard API shows the attempts for each event — `api/webhooks.go:88-102`
- `Send` becomes `Deliver`. New tests cover the backoff timing.

**What did not change:** The payload format and the signature stay the same.

**Claim vs. code:** The PR body says "retries on timeout". The code also retries on every 5xx response (`webhook/deliver.go:52`).

**Read first:** `webhook/deliver.go:33-71` holds the retry loop. `migrations/0042_attempts.sql` adds a table on the delivery path.

**Watch points:** `migrations/0042_attempts.sql:3` adds an index to a large table. A standard review must check its lock behavior.
