# Coverage Checklist — the lenses

Two lens sets, picked by **issue kind** (Step 0 in [SKILL.md](SKILL.md)):

- **Bug / investigation** → the failure-class lenses below. You're asking *what's wrong with the
  existing code*.
- **Feature** → the readiness-to-build lenses further down. You're asking *what must this do, where
  does it plug in, what do I decide*.

The orchestration (modes, gates, fan-out, subagent contract, severity normalization) is identical
for both — only the lens set, the finding categories, and the report schema change.

# Bug / investigation lenses

Search the surface by **failure class**, not by report category. Each lens below is one pass over
the affected code. A finding is categorized as Gap / Bug / Risk *after* you find it — the lens is
how you find it in the first place. Run every lens that plausibly applies; note the ones you ruled
out so coverage is auditable.

## Lenses

1. **Correctness & invariants** — wrong logic, off-by-one, broken pre/postconditions, state that
   can go inconsistent, assumptions that don't hold for all inputs.
2. **Concurrency & ordering** — races, missing locks, non-atomic read-modify-write, lost updates,
   ordering assumptions, idempotency under retry/duplicate delivery.
3. **Error handling & failure modes** — swallowed errors, partial failure, missing rollback,
   retries without backoff/limit, timeouts, cancellation, resource leaks on the error path.
4. **Data integrity** — missing validation, nullability, uniqueness/constraint gaps, migration
   safety (forward/back), encoding/precision loss, orphaned or duplicated records.
5. **Security & trust** — authz/authn gaps, untrusted input reaching a sink (injection, path,
   deserialization), secret handling, over-broad permissions, sensitive data in logs.
6. **Performance & scale** — N+1 queries, unbounded result sets / memory growth, missing indexes,
   hot-path allocations, synchronous work that should be async, cache stampede.
7. **Boundaries & contracts** — API/schema backward compat, breaking changes to callers, hidden
   coupling, leaking internals, inconsistent error contracts across a boundary.
8. **Tests & observability** — untested branches and edge cases, no regression test for the
   issue's bug, missing/structured logs, missing metrics or traces on the new path.

Map each lens's hits to findings, tagging the category **Gap / Bug / Risk**.

# Feature lenses

For a feature issue you're not hunting failure modes in existing code — you're surveying
**readiness to build**. Each lens is one pass over the surface (existing code the feature will
touch or extend), asking what the builder needs to know or decide. A finding is categorized as
**Decision / Integration point / Risk-Unknown / Open question** *after* you find it. Run every lens
that plausibly applies; note the ones you ruled out.

## Lenses

1. **Requirements & acceptance** — what the feature must do, acceptance criteria, explicit
   non-goals, and ambiguities that must be resolved before coding. Pull these from the issue; flag
   what's underspecified as **Open question** findings.
2. **Integration points & seams** — where the feature plugs in: entrypoints, modules to extend,
   interfaces/ports, the call sites that will invoke it. Each concrete touch point is a finding.
3. **Existing patterns & reuse** — how similar features are already built in this codebase (so the
   new one is idiomatic), and existing helpers/abstractions to lean on instead of reinventing.
4. **Data model & persistence** — new tables/columns/migrations, indexes, encoding, and which
   datastore fits (apply the datastore decision tree). Forward/back migration safety.
5. **API & contracts** — new endpoints/RPCs/events, request/response shapes, versioning, backward
   compatibility with existing callers.
6. **Design options & tradeoffs** — the 2–3 realistic ways to build it, each a **Decision** finding
   with a recommendation. This is the heart of feature pre-work.
7. **Cross-cutting impact** — config, feature flags, authz/authn, observability, perf budget, i18n —
   what the feature touches beyond its own module.
8. **Risks, unknowns & dependencies** — third-party deps, external services, unknowns that need a
   spike, sequencing/blocking between parts, rollout/flagging concerns.
9. **Test strategy** — what to TDD vs test-after (per the workflow rules), key scenarios to cover,
   fixtures or harnesses the feature will need.

Map each lens's hits to findings, tagging the category **Decision / Integration point /
Risk-Unknown / Open question**.

## How to apply

Lens breadth follows the mode (`deep` ⊇ `default` ⊇ `quick`):

- **`quick`:** only the lenses **most relevant to the issue** (typically 2–4), walked yourself in
  one pass. Name them up front.
- **`default`, small scope:** all **applicable** lenses (prune clearly-N/A ones), walked yourself.
- **`default`, large scope (lens fan-out):** one subagent per applicable lens, each scanning the
  **whole** surface through that single lens — finds more than splitting by module, because each
  subagent reasons in one failure mode deeply.
- **`deep`:** every lens, even marginal ones. Lens fan-out for a single-area surface; **matrix**
  (subagent per area × lens) only when there's more than one distinct area.

**Subagent contract:** pass each agent the surface map so it doesn't re-discover files; it
**returns** concise findings (location, short evidence, why, proposed suggestion, provisional
severity) — it does **not** write report files. The orchestrator dedupes, normalizes severity, and
writes the report by editing the returned material (no re-reading the code).

**Model per subagent (token control):** a single-lens scan is narrow — default it to `sonnet`, and
`haiku` for the simplest lenses (e.g. tests/observability). Reserve Opus for the merge/triage the
orchestrator does, not the fan-out. The plan presented at Gate 2 names the model so the user can
override.

Findings land in doc 3 of the report, keyed by `F-NN` to their recommendations in doc 4 — the
bug report and the feature report share that structure. See [TEMPLATES.md](TEMPLATES.md) for both
variants.
