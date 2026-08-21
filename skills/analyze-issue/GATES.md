# Modes, kinds & gates

Depth and spend control for [SKILL.md](SKILL.md). The skill marks *where* each gate fires; this
file is the single source for *what* it presents and who can change what.

## Mode & kind

The invocation may carry up to two words, order-independent: a **mode** word and a **kind** word.
Parse both before anything else.

- **Mode** (`quick` | `default` | `deep`) sets investigation depth — see the table below. Lens
  breadth is a gradient: `deep` ⊇ `default` ⊇ `quick`. No mode word → `default`.
- **Kind** (`bug` | `feature`) selects the lens set and report variant. No kind word → **detect it
  in Step 0**, don't assume.

An unrecognized word → ask, don't guess.

### Mode

| Mode | When | Behavior |
|------|------|----------|
| `quick` | want a fast read | Single-pass, **no subagents**, only the lenses **most relevant to the issue** (named up front), **all gates skipped**, **chat-only — no files**. Offer a `write-plan` handoff if the user wants it saved. |
| `default` *(or none)* | normal use | **Scope-driven** — small scope runs single-pass; large scope fans out by lens. Runs all **applicable** lenses (clearly-N/A ones pruned). Gates 1 always; Gates 2/3 on large scope only. Writes the 4-file report. |
| `deep` | high-stakes, max coverage | **Full lens fan-out** (every lens, even marginal). Escalates to **matrix** (area × lens) only when there's more than one distinct area. Gates 1, 2, and 3 all fire. Writes the 4-file report. |

The mode table sets depth regardless of kind — a `feature` analysis still runs `quick`/`default`/
`deep` the same way, just with the feature lenses and report variant.

## Gates & budget

Gates control **agent and write spend**. They fire by mode/scope as below.

- **Gate 1 — Scope confirm (after Step 1; every mode except `quick`).** Present the issue as you
  read it, the **kind** (bug / feature, and why you classified it that way), the surface map, and
  your **scope estimate** (small / large + file/module count). Wait for go before any analysis
  spend. `quick` states understanding inline without stopping. If the kind or the map is wrong,
  correct from the user's feedback — both are cheap; the expensive fork stays behind Gate 2.
- **Gate 2 — Execution plan (large scope, and always in `deep`).** Present the fan-out plan and
  **wait for go** before spawning any subagent. The main token gate — the user can trim lenses,
  drop to single-pass, cap subagent count, or change the model.
- **Gate 3 — Triage (large scope, and always in `deep`).** Show the compact findings table
  (ID / category / severity / location) before writing the full report; let the user drop noise /
  low-severity items.

The steps below only mark *where* a gate fires — this section is the single source for what each
gate presents and who can change what.

**Small scope (default mode) auto-proceeds** through Gates 2 and 3 — no ceremony for cheap work.

## Detecting the kind

Read it from the strongest signal available:

- **GitHub labels / issue type** — `bug` → bug; `feature`/`enhancement`/`feature request` →
  feature. The most reliable signal when present.
- **Template** — a bug-report template → bug; a feature-request template → feature.
- **Verbs** — "broken / fails / regression / incorrect / crashes / wrong" → bug; "implement / add /
  support / introduce / new" → feature.

If the signals conflict or are absent, **ask at Gate 1** (you're stopping there anyway) — state
your best guess and let the user confirm or flip it. The kind decides the lens set
([CHECKLIST.md](CHECKLIST.md)), the finding categories, and the report variant
([TEMPLATES.md](TEMPLATES.md)); everything else runs the same.

## Gate 2 — the plan format

Present it like this and wait for go:

```
Scope:     large (surface = 14 files, 3 modules)
Mode:      lens fan-out
Lenses:    correctness, concurrency, data-integrity, error-handling
           [skipping: security (no untrusted input), perf (not a hot path)]
Subagents: 4   (model: sonnet)
```

