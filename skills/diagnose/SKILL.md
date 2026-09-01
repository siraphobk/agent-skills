---
name: diagnose
allowed-tools: Read Write Edit Grep Glob Bash
description: Disciplined diagnosis loop for hard bugs and performance regressions. Reproduce → minimise → hypothesise → instrument → fix → regression-test. Use when user says "diagnose this" / "debug this", reports a bug, says something is broken/throwing/failing, or describes a performance regression. NOT for a breadth-first pre-change survey of the code around an issue — use analyze-issue for that.
---

# Diagnose

This skill is a discipline for hard bugs. Skip a phase only when you can justify the skip.

Read the project's domain glossary when you explore the codebase. The glossary gives you a clear mental model of the relevant modules. Also read the ADRs for the area you change.

## Phase 1: Build a feedback loop

**This is the skill.** Everything else is mechanical. You will find the cause if you have a fast, deterministic pass/fail signal for the bug. The agent must be able to run that signal. Bisection, hypothesis tests, and instrumentation all consume that signal. Without a signal, no amount of code reading will save you.

Spend disproportionate effort here. **Be aggressive. Be creative. Do not quit.**

### Ways to construct a loop, in roughly this order

| # | Way | How you use it |
|---|---|---|
| 1 | Failing test | Write it at whatever test point reaches the bug. Unit, integration, or e2e. |
| 2 | Curl or HTTP script | Send requests to a running dev server. |
| 3 | CLI invocation | Give it a fixture input. Diff stdout against a known-good snapshot. |
| 4 | Headless browser script | Playwright or Puppeteer drives the UI. Assert on DOM, console, or network. |
| 5 | Replay of a captured trace | Save a real request, payload, or event log to disk. Replay it through the code path alone. |
| 6 | Throwaway harness | Start a minimal subset of the system, with mocked deps. One function call reaches the bug. |
| 7 | Property or fuzz loop | For a "sometimes wrong output" bug, run 1000 random inputs. Look for the failure mode. |
| 8 | Bisection harness | For a bug between two known states, automate "boot at state X, check, repeat". |
| 9 | Differential loop | Run one input through two versions, or through two configs. Diff the outputs. |
| 10 | HITL bash script | Last resort. If a human must click, drive them with `scripts/hitl-loop.template.sh`. |

Notes on the table:

- A known state in row 8 is a commit, a dataset, or a version. Automation lets you run `git bisect run` on it.
- The script in row 10 keeps the loop structured. Its captured output returns to you.

Build the right feedback loop. The bug is then 90% fixed.

### Iterate on the loop itself

Treat the loop as a product. Once you have _a_ loop, ask:

- Can I make it faster? (Cache setup, skip unrelated init, narrow the test scope.)
- Can I make the signal sharper? (Assert on the specific symptom, not "didn't crash".)
- Can I make it more deterministic? (Pin time, seed RNG, isolate filesystem, freeze network.)

A 30-second flaky loop is barely better than no loop. A 2-second deterministic loop is a debugging superpower.

### Non-deterministic bugs need a higher reproduction rate

The goal is not a clean repro. The goal is a **higher reproduction rate**. Loop the trigger 100×, run loops in parallel, add stress, narrow the timing windows, and inject sleeps. A 50%-flake bug is debuggable. A 1%-flake bug is not. Keep raising the rate until the bug is debuggable.

### Stop when you genuinely cannot build a loop

Stop and say so explicitly. List what you tried. Then ask the user for one of these:

1. Access to whatever environment reproduces the bug.
2. A captured artifact. That is a HAR file, a log dump, a core dump, or a screen recording with timestamps.
3. Permission to add temporary production instrumentation.

Do **not** proceed to hypothesise without a loop.

Do not proceed to Phase 2 until you have a loop you believe in.

## Phase 2: Reproduce

Run the loop. Watch the bug appear.

Confirm:

- [ ] The loop produces the failure mode that the **user** described. It does not produce a different failure that happens to be nearby. A wrong bug gives a wrong fix.
- [ ] The failure is reproducible across multiple runs. For a non-deterministic bug, it is reproducible at a high enough rate to debug against.
- [ ] You captured the exact symptom, so later phases can verify that the fix addresses it. The symptom is the error message, the wrong output, or the slow timing.

Do not proceed until you reproduce the bug.

## Phase 3: Hypothesise

Generate **3–5 ranked hypotheses** before you test any of them. One hypothesis alone anchors you on the first plausible idea.

Each hypothesis must be **falsifiable**. State the prediction that it makes.

> Format: "If <X> is the cause, then <changing Y> will make the bug disappear / <changing Z> will make it worse."

If you cannot state the prediction, the hypothesis is a vibe. Discard it or sharpen it.

**Show the ranked list to the user before you test.** The user often has domain knowledge that re-ranks the list at once. An example is "we just deployed a change to #3". The user also knows which hypotheses they already excluded. The checkpoint is cheap and it saves much time. Do not wait for an answer. Proceed with your ranking if the user is AFK.

## Phase 4: Instrument

Each probe must map to a specific prediction from Phase 3. **Change one variable at a time.**

Tool preference:

1. **Debugger or REPL inspection**, if the environment supports it. One breakpoint beats ten logs.
2. **Targeted logs** at the boundaries that distinguish hypotheses.
3. Never "log everything and grep".

**Tag every debug log** with a unique prefix, for example `[DEBUG-a4f2]`. The cleanup at the end is then one grep. Untagged logs stay in the code. Tagged logs get removed.

**Perf branch.** For performance regressions, logs are usually wrong. Establish a baseline measurement instead. Use a timing harness, `performance.now()`, a profiler, or a query plan. Then bisect. Measure first and fix second.

## Phase 5: Fix + regression test

Write the regression test **before the fix**. Do this only if a **correct test point** exists for it.

At a correct test point, the test exercises the **real bug pattern** as it occurs at the call site. Some test points are too shallow. Two examples:

- A single-caller test, when the bug needs multiple callers.
- A unit test that cannot replicate the chain that triggered the bug.

A regression test at a shallow test point gives false confidence.

**If no correct test point exists, that is itself the finding.** Note it. The architecture of the codebase prevents a test that covers the bug. Flag this for the next phase.

If a correct test point exists:

1. Turn the minimised repro into a failing test at that test point.
2. Watch it fail.
3. Apply the fix.
4. Watch it pass.
5. Re-run the Phase 1 feedback loop against the original (un-minimised) scenario.

## Phase 6: Cleanup + post-mortem

Do these before you declare the work done:

- [ ] The original repro no longer reproduces. Re-run the Phase 1 loop.
- [ ] The regression test passes, or you documented that no correct test point exists.
- [ ] You removed all `[DEBUG-...]` instrumentation. `grep` the prefix.
- [ ] You deleted the throwaway prototypes, or you moved them to a clearly-marked debug location.
- [ ] The commit or PR message states the hypothesis that proved correct, so the next debugger learns.

**Then ask this question. What would have prevented this bug?** If the answer needs an architectural change, recommend it in the post-mortem with the specifics. Examples are no good test point, tangled callers, and hidden coupling. Make the recommendation **after** the fix is in place, not before. You have more information now than at the start.
