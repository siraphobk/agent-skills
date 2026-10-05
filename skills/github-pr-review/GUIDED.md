# Guided PR review

Use this procedure only in `guided` mode. The main skill owns context gathering, checkout, severity, and posting approval.
The result is shared understanding and an evidence-based review, not a line-by-line narration.

## Workflow

1. **Prepare the context brief.** Complete Steps 2 and 3 of the main skill before judging implementation.
   Identify the problem, intended users, expected behavior, constraints, non-goals, and important failure behavior.
   Give each objective a stable ID, such as O1. Cite its source and label inferred objectives.
   Record contradictory sources and missing information. Do not choose the implementation as the authority for disputed intent.
   Identify what evidence could establish each objective, including boundary cases and runtime scenarios.

2. **Propose the concept map.** Use documentation, PR metadata, and file names before the Ready gate.
   A concept is one responsibility or domain rule. It can span files, or share a file with other concepts.
   Name each concept, its objective IDs, dependencies, and likely code locations.
   Order concepts so the user understands prerequisites before their consumers. Identify cycles and shared contracts explicitly.
   Account for every in-scope file. Keep generated files visible as skipped, not silently omitted.
   Treat this map as provisional until you read implementation after the Ready gate.
   Show the map with the context brief, then wait for explicit approval.

3. **Explain one concept.** Read the full relevant files and surrounding callers after approval.
   Confirm or revise the concept map. Explain material revisions before continuing, and obtain approval for scope changes.
   Use the concept card below. Start with purpose, then trace input, decisions, state changes, output, and failure paths.
   Separate changed behavior from unchanged supporting code. Cite precise `path:line` or `path:start-end` anchors.
   Explain dependencies on earlier concepts and assumptions that later concepts must confirm.
   Show only code needed to explain a decision. Do not paste whole files or narrate every line.

4. **Assess the evidence.** Read test assertions, not just test names. Check whether they establish the stated objective.
   Distinguish source inspection, tests inspected, observed execution, and author-reported results.
   Record the scenario, expected result, actual result, and evidence source for observed execution.
   A passing suite alone does not establish runtime behavior. Never claim a scenario ran without observed output.
   Use available tools for safe verification. Report environment or tool limits and leave affected claims unverified.
   Obtain approval before an experiment changes code or external state.
   Apply the main skill's correctness, maintainability, performance, security, and migration rules.
   Record candidate findings with anchors and severity. Keep unresolved dependencies explicit rather than declaring premature success.

5. **Pause and preserve progress.** Show the compact progress map and wait after each concept.
   Keep the concept current while awaiting questions or continuation. A question is not permission to advance.
   Answer questions about current or earlier concepts without starting another concept.
   On explicit continuation, mark the settled concept complete and start the next one.
   Preserve objective IDs, sources, dependencies, verification evidence, and candidate findings across turns.
   Revisit earlier assessments when a later concept invalidates their assumptions.
   For large PRs, retain chunk boundaries and track concepts within each chunk. Do not replace chunks with arbitrary file slices.

6. **Assess the complete behavior.** After all concepts, trace the combined behavior across their boundaries.
   Check that dependencies, failure paths, and state transitions support the objectives together.
   Use the main report template to map every objective to implementation, evidence, and assessment.
   Distinguish `met`, `partially met`, `not met`, and `unverified` objectives. Explain each unmet or uncertain part.
   Keep review coverage separate from objective status. An explained concept does not prove its objective.
   Review findings with the user through the main skill's delivery gate. Do not post without approval.

## Concept card

**Concept:** <name and objective IDs>

**Purpose:** <what this responsibility means, why it exists, and the required behavior>

**Implementation:** <entry point, decisions, state changes, outputs, failure paths, and dependencies, with anchors>

**Verification:** <evidence type, scenario or assertion, result, and remaining uncertainty>

**Assessment:** <whether the concept meets its goal, candidate findings, and unresolved dependencies>

| Concept | Objectives | Depends on | Status |
|---|---|---|---|
| <previous concept> | O1 | none | complete |
| <current concept> | O2 | <previous concept> | current |
| <next concept> | O2 | <current concept> | pending |

Stop here. Wait for questions or explicit continuation before explaining the next concept.

## Worked example

This example uses fictional paths and evidence. It demonstrates one turn after approval of the context brief.
The brief cites `docs/payments.md:12-18` for O1: retries must not create duplicate charges.
The map has two concepts: retry identity, then charge creation.

### Too coarse

The handler uses an idempotency key. The database has a unique constraint, and tests pass. This looks correct.

### Right density

**Concept:** Retry identity, O1.

**Purpose:** A retry must identify the original payment attempt. Otherwise the database cannot distinguish a retry from a new charge.

**Implementation:** `api/payments.go:41-58` reads the caller's retry key and validates it before creating a payment command.
An empty key returns a client error before charge creation. `domain/payment.go:23-31` preserves the key in that command.
The PR changes validation, not key generation. Charge creation must use the preserved key within the merchant's scope.
We will inspect that dependency in the next concept.

**Verification:** Source inspection confirms that validation precedes the charge call.
`api/payments_test.go:70-96` asserts a client error and no charge call for an empty key.
Those assertions cover missing identity, not duplicate charging. The tests were inspected but not run in this session.
The author's reported test pass does not prove merchant-scoped uniqueness under concurrent retries.

**Assessment:** Missing-key handling matches the documented rule by inspection. O1 remains unverified until we inspect charge creation and concurrency evidence.
No defect is confirmed in this concept. The database dependency remains open.

| Concept | Objectives | Depends on | Status |
|---|---|---|---|
| Retry identity | O1 | none | current |
| Charge creation | O1 | Retry identity | pending |

Wait here for questions or explicit continuation. Do not begin charge creation in the same turn.

## Constraints

- Gather available context before requesting information. Do not demand exhaustive documentation unrelated to the objectives.
- Never treat a PR claim, a test name, or an inferred requirement as verified behavior.
- Explain one concept per turn. Do not continue because the next concept looks simple.
- Keep the progress map compact. Preserve evidence references instead of repeating earlier explanations.
- Chat remains the default. Ask for approval before saving a review or making an outward-facing change.
