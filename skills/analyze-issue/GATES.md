# Modes, kinds, and gates

Depth and spend control for [SKILL.md](SKILL.md). The skill marks *where* each gate fires. This
file is the single source for *what* each gate presents and who can change what.

## Mode and kind

The invocation can carry up to two words, in any order: a **mode** word and a **kind** word. Parse
both before anything else.

- **Mode** (`quick`, `default`, or `deep`) sets the depth of the investigation. See the table below.
  Lens breadth is a gradient: `deep` ⊇ `default` ⊇ `quick`. With no mode word, the mode is `default`.
- **Kind** (`bug` or `feature`) selects the lens set and the report variant. With no kind word,
  **detect the kind in Step 0**. Do not assume it.

Ask about an unrecognized word. Do not guess.

### Mode

| Mode | When | Behavior |
|------|------|----------|
| `quick` | you want a fast read | Single pass. **No subagents.** Only the lenses **most relevant to the issue**, named at the start. **All gates skipped.** **Chat only, no files.** Offer a `write-plan` handoff if the user wants the answer saved. |
| `default` *(or none)* | normal use | **Scope-driven.** A small scope runs a single pass. A large scope uses lens fan-out. Runs all **applicable** lenses, and prunes the ones that clearly do not apply. Gate 1 always fires. Gates 2 and 3 fire on a large scope only. Writes the 4-file report. |
| `deep` | high stakes, maximum coverage | **Full lens fan-out**, every lens, even the marginal ones. Escalates to a **matrix** (one subagent per area and lens pair) only when there is more than one distinct area. Gates 1, 2, and 3 all fire. Writes the 4-file report. |

The mode table sets the depth for either kind. A `feature` analysis still runs `quick`, `default`,
or `deep` the same way. It only uses the feature lenses and the feature report variant.

## Gates and budget

Gates control **agent and write spend**. They fire by mode and scope, as below.

- **Gate 1, scope confirm.** It fires after Step 1, in every mode except `quick`. Present four
  things:
  - the issue as you read it
  - the **kind** (bug or feature), and why you classified it that way
  - the surface map
  - your **scope estimate** (small or large, plus the file and module count)

  Wait for a go before any analysis spend. `quick` states the understanding inline and does not
  stop. The kind or the map may be wrong. Correct it from the user's feedback, because both are
  cheap. The expensive fork stays behind Gate 2.
- **Gate 2, execution plan.** It fires on a large scope, and always in `deep`. Present the fan-out
  plan and **wait for a go** before you start any subagent. This is the main token gate. The user
  can trim lenses, drop to a single pass, cap the subagent count, or change the model.
- **Gate 3, triage.** It fires on a large scope, and always in `deep`. Show the compact findings
  table (ID, category, severity, location) before you write the full report. Let the user drop the
  noise and the low-severity items.

The steps in [SKILL.md](SKILL.md) only mark *where* a gate fires. This section is the single source
for what each gate presents and who can change what.

**A small scope in `default` mode auto-proceeds** through Gates 2 and 3. Cheap work needs no
ceremony.

## Detecting the kind

Read the kind from the strongest signal available:

- **GitHub labels or issue type.** `bug` means bug. `feature`, `enhancement`, or `feature request`
  means feature. This is the most reliable signal when it is present.
- **Template.** A bug-report template means bug. A feature-request template means feature.
- **Verbs.** "broken / fails / regression / incorrect / crashes / wrong" means bug. "implement /
  add / support / introduce / new" means feature.

The signals may conflict or be absent. Then **ask at Gate 1**, because you stop there anyway. State
your best guess. The user confirms it or changes it. The kind decides the lens set
([CHECKLIST.md](CHECKLIST.md)), the finding categories, and the report variant
([TEMPLATES.md](TEMPLATES.md)). Everything else runs the same.

## Gate 2: the plan format

Present the plan like this and wait for a go:

```
Scope:     large (surface = 14 files, 3 modules)
Mode:      lens fan-out
Lenses:    correctness, concurrency, data-integrity, error-handling
           [skipping: security (no untrusted input), perf (not a hot path)]
Subagents: 4   (model: sonnet)
```
