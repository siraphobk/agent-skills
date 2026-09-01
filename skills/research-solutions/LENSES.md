# Problem types

Pick the primary type in Step 2 and say why. Each type sets four things:

1. The **questions that must be answered** before any approach is credible.
2. **Where the standards live**, so outward research starts in the right place.
3. **Where our evidence lives**, so inward research starts in the right place too.
4. The **failure modes** that every approach must address.

A second type often applies. Note it, and use its questions as well.

If no type fits, say so and build the question list from the closest two. Do not
force a bad match. A wrong type sends the whole research in the wrong direction.

---

## 1. Integration: connecting to a third party

**Looks like:** a payment provider, a shipping carrier, an ERP, a marketplace, or
any system you do not control.

**Must answer**
- What is the **connection surface**: REST, webhook, SDK, file drop, or message queue?
- Which side is the **source of truth** for each shared object? How does the other
  side learn about changes?
- What is the **auth model**: keys, OAuth, mTLS, or signed webhooks? What is the
  rotation story?
- What are the **rate limits, quotas, and sandbox**? Can you test outside
  production?
- What is **idempotent** on their side, and what key do they honor?

**Standards live in:** the vendor's own API reference and webhook docs first. Then
their changelog and status page history. Then the RFCs for the transport, such as
HTTP semantics, webhook signing, and OAuth. Their OSS SDK is often more honest
than the docs.

**Our evidence lives in:** any third-party adapter we already have. That adapter
is the pattern to copy, or the mistake not to repeat. Then read the inbound HTTP
layer and the route table. Then read the outbound client and its retry config.
Then read the queue or worker setup that an async approach would need. Confirm
that the worker exists before an approach depends on one.

**Failure modes to cover.** This section is mandatory for this type.
- Duplicate delivery and replay. Idempotency keys.
- Timeout with an unknown outcome. Did the request arrive, or not?
- Out-of-order events.
- Reconciliation. How you detect and repair drift after an outage.
- Backfill and initial sync of existing data.
- Vendor outage. Do you queue, degrade, or refuse?

---

## 2. New capability: a feature that does not exist yet

**Looks like:** product wants something the system has never done.

**Must answer**
- What is the **smallest version that is genuinely useful**? What is the full version?
- Which **existing concept** does it extend, and which part is genuinely new?
- Who **uses** it, and through what surface: UI, API, background job, or admin tool?
- What does it need to **read and write**? Does that cross a boundary it should
  not cross?
- What already-solved problem is this a **special case of**?

**Standards live in:** how comparable products expose the same capability. Read
their public docs as a spec. Also read domain-modeling prior art, and open source
that implements the same idea.

**Our evidence lives in:** the domain model and the closest existing feature.
Build the new feature the way that one is built, unless there is a reason not to.
Then read the entry points it needs, such as route handlers, UI entry points, and
the job registry. Then read the permission layer that decides who sees it.

**Failure modes to cover**
- Partial adoption. Old records predate the feature.
- Permission and visibility gaps.
- The feature works, but nobody can find it.

---

## 3. Performance: it works, it is just too slow or too expensive

**Looks like:** a slow endpoint, a job that misses its window, or a cost line that
grows faster than usage.

**Must answer**
- What is the **target number**, and what is its source? "Faster" is not a target.
- Where do the time and the money actually go? **Measure it. Do not guess.**
- Is the bottleneck **algorithmic, I/O, contention, or volume**? Each one has a
  different family of fixes.
- What is the **cheapest fix that hits the target**? What is the fix that removes
  the ceiling for good?

**Standards live in:** the tuning docs of the database or the runtime. Also
published benchmarks from the vendor. Also engineering blogs where someone hit the
same wall at the same scale.

**Our evidence lives in:** the hot path itself. Read it before you propose
anything. Then read the query sites it touches. Then read whatever metrics or
tracing already exists. If none exists, that is finding one. Then read the live
resource limits on the service. Read the limits from the cluster, not from the
chart.

**Failure modes to cover**
- You optimize the wrong layer, because the measurement was coarse.
- A fix that trades correctness for speed, such as stale caches or dropped ordering.
- A fix that only holds at today's volume.

---

## 4. Data and modeling: shape, storage, or migration

**Looks like:** a new entity, a schema that no longer fits, or a move between
stores.

**Must answer**
- What are the **entities, their identity, and their lifecycle**?
- What must stay **consistent together**, and what can lag?
- **Retention and history.** Do you need the current value, or every value it ever had?
- If it is a migration, what is the **cutover shape**: dual-write, backfill then
  flip, or big-bang?
- How do you **reverse** it after data is already written in the new shape?

**Standards live in:** normalization and event-sourcing literature. Also the
target store's own migration guidance. Use the `migration-safety` agent for
anything that touches a live table.

**Our evidence lives in:** the existing schema and the migration directory. The
way this repo runs migrations constrains every cutover option. Then read the
entities that would change, their write sites, and the row counts on the tables
involved. A plan that ignores table size is a plan that stalls at cutover.

**Failure modes to cover**
- Backfill that takes longer than the deploy window.
- Locks on a large table.
- Two writers that disagree during dual-write.
- No way back after you drop the old data.

---

## 5. Reliability and scale: it breaks under load or under failure

**Looks like:** cascading failures, retry storms, or a component that you cannot
restart safely.

**Must answer**
- What is the **failure domain**? Which component makes which other component fail?
- What is the **required recovery behavior**: retry, queue, shed load, or fail loudly?
- Where does **state** live? What happens to in-flight work on restart?
- What is the **SLA or error budget** that this has to hold?

**Standards live in:** SRE literature, such as error budgets and graceful
degradation. Also the platform's own resilience docs. Also published postmortems
from companies at a similar scale.

**Our evidence lives in:** the k8s manifests. Read the replicas, the probes, the
resource limits, the PodDisruptionBudgets, and the restart policy. Read them live,
not from the chart. Then read the retry and timeout settings in code. Then read
the queue config. Also read any runbook that records what has already broken here.

**Failure modes to cover**
- Retry amplification.
- Thundering herd on recovery.
- Silent data loss during failover.
- Health checks that pass while the service is useless.

---

## 6. Build vs buy: choosing a tool, vendor, or library

**Looks like:** "should we use X or write our own?"

**Must answer**
- What is the **real cost of building**: the first version *and* the ongoing care?
- What **lock-in** does a purchase create, and what would an exit cost?
- Is the vendor or the project **healthy**? Check the release cadence, the open
  issue trends, and who funds it.
- Which requirements are **non-negotiable**? Does each candidate meet them?
- What is the **escape hatch** if this choice is wrong?

**Standards live in:** the license terms, and the project's own release and
security history. Also independent comparisons. Never use the vendor's own
comparison page.

**Our evidence lives in:** whatever we already built that overlaps. Half of
"should we buy this" is "how much of it do we already have". Then read the
dependency manifests (`go.mod`, `package.json`, `pyproject.toml`) for what the
project already includes. Then read existing vendor integrations for what one
adoption actually costs us. Ask the user for anything commercial, such as the
pricing tier, the contract, and the relationship.

**Failure modes to cover**
- Hidden per-seat or per-event pricing that scales badly.
- A missing feature that you only discover after adoption.
- Abandonment risk.
- Data trapped in a proprietary format.
