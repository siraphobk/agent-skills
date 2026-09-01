---
name: write-skill
allowed-tools: Read Write Edit Grep Glob
description: Author a new skill or rework an existing one so it matches this setup's house conventions — trigger-rich description, numbered Workflow, hard Constraints list, approval gates before anything is written or pushed, and a bundled worked example that calibrates output density. Confirms the shape (name, description, section list, bundled files) before writing, then drafts the files and presents them for review. Use when the user says "write a skill", "create a skill", "make a new skill", "turn this into a skill", "fix this skill", "this skill isn't triggering", or asks where a repeatable procedure should live. NOT for running evals, benchmarks, or description-optimization scripts — the skill-creator plugin owns that loop. NOT for one-off preferences or non-negotiable policy — a preference belongs in your agent's instructions file, a MUST/never belongs in a rules file.
---

# Write Skill

A skill is a repeatable multi-step procedure. A preference is not a skill. A
preference goes to your agent's user-level instructions file, to a memory
fragment, or to a rules file. Check that first.

The sibling skills are the real spec. Read one before you write a draft.

| Sibling skill | What it shows |
|---|---|
| `write-plan` | A bundled template plus a worked example |
| `execute-plan` | A loop with gates |
| `analyze-issue` | Modes |
| `github-pr-create` | A tool-driven workflow |

## Workflow

1. **Pin the job.** Which procedure repeats? What triggers it? Does the skill
   write files, call tools, or only reason? Which skill runs after it, and which
   skill runs before it? If it overlaps an existing skill, name that skill and
   explain how the two differ. One skill that covers a job beats two skills that
   each half-cover it.

2. **Gate. Confirm the shape before you write.** Present one short block. The
   block shows the name, the draft description, the section list, and any
   bundled files. Wait for the user to approve. A wrong name or a redundant
   skill is cheap to catch here. It is expensive to catch after a full draft.

3. **Draft the files.** Write `<name>/SKILL.md` in your agent's skills
   directory. Add bundled files only when they earn their place. See *Shape*.
   Then present a summary for review. The summary says what each section does
   and which calls are still open. Do not paste the whole file back.

4. **Revise and confirm.** Fix what the user flags. Present the result again.
   The skill ends at the files. Do not use the new skill unless the user asks.

## Shape

```
<name>/
├── SKILL.md        # required — under 150 lines
├── TEMPLATES.md    # the exact output shape, if the skill produces a document
├── EXAMPLES.md     # one worked example at the right density
└── scripts/        # only for deterministic work (parsing, validation, file I/O)
```

**SKILL.md** holds these parts, in this order:

- Frontmatter: `name`, `description`, optional `argument-hint`, optional
  `allowed-tools`
- `# Title`
- Two lines of framing
- `## Workflow` as numbered steps
- `## Constraints` as MUST/never bullets

Add another section only when the skill genuinely needs it.

**The agent sees only the description when it picks a skill.** Keep it to 1024
characters or fewer, in the third person. Put what the skill does first. Then
put the trigger phrases a user would really type. Then put the boundary, in the
form `NOT for X (use Y)`. Every sibling skill here ends with that boundary line.
Without it, two skills fight over the same request.

**Bundle a worked example whenever output density matters.** Rules describe the
output. Examples calibrate it, and the example wins. A thin example teaches thin
output, whatever the rules say. Add a `too coarse vs. right` contrast when the
failure mode is vagueness.

**Write the body in Simplified Technical English.**

- Write the whole skill body in ASD-STE100 Simplified Technical English.
- Keep each sentence to 20 words or fewer. Use active voice and simple tenses.
- Do not use contractions, semicolons, em dashes, or phrasal verbs.
- Use one name for each thing. Do not rotate synonyms.
- Leave the frontmatter `description:` as it is. It is trigger text for the
  skill matcher, not prose.

## Constraints

- **Gate before the first file.** Step 2's shape confirmation is not optional.
- **Delegate. Do not duplicate.** Point at the file that owns the mechanics.
  Use `update-config` for hooks and settings. Use your agent's instructions file
  for code style and test policy. Use the git rules for commit and push. If you
  copy their content into a new skill, the two copies drift apart.
- **Name the handoff.** End the workflow with the next skill to run. Recommend
  that skill. Never invoke it. Say which skill feeds this one, if any skill does.
- **Stop for approval before any outward-facing action.** Such an action is a
  write to the user's repo, a push, a new PR, or a post anywhere. State this
  rule in Constraints, in the skill's own words.
- **`allowed-tools` must cover what the skill actually does.** A skill that
  writes files needs `Write`. A skill that reads a bundled file needs `Read`. A
  missing entry causes a silent failure at the worst moment. `allowed-tools` is
  required, not optional. A skill without it is rejected before it ships.
- **Scratch output goes to `.agents/scratch/<kind>/`** in the target repo. Name
  each file `YYYY-MM-DD-<kebab-slug>`. Never write scratch to `/tmp` or the repo
  root.
- **Write it the way you want to read it.** Use 6th-grade words. Give the why
  before the what. Name a concrete path instead of "the relevant file".
- **Keep it under 150 lines, or split it.** Extra content goes to a bundled
  file, one level deep. Never add a second hop. Every skill here fits. If a
  draft does not fit, look at the extra content. It is almost always an output
  template, an API payload shape, or a block of tool mechanics. Each of those
  wants its own bundled file anyway. Move them before you ask for an exception.
- **No dates, versions, or "currently".** A skill that ages is a skill that lies.
- **Draft to the budget.** When a target has a stated size limit, write to that
  limit on the first pass. A long draft that you then trim wastes edits and
  still lands over the limit. If the content genuinely needs the space, say so
  and pass the limit on purpose. Do not discover the overflow four edits later.
- **When you rework an existing skill,** read every file in it first. Then check
  what else references it. Grep your skills directory for `<name>`. Skills point
  at each other. A rename or a changed section title breaks the pointer with no
  warning. Read the counterpart skill too. The counterpart is the skill that
  consumes this one's output, or the skill that feeds it. Half the real defects
  live in the gap between the pair, not inside either file.
- **Audit before you add.** A rework does more than add. Ask which existing
  sections anybody has ever used. A section nobody fills costs tokens on every
  run. Propose a cut in the same message as an addition.

**For evals, benchmarks, or description tuning,** use the `skill-creator`
plugin. It runs test prompts, grades results, and optimizes the trigger line.
This skill stops at a well-shaped draft.
