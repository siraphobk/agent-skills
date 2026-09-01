# Coverage Checklist: the lenses

There are two lens sets. The **issue kind** picks the set, in Step 0 of [SKILL.md](SKILL.md).

- **Bug / investigation:** use the failure-class lenses below. You ask *what is wrong with the
  existing code*.
- **Feature:** use the readiness-to-build lenses further down. You ask *what must this do, where
  does it connect, and what do I decide*.

The process is the same for both kinds. That covers the modes, the gates, the fan-out, the subagent
contract, and severity normalization. Only the lens set, the finding categories, and the report
schema change.

# Bug / investigation lenses

Search the surface by **failure class**, not by report category. Each lens below is one pass over
the affected code. You categorize a finding as Gap, Bug, or Risk *after* you find it. The lens is
how you find it in the first place. Run every lens that plausibly applies. Note the lenses you
excluded, so the coverage is auditable.

## Lenses

| # | Lens | What to look for |
|---|------|------------------|
| 1 | Correctness and invariants | wrong logic, off-by-one, broken pre/postconditions, state that can go inconsistent, assumptions that do not hold for all inputs |
| 2 | Concurrency and ordering | races, missing locks, non-atomic read-modify-write, lost updates, ordering assumptions, idempotency under retry or duplicate delivery |
| 3 | Error handling and failure modes | swallowed errors, partial failure, missing rollback, retries without backoff or limit, timeouts, cancellation, resource leaks on the error path |
| 4 | Data integrity | missing validation, nullability, uniqueness and constraint gaps, migration safety forward and back, encoding or precision loss, orphaned or duplicated records |
| 5 | Security and trust | authz/authn gaps, untrusted input that reaches a sink (injection, path, deserialization), secret handling, over-broad permissions, sensitive data in logs |
| 6 | Performance and scale | N+1 queries, unbounded result sets, memory growth, missing indexes, hot-path allocations, synchronous work that should be async, cache stampede |
| 7 | Boundaries and contracts | API and schema backward compatibility, breaking changes to callers, hidden coupling, leaked internals, inconsistent error contracts across a boundary |
| 8 | Tests and observability | untested branches and edge cases, no regression test for the issue's bug, missing structured logs, missing metrics or traces on the new path |

Map the hits of each lens to findings. Tag each finding with the category **Gap**, **Bug**, or
**Risk**.

# Feature lenses

For a feature issue you do not hunt failure modes in existing code. You survey **readiness to
build**. Each lens is one pass over the surface, which is the existing code the feature will touch
or extend. Each lens asks what the builder must know or decide. You categorize a finding as
**Decision**, **Integration point**, **Risk-Unknown**, or **Open question** *after* you find it. Run
every lens that plausibly applies. Note the lenses you excluded.

## Lenses

| # | Lens | What to look for |
|---|------|------------------|
| 1 | Requirements and acceptance | what the feature must do, the acceptance criteria, explicit non-goals, ambiguities to resolve before coding |
| 2 | Integration points | where the feature connects: entrypoints, modules to extend, interfaces and ports, the call sites that will invoke it |
| 3 | Existing patterns and reuse | how this codebase already builds similar features, so the new one is idiomatic, plus existing helpers and abstractions to use instead of new ones |
| 4 | Data model and persistence | new tables, columns, and migrations, indexes, encoding, which datastore fits (apply the datastore decision tree), forward and back migration safety |
| 5 | API and contracts | new endpoints, RPCs, and events, request and response shapes, versioning, backward compatibility with existing callers |
| 6 | Design options and tradeoffs | the 2–3 realistic ways to build the feature, each with its trade-off |
| 7 | Cross-cutting impact | config, feature flags, authz/authn, observability, performance budget, i18n, whatever the feature touches beyond its own module |
| 8 | Risks, unknowns, and dependencies | third-party deps, external services, unknowns that need a spike, sequencing and blocking between parts, rollout and flagging concerns |
| 9 | Test strategy | what to TDD and what to test after (per the workflow rules), key scenarios to cover, fixtures or harnesses the feature will need |

Three lenses carry an extra instruction:

- **Lens 1:** take the requirements from the issue. Record what is underspecified as an **Open
  question** finding.
- **Lens 2:** each concrete touch point is one finding.
- **Lens 6:** each option is a **Decision** finding with a recommendation. This lens is the heart of
  feature pre-work.

Map the hits of each lens to findings. Tag each finding with **Decision**, **Integration point**,
**Risk-Unknown**, or **Open question**.

## How to apply the lenses

Lens breadth follows the mode (`deep` ⊇ `default` ⊇ `quick`):

- **`quick`:** run only the lenses **most relevant to the issue**, typically 2–4. Walk them yourself
  in one pass. Name them at the start.
- **`default`, small scope:** run all **applicable** lenses. Prune the ones that clearly do not
  apply. Walk them yourself.
- **`default`, large scope (lens fan-out):** use one subagent per applicable lens. Each subagent
  scans the **whole** surface through that single lens. This finds more than a split by module,
  because each subagent reasons deeply in one failure mode.
- **`deep`:** run every lens, even the marginal ones. Use lens fan-out for a single-area surface.
  Use a **matrix** (one subagent per area and lens pair) only when there is more than one distinct
  area.

**Subagent contract:** pass each agent the surface map, so the agent does not discover the files
again. The agent **returns** concise findings: location, short evidence, why, proposed suggestion,
and provisional severity. The agent does **not** write report files. The orchestrator dedupes the
findings, normalizes severity, and writes the report by editing the returned material. The
orchestrator does not read the code again.

**Model per subagent (token control):** a single-lens scan is narrow. Default it to `sonnet`. Use
`haiku` for the simplest lenses, such as tests and observability. Reserve Opus for the merge and
triage the orchestrator does, not for the fan-out. The plan presented at Gate 2 names the model, so
the user can override it.

Findings land in doc 3 of the report. The `F-NN` key ties each finding to its recommendation in
doc 4. The bug report and the feature report share that structure. See
[TEMPLATES.md](TEMPLATES.md) for both variants.
