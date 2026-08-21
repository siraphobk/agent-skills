---
name: run-and-report-tests
allowed-tools: Read Write Grep Glob Bash
description: Detect the test runner for a target directory, confirm the command with the user, run it, then write a markdown summary to .agents/scratch/test-reports/<timestamp>-<dirname>.md. Invoke when (1) the user explicitly names this skill, or (2) the user asks to run tests AND write/save/generate a report, summarize the run, or capture results to a file. If the user only asks to run tests with no mention of a report, do NOT invoke this skill automatically — first ask whether they also want a written report; invoke only if they confirm, otherwise just run the tests inline.
---

# Run and Report Tests

## Workflow

Run in order. Stop at each confirmation gate.

### 1. Detect test command

Identify the test target (directory or package) from user input. Inspect it:

- `*_test.go` present → Go. Default cmd: `go test -v <target>`.
- `*_test.py` / `test_*.py` / `conftest.py` / `pytest.ini` → likely pytest. Ask user before assuming.
- `*.test.ts` / `*.test.js` / `*.spec.ts` / `vitest.config.*` / `jest.config.*` → ask which runner.
- `Cargo.toml` with `#[test]` → `cargo test`.
- Pre-built binary, unknown language, or ambiguous → **ask user for the exact command**.

### 2. Confirm command

Present the proposed command verbatim. Wait for user approval. Do not run yet.

### 3. Ask report scope

Ask: full report (both passing and failing) OR failing only?

### 4. Run + capture

Run the agreed command via Bash. Capture stdout AND stderr (`2>&1`). Set a generous timeout (default `600000` ms). Do not truncate the captured output before parsing.

### 5. Parse output

Extract:

- Total / passed / failed / skipped counts.
- Each failing test: name, file:line, error message, expected vs actual if present.
- Common pattern across failures (same error string, same package, same step name, etc.).
- Obvious root cause if one jumps out (e.g., every failure says `got "DESIGNER"` → fixture leak or default-role bug).

If output is messy or unaligned, normalize into a markdown table.

### 6. Write report

Path: `.agents/scratch/test-reports/<YYYY-MM-DD-HH-MM-SS>-<test-dirname>.md`, relative to current working directory.

- Timestamp: `date +%Y-%m-%d-%H-%M-%S`.
- `<test-dirname>`: basename of target dir; if a package path, replace `/` with `-`.
- Create `.agents/scratch/test-reports/` if missing (use `mkdir -p`).

### 7. Confirm

Print the absolute report path to the user.

## Report template

```md
# Test Report — <test-dirname>

- **Command**: `<exact command run>`
- **Run at**: <ISO timestamp>
- **Target**: `<absolute path>`
- **Duration**: <if reported by runner>

## Summary

| Metric  | Count |
|---------|-------|
| Total   | N     |
| Passed  | N     |
| Failed  | N     |
| Skipped | N     |

## Failing tests

| Test | Location | Error |
|------|----------|-------|
| ...  | file:line | ... |

## Common pattern

<one-paragraph description of shared failure shape, or "No common pattern.">

## Root cause hypothesis

<only if obvious from output; otherwise omit this section>

## Passing tests
<include only if user asked for full report; otherwise omit>

- name (file:line)
- ...

## Raw output

<details>
<summary>Click to expand</summary>

\`\`\`
<verbatim captured output>
\`\`\`

</details>
```

## Constraints

- Never invent results. If a count is unclear, mark it `?` and note why.
- Preserve runner error text verbatim inside code blocks.
- Strip ANSI color codes before writing to the report.
- Do not delete or overwrite existing reports.
- If the test command fails to start (compile error, missing binary), still write a report — the failure is the result.
