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

This skill works in two directions at once. It finds what the world already does. It also finds
what our own system can support. The result is **options and evidence**. It is not a plan, and it
is not code.

## Modes

| Mode | When | Behavior |
|---|---|---|
| `quick` | small, well-bounded problem | One pass, no subagents, 2 or more approaches, **chat only, no files**. Offer a `write-plan` handoff if the result is worth saving. |
| `default` *(or none)* | normal use | Both gates, 3 or more approaches, writes the 4-file report. Use subagents only if the surface is broad. |
| `deep` | epic, or high cost-to-reverse | Wider sweep. More vendors, more standards, explicit build-vs-buy. Expect subagents. Writes the report. |

## Gates

There are two stops. Each one comes **before** the spend it authorizes. Gate 1 is cheap insurance,
because research on the wrong problem is the expensive mistake. Gate 2 stops a full writeup on an
approach you would have rejected in seconds.

- **Gate 1, requirement and research plan** (after Step 2). Present the distilled requirement, the
  problem type and why, and the research plan. The research plan names the sources you go to, and
  what you read in our own system. It also names any subagents you want. Wait for a go before you
  spend on research.
- **Gate 2, option sketches** (after Step 3). Present 3 or more sketches, two lines each, and the
  questions for product. The user picks which ones to develop. Write no files before this gate.

`quick` mode states both gates inline and continues.

## Workflow

**Step 1. Distill the requirement.** What product hands you is never complete. Turn it into the
**Requirement** block in [TEMPLATES.md](TEMPLATES.md). That block holds the goal, the non-goals, the
constraints, the assumptions, and the success signal. Non-goals and assumptions do the real work
here. Non-goals name the nearby things people otherwise assume are included. Every assumption
becomes a question for product.

Ask at most one round of questions. Ask only for what is missing *and* blocks the work. Everything
else becomes an assumption or an open question. Distill, do not interview.

**Step 2. Classify the problem type.** Pick a type from [LENSES.md](LENSES.md) and say why. The type
sets four things:

1. The questions that must be answered.
2. Where outside standards live.
3. Where **our own** evidence lives.
4. The failure modes every approach must cover.

If more than one type applies, name a primary and a secondary.

**Gate 1 fires here.** See *Gates*.

**Step 3. Research in both directions.** Neither direction alone is enough. If you know the industry
standard but not what our system supports, you produce approaches nobody can build.

*Outward.* Stop when you have enough to sketch options.

1. **Normative:** RFCs, specs, and formal standards.
2. **Official:** vendor docs and API references. For a library or an SDK, prefer the context7 MCP.
3. **Prior art:** how known players and respected open source actually do it.
4. **Practitioner:** engineering blogs, conference talks, and postmortems.

*Inward.* Go only as deep as you must to judge the option.

- **Code-shaped ideas.** Use Glob, Grep, and Read on the real code. Find the places an approach
  would attach to, the patterns already in use, and whatever quietly eliminates an option.
- **Architecture-shaped ideas.** Read the k8s manifests and the infra config. For runtime facts of a
  running service, read the live cluster, not the chart (`brain/cautionary/k8s-live-not-chart.md`).
- **Neither.** Ask the user. Team shape, roadmap, vendor relationships, and past decisions are not in
  the repo. A guess at them wastes the whole run.

Grade every claim as you collect it. The scale is in [TEMPLATES.md](TEMPLATES.md). A claim you
cannot source is an inference. Label it as one, and do not disguise it.

**Step 4. Checkpoint.** Gate 2 fires. See *Gates*.

**Step 5. Develop and deliver.** Build the chosen approaches to the depth that
[TEMPLATES.md](TEMPLATES.md) sets. Then write its four files to
`<repo-root>/.agents/scratch/solution-research/<YYYY-MM-DD>-<kebab-slug>/`. For the date, use
`currentDate` from global memory if it is present. If it is not, use `date +%Y-%m-%d`. Show the
options table and the directory path in chat.

## Constraints

### The options must be genuinely different

- **Give three genuinely different approaches, or say why not.** Variations of one idea are one
  idea. If the problem honestly has a single sane answer, say so and name what eliminates the
  others. Never pad the list to three.
- **Keep the rejects.** An approach you considered and dropped stays in `03-approaches.md` with the
  reason. That is the standing answer to "did you consider X?".

### Every claim must carry its evidence

- **Grade every claim.** The report holds no ungraded assertion. Anything the recommendation depends
  on that is only community-grade or inference goes in the unverified list in `04-references.md`.
- **Never invent a source.** Use no URL you did not fetch. Report no API behavior you did not read.
  "I could not confirm this" is a valid and useful finding.
- **Prove every claim about our own system.** Give a `file:line` for code, and a resource name for
  infra. A grep that matched nothing does not prove a thing is absent. See
  `brain/cautionary/empty-grep-not-evidence.md`. An unproven feasibility claim is the most expensive
  kind of wrong here, because the whole approach rests on it.

### Stay inside the research scope

- **Do recon, not a survey.** Read our code only far enough to judge whether an option is real. The
  full build map is `analyze-issue`'s job, and it covers every attachment point, every caller, and
  every pattern to follow. To do that work here spends two runs on one job.
- **Keep internals out of search queries.** Search the generic shape of the problem. Never put
  internal details into a web search or a third-party tool. That covers customer names, internal
  service names, private identifiers, and unreleased product details.
- **Filter to what we can actually build.** Score approaches against the Tech Profile in your
  agent's user-level instructions file. Score them against what the recon found as well. If the best
  option is still one the team cannot build today, say so. Name what its adoption would cost.
- **Size at AI pace.** Give effort in agent-days. Follow the Character notes in the brain index.

### Write no plan, and name the next skill

- **Ask before you spawn subagents.** Propose subagents at Gate 1, and spawn them only after a go.
  `rules/spawning-subagents.md` holds here with no exception.
- **Write no code and no phases.** Pseudocode and interface sketches are fine. Implementation is
  not, and neither is a phased rollout. That is `write-plan`.
- **Next step:** recommend `analyze-issue` to turn the chosen approach into a full build map. Then
  recommend `write-plan`, pointed at the report directory and the chosen `A-NN`. The distilled goal
  and non-goals from Step 1 carry straight into the plan. The full chain is **research-solutions →
  analyze-issue → write-plan → execute-plan**. Recommend it, and never invoke it automatically.
