---
name: run-and-report-tests
allowed-tools: Read Write Grep Glob Bash
description: Detect the test runner for a target directory, confirm the command with the user, run it, then write a markdown summary to .agents/scratch/test-reports/<timestamp>-<dirname>.md. Invoke when (1) the user explicitly names this skill, or (2) the user asks to run tests AND write/save/generate a report, summarize the run, or capture results to a file. If the user only asks to run tests with no mention of a report, do NOT invoke this skill automatically — first ask whether they also want a written report; invoke only if they confirm, otherwise just run the tests inline.
---

# Run and Report Tests

## Workflow

Run the steps in order. Stop at each confirmation gate.

### 1. Detect test command

Identify the test target from the user input. The target is a directory or a package. Inspect the target:

- `*_test.go` present → Go. The default command is `go test -v <target>`.
- `*_test.py` / `test_*.py` / `conftest.py` / `pytest.ini` → probably pytest. Ask the user first. Do not assume.
- `*.test.ts` / `*.test.js` / `*.spec.ts` / `vitest.config.*` / `jest.config.*` → ask the user which runner to use.
- `Cargo.toml` with `#[test]` → `cargo test`.
- Pre-built binary, unknown language, or an unclear target → **ask the user for the exact command**.

### 2. Confirm command

Present the proposed command verbatim. Wait for the user to approve it. Do not run the command yet.

### 3. Ask report scope

Ask the user this question: full report (both passing and failing) OR failing only?

### 4. Run + capture

Run the agreed command with Bash. Capture stdout AND stderr (`2>&1`). Set a long timeout. The default is `600000` ms. Do not truncate the captured output before you parse it.

### 5. Parse output

Extract these facts:

- The total, passed, failed, and skipped counts.
- Each failing test: name, file:line, error message, and expected vs actual if present.
- The common pattern across the failures (same error string, same package, same step name, and so on).
- The root cause, if the output makes one obvious (for example, every failure says `got "DESIGNER"` → fixture leak or default-role bug).

Normalize the output into a markdown table if it is messy or unaligned.

### 6. Write report

Write the report to `.agents/scratch/test-reports/<YYYY-MM-DD-HH-MM-SS>-<test-dirname>.md`. This path is relative to the current working directory.

- Get the timestamp from `date +%Y-%m-%d-%H-%M-%S`.
- `<test-dirname>` is the basename of the target directory. Replace `/` with `-` if the target is a package path.
- Create `.agents/scratch/test-reports/` if the directory does not exist. Use `mkdir -p`.

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

- Never invent results. If a count is unclear, mark it `?` and give the reason.
- Keep the runner error text verbatim inside code blocks.
- Remove ANSI color codes before you write the report.
- Do not delete or overwrite an existing report.
- Write a report even if the test command does not start (compile error, missing binary). The failure is the result.
