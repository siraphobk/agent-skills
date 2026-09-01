# Issue Templates: the output shapes

This file holds three literal shapes that [SKILL.md](SKILL.md) fills in. Every branch about
*which* shape to use lives in SKILL.md. This file holds only the shapes themselves.

## Default issue body (no repo template)

Use this shape when Step 1 found nothing in `.github/ISSUE_TEMPLATE/`. Remove the sections that
do not apply to the kind of issue. A feature request with an empty "Steps to reproduce" reads
worse than one without the heading.

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

Write this shape to `.agents/scratch/draft-issues/{filename}`. The metadata sits in the header.
The user can check the labels and the assignee there, and does not need to read the body.

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

Print this block in chat after you write the draft file. Stop here. Step 5 validates the labels
only after the user agrees.

```
Draft written to .agents/scratch/draft-issues/{filename}
Title: {title}
Template: {template}
Labels: {labels}

Review the draft. Say "looks good" or "create the issue" to proceed,
or tell me what to change.
```
