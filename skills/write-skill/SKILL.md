---
name: write-skill
allowed-tools: Read Write Edit Grep Glob
description: Author a new skill or rework an existing one so it matches this setup's house conventions — trigger-rich description, numbered Workflow, hard Constraints list, approval gates before anything is written or pushed, and a bundled worked example that calibrates output density. Confirms the shape (name, description, section list, bundled files) before writing, then drafts the files and presents them for review. Use when the user says "write a skill", "create a skill", "make a new skill", "turn this into a skill", "fix this skill", "this skill isn't triggering", or asks where a repeatable procedure should live. NOT for running evals, benchmarks, or description-optimization scripts — the skill-creator plugin owns that loop. NOT for one-off preferences or non-negotiable policy — a preference belongs in your agent's instructions file, a MUST/never belongs in a rules file.
---

# Write Skill

A skill is a repeatable multi-step procedure. A preference is not a skill — that
goes to your agent's user-level instructions file, a memory fragment, or a rules
file. Check that first.

The sibling skills are the real spec. Read one before drafting: `write-plan` for
a bundled template + worked example, `execute-plan` for a loop with gates,
`analyze-issue` for modes, `github-pr-create` for a tool-driven workflow.

## Workflow

1. **Pin the job.** What procedure repeats? What triggers it? Does it write
   files, call tools, or only reason? What does it hand off to, and what hands
   off to it? If it overlaps an existing skill, say which and how they differ —
   two skills that both half-cover a job is worse than one that covers it.

2. **Gate — confirm the shape before writing.** Present in one short block: the
   name, the draft description, the section list, and any bundled files. Wait for
   go. This is the cheap place to catch a wrong name or a redundant skill; a full
   draft is not.

3. **Draft the files.** `<name>/SKILL.md` in your agent's skills directory, plus bundled files
   when they earn their place (see *Shape*). Then present a summary for review —
   what each section does and the open calls — not the whole file pasted back.

4. **Revise and confirm.** Fix what the user flags, re-present. The skill ends
   at the files; don't start using the new skill unless asked.

## Shape

```
<name>/
├── SKILL.md        # required — under 150 lines
├── TEMPLATES.md    # the exact output shape, if the skill produces a document
├── EXAMPLES.md     # one worked example at the right density
└── scripts/        # only for deterministic work (parsing, validation, file I/O)
```

**SKILL.md** — frontmatter (`name`, `description`, optional `argument-hint`,
optional `allowed-tools`), `# Title`, a two-line framing, `## Workflow` as
numbered steps, then `## Constraints` as MUST/never bullets. Extra sections only
when the skill genuinely needs them.

**The description is the only thing the agent sees** when picking a skill. Max
1024 chars, third person. First what it does, then the trigger phrases a user
would actually type, then the boundary: `NOT for X (use Y)`. Every sibling skill
here ends with that boundary line — without it two skills fight over the same
request.

**Bundle a worked example whenever output density matters.** Rules describe;
examples calibrate — and the example wins. A thin example teaches thin output no
matter what the rules say. Pair it with a `too coarse vs. right` contrast when
the failure mode is vagueness.

## Constraints

- **Gate before the first file.** Step 2's shape confirmation is not optional.
- **Delegate, don't duplicate.** Point at whoever owns the mechanics —
  `update-config` for hooks and settings, your agent's instructions file for code
  style and test policy, the git rules for commit and push. Copying their content
  into a new skill guarantees the two drift apart.
- **Name the handoff.** End the workflow with the next skill to run — recommend
  it, never invoke it. Say which skill feeds this one, if any.
- **Anything outward-facing stops for approval.** Writing to the user's repo,
  pushing, opening a PR, posting anywhere. Say so in Constraints, in the skill's
  own words.
- **`allowed-tools` must cover what the skill actually does.** A skill that
  writes files needs `Write`; one that reads a bundled file needs `Read`. A
  missing entry is a silent failure at the worst moment. It is required, not
  optional — a skill without it is rejected before it ships.
- **Scratch output goes to `.agents/scratch/<kind>/`** in the target repo, named
  `YYYY-MM-DD-<kebab-slug>`. Never write scratch to `/tmp` or the repo root.
- **Write it the way you'd want it read** — 6th-grade vocab, why over what,
  concrete paths over "the relevant file".
- **Under 150 lines, or split.** Overflow goes to a bundled file, one level deep.
  Never a second hop. Every skill here fits. If a draft doesn't, the overflow is almost always
  an output template, an API payload shape, or a block of tool mechanics — each of which wants
  its own bundled file anyway. Move those before asking for an exception.
- **No dates, versions, or "currently".** A skill that ages is a skill that lies.
- **Draft to the budget.** When a target has a stated size limit, write to it on
  the first pass. Writing long and trimming burns edits and still lands over. If
  the content genuinely needs the space, say so and blow the budget on purpose —
  don't discover it four edits later.
- **Reworking an existing skill:** read every file in it first, and check what
  else references it — grep your skills directory for `<name>`. Skills point at each other;
  a rename or a changed section title breaks the pointer silently. Read the
  counterpart too — the skill that consumes this one's output, or feeds it. Half
  the real defects live in the gap between the pair, not inside either file.
- **Audit before you add.** A rework is not only additive. Ask which existing
  sections have ever been used; a section nobody fills is costing tokens on every
  run. Propose cutting it in the same breath as adding.

**For evals, benchmarks, or description tuning**, hand off to the `skill-creator`
plugin — it runs test prompts, grades results, and optimizes the trigger line.
This skill stops at a well-shaped draft.
