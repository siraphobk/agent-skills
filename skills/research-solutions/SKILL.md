---
name: research-solutions
allowed-tools: Read Write Grep Glob Task WebSearch WebFetch Bash(kubectl *) Bash(mkdir *) Bash(date *)
description: >
  Research and ideation for a problem or requirement. Distills the requirement (goals, non-goals,
  constraints, assumptions), classifies the problem type, then researches outward (RFCs, standards,
  vendor docs, open source, prior art) and inward (our codebase, k8s manifests, asking the user) to
  produce 3+ distinct approaches with integration points, failure modes, limits, effort, and
  cost-to-reverse. Gates twice — on the requirement, then on option sketches in chat — before
  writing a 4-file report under .agents/scratch/solution-research/. Use when the user says "research
  how to do X", "how should I solve this", "brainstorm ideas for X", "what's the industry standard
  for X", or brings a requirement from the product team. NOT for a full build-map survey of our
  codebase (use analyze-issue; this reads our code only far enough to judge an option), NOT for
  writing the implementation plan (use write-plan), NOT for stress-testing an existing plan (use
  grill-me). Optional arg: mode "quick"|"default"|"deep".
argument-hint: "[quick|default|deep]"
---

# Research Solutions

Two directions at once: what the world already does, and what our own system can actually support.
The deliverable is **options and evidence** — not a plan, not code.

## Modes

| Mode | When | Behavior |
|---|---|---|
| `quick` | small, well-bounded problem | Single-pass, no subagents, 2+ approaches, **chat only — no files**. Offer a `write-plan` handoff if it should be saved. |
| `default` *(or none)* | normal use | Both gates, 3+ approaches, writes the 4-file report. Fan-out only if the surface is broad. |
| `deep` | epic, or high cost-to-reverse | Wider sweep — more vendors, more standards, explicit build-vs-buy. Fan-out expected. Writes the report. |

## Gates

Two stops, both **before** the spend they authorize. Gate 1 is cheap insurance — researching the
wrong problem is the expensive mistake. Gate 2 stops a full writeup landing on an approach you would
have rejected in seconds.

- **Gate 1 — Requirement & research plan** (after Step 2). Present the distilled requirement, the
  problem type and why, and the research plan — sources you'll go to, what you'll read in our own
  system, and any subagent fan-out. Wait for go before research spend.
- **Gate 2 — Option sketches** (after Step 3). Present 3+ sketches, two lines each, and the
  questions for product. The user picks which to develop. Write no files before this.

`quick` states both inline and keeps going.

## Workflow

**Step 1 — Distill the requirement.** What product hands you is never complete. Turn it into the
**Requirement** block in [TEMPLATES.md](TEMPLATES.md) — goal, non-goals, constraints, assumptions,
success signal. Non-goals and assumptions do the real work here: non-goals name the nearby things
people will otherwise assume are included, and every assumption becomes a question for product.

Ask at most one round of questions, only for what is missing *and* blocks the work. Everything else
becomes an assumption or an open question — distill, don't interview.

**Step 2 — Classify the problem type.** Pick from [LENSES.md](LENSES.md) and say why. The type sets
the questions that must be answered, where outside standards live, where **our own** evidence lives,
and the failure modes every approach has to cover. If more than one applies, name primary and
secondary.

**Gate 1 fires here** — see *Gates*.

**Step 3 — Research, both directions.** Neither alone is enough: industry standard with no idea what
our system can support produces approaches nobody can build.

*Outward* — stop when there is enough to sketch options:

1. **Normative** — RFCs, specs, formal standards.
2. **Official** — vendor docs and API references. For a library or SDK, prefer the context7 MCP.
3. **Prior art** — how known players and respected open source actually do it.
4. **Practitioner** — engineering blogs, conference talks, postmortems.

*Inward* — go only as deep as judging the option needs:

- **Code-shaped ideas** — Glob/Grep/Read the real code. Find the seams an approach would hang off,
  the patterns already in use, and whatever quietly rules an option out.
- **Architecture-shaped ideas** — read the k8s manifests and infra config. For runtime facts of a
  running service, read the live cluster, not the chart (`brain/cautionary/k8s-live-not-chart.md`).
- **Neither** — ask the user. Team shape, roadmap, vendor relationships, and past decisions are not
  in the repo, and guessing at them wastes the whole run.

Grade every claim as you collect it (scale in [TEMPLATES.md](TEMPLATES.md)). A claim you cannot
source is an inference — label it, don't launder it.

**Step 4 — Checkpoint.** Gate 2 fires — see *Gates*.

**Step 5 — Develop and deliver.** Build the chosen approaches to the depth
[TEMPLATES.md](TEMPLATES.md) sets, then write its four files to
`<repo-root>/.agents/scratch/solution-research/<YYYY-MM-DD>-<kebab-slug>/`. Date source:
`currentDate` from global memory if present, else `date +%Y-%m-%d`. Show the options table and the
directory path in chat.

## Constraints

- **Three genuinely different approaches, or say why not.** Variations of one idea are one idea. If
  the problem honestly has a single sane answer, say so and name what rules the others out — never
  pad to three.
- **Keep the rejects.** An approach considered and dropped stays in `03-approaches.md` with the
  reason. That is the standing answer to "did you consider X?".
- **Grade every claim.** No ungraded assertion in the report. Anything the recommendation leans on
  that is only community-grade or inference goes in the unverified list in `04-references.md`.
- **Never invent a source.** No URL you did not fetch, no API behavior you did not read. "I could
  not confirm this" is a valid and useful finding.
- **Prove every claim about our own system.** `file:line` for code, a resource name for infra. A
  grep that matched nothing is not proof a thing is absent — see
  `brain/cautionary/empty-grep-not-evidence.md`. An unproven feasibility claim is the most expensive
  kind of wrong here, because the whole approach rests on it.
- **Recon, not survey.** Read our code only far enough to judge whether an option is real. The full
  build map — every seam, every caller, every pattern to follow — is `analyze-issue`'s job. Doing it
  here spends two runs on one job.
- **Keep internals out of search queries.** Search the generic shape of the problem. Customer names,
  internal service names, private identifiers, and unreleased product details never go into a web
  search or a third-party tool.
- **Filter to what we can actually build.** Score approaches against the Tech Profile in
  your agent's user-level instructions file *and* against what the recon found. If the best option is still one the team
  cannot build today, say so and name what adopting it would cost.
- **Size at AI pace.** Effort in agent-days, following the Character notes in the brain index.
- **Ask before fan-out.** Subagents are proposed at Gate 1 and spawned only after go —
  `rules/spawning-subagents.md` holds here with no exception.
- **No code, no phases.** Pseudocode and interface sketches are fine. Implementation is not, and
  neither is a phased rollout — that is `write-plan`.
- **Next step:** recommend `analyze-issue` to turn the chosen approach into a full build map, then
  `write-plan` pointed at the report directory and the chosen `A-NN`. The distilled goal and
  non-goals from Step 1 carry straight into the plan. The full chain is **research-solutions →
  analyze-issue → write-plan → execute-plan**. Recommend it; never invoke it automatically.
