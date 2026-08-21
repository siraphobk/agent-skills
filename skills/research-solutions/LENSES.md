# Problem types

Pick the primary type in Step 2 and say why. Each type sets four things: the
**questions that must be answered** before any approach is credible, **where the
standards live** so outward research starts in the right place, **where our
evidence lives** so inward research does too, and the **failure modes** every
approach has to address. A second type often applies — note it and borrow its
questions.

If nothing fits, say so and build the question list from the closest two. Don't
force a bad match; a wrong type sends the whole research the wrong way.

---

## 1. Integration — connecting to a third party

**Looks like:** a payment provider, a shipping carrier, an ERP, a marketplace, any
system you don't control.

**Must answer**
- What is the **connection surface** — REST, webhook, SDK, file drop, message queue?
- Which side is the **source of truth** for each shared object, and how does the
  other side learn about changes?
- **Auth model** — keys, OAuth, mTLS, signed webhooks. Rotation story?
- **Rate limits, quotas, and sandbox** — can you test without touching production?
- What is **idempotent** on their side, and what key do they honor?

**Standards live in:** the vendor's own API reference and webhook docs first; then
their changelog and status page history; then RFCs for the transport (HTTP
semantics, webhook signing, OAuth). Their OSS SDK is often more honest than the docs.

**Our evidence lives in:** any third-party adapter we already have — it is the
pattern to copy or the mistake not to repeat. Then the inbound HTTP layer and
route table, the outbound client and its retry config, and the queue or worker
setup an async approach would need. Confirm the worker actually exists before an
approach depends on one.

**Failure modes to cover** — mandatory section for this type
- Duplicate delivery and replay; idempotency keys
- Timeout with unknown outcome (did it land or not?)
- Out-of-order events
- Reconciliation — how you detect and repair drift after an outage
- Backfill and initial sync of existing data
- Vendor outage: queue, degrade, or refuse?

---

## 2. New capability — a feature that doesn't exist yet

**Looks like:** product wants something the system has never done.

**Must answer**
- What is the **smallest version that is genuinely useful**? What's the full version?
- Which **existing concept** does it extend, and which is genuinely new?
- Who **uses** it and through what surface — UI, API, background job, admin tool?
- What does it need to **read and write**, and does that cross a boundary it
  shouldn't?
- What already-solved problem is this a **special case of**?

**Standards live in:** how comparable products expose the same capability
(read their public docs as a spec), domain-modeling prior art, and open source
that implements the same idea.

**Our evidence lives in:** the domain model and the closest existing feature —
build the new one the way that one is built unless there's a reason not to. Then
the surface it needs (route handlers, UI entry points, job registry) and the
permission layer that decides who sees it.

**Failure modes to cover**
- Partial adoption — old records that predate the feature
- Permission and visibility gaps
- The feature working but nobody able to find it

---

## 3. Performance — it works, it's just too slow or too expensive

**Looks like:** a slow endpoint, a job that misses its window, a cost line growing
faster than usage.

**Must answer**
- What is the **target number**, and where does it come from? "Faster" is not a target.
- Where is the time or money actually going — **measured, not guessed**?
- Is the bottleneck **algorithmic, I/O, contention, or volume**? Each has a
  different family of fixes.
- What is the **cheapest fix that hits the target**, versus the one that removes
  the ceiling for good?

**Standards live in:** the database or runtime's own tuning docs, published
benchmarks from the vendor, and engineering blogs where someone hit the same wall
at the same scale.

**Our evidence lives in:** the hot path itself — read it before proposing
anything. Then the query sites it touches, whatever metrics or tracing already
exists (if none, that's finding one), and the live resource limits on the
service. Read limits from the cluster, not the chart.

**Failure modes to cover**
- Optimizing the wrong layer because the measurement was coarse
- A fix that trades correctness for speed (stale caches, dropped ordering)
- A fix that only holds at today's volume

---

## 4. Data & modeling — shape, storage, or migration

**Looks like:** a new entity, a schema that no longer fits, a move between stores.

**Must answer**
- What are the **entities, their identity, and their lifecycle**?
- What must stay **consistent together**, and what can lag?
- **Retention and history** — do you need the current value, or every value it ever had?
- If it's a migration: what is the **cutover shape** — dual-write, backfill then
  flip, or big-bang?
- How does it **roll back** after data has already been written in the new shape?

**Standards live in:** normalization and event-sourcing literature, the target
store's own migration guidance, and the `migration-safety` agent for anything that
touches a live table.

**Our evidence lives in:** the existing schema and migration directory — how
migrations are run here constrains every cutover option. Then the entities that
would change, their write sites, and the row counts on the tables involved
(a plan that ignores table size is a plan that stalls at cutover).

**Failure modes to cover**
- Backfill that takes longer than the deploy window
- Locks on a large table
- Two writers disagreeing during dual-write
- No path back once old data is dropped

---

## 5. Reliability & scale — it breaks under load or under failure

**Looks like:** cascading failures, retry storms, a component that can't be
restarted safely.

**Must answer**
- What is the **failure domain** — what takes what down with it?
- What is the **required recovery behavior**: retry, queue, shed load, or fail loudly?
- Where does **state** live, and what happens to in-flight work on restart?
- What is the **SLA or error budget** this has to hold?

**Standards live in:** SRE literature (error budgets, graceful degradation),
the platform's own resilience docs, and published postmortems from companies at
similar scale.

**Our evidence lives in:** the k8s manifests — replicas, probes, resource limits,
PodDisruptionBudgets, restart policy — read live rather than from the chart. Then
the retry and timeout settings in code, the queue config, and any runbook that
records what has already broken here.

**Failure modes to cover**
- Retry amplification
- Thundering herd on recovery
- Silent data loss during failover
- Health checks that pass while the service is useless

---

## 6. Build vs buy — choosing a tool, vendor, or library

**Looks like:** "should we use X or write our own?"

**Must answer**
- What is the **real cost of building** — first version *and* the ongoing care?
- What does buying **lock in**, and what would leaving cost?
- Is the vendor or project **healthy** — release cadence, open issue trends,
  who funds it?
- Which requirements are **non-negotiable**, and does each candidate meet them?
- What is the **escape hatch** if this turns out wrong?

**Standards live in:** license terms, the project's own release and security
history, and independent comparisons — never the vendor's own comparison page.

**Our evidence lives in:** whatever we already built that overlaps — half of
"should we buy this" is "how much of it do we already have". Then the dependency
manifests (`go.mod`, `package.json`, `pyproject.toml`) for what is already pulled
in, and existing vendor integrations for what adopting one actually costs us.
Ask the user for anything commercial — pricing tier, contract, relationship.

**Failure modes to cover**
- Hidden per-seat or per-event pricing that scales badly
- A missing feature that only shows up after adoption
- Abandonment risk
- Data trapped in a proprietary format
