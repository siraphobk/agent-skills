# Issue Templates — the output shapes

Three literal shapes [SKILL.md](SKILL.md) fills in. Every branch about *which* shape to use lives
in SKILL.md; this file only holds the shapes themselves.

## Default issue body (no repo template)

Used when Step 1 found nothing in `.github/ISSUE_TEMPLATE/`. Drop the sections that don't apply
to the kind of issue — a feature request with an empty "Steps to reproduce" reads worse than one
without the heading.

```markdown
## Description
<what + why>

## Steps to reproduce
<bugs only — numbered list>

## Expected behavior
<bugs only>

## Actual behavior
<bugs only>

## Acceptance criteria
<features only — bullet list>

## Additional context
<links, screenshots, related issues; or "None">
```

## Draft file wrapper

Written to `.agents/scratch/draft-issues/{filename}`. The metadata sits in the header so the user
can check labels and assignee without reading the body.

```markdown
# Issue Draft

**Title:** {title}
**Template:** {template name or "none"}
**Labels:** {labels or "none"}
**Assignee:** {assignee or "none"}
**Type:** {issue type or "none"}

---

{issue body}
```

## Confirm block

Printed in chat once the draft file is written. Stop here — Step 5 validates the labels only
after the user says go.

```
Draft written to .agents/scratch/draft-issues/{filename}
Title: {title}
Template: {template}
Labels: {labels}

Review the draft. Say "looks good" or "create the issue" to proceed,
or tell me what to change.
```
