# ADR Format

ADRs live in `docs/adr/`. They use sequential numbers: `0001-slug.md`, `0002-slug.md`, and so on.

Create the `docs/adr/` directory lazily. Create it only when you need the first ADR.

## Template

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

That is all. An ADR can be a single paragraph. The value is the record *that* a decision was made, and *why*. The value does not come from completed sections.

## Optional sections

Include these only when they add genuine value. Most ADRs do not need them.

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`). Use it when you revisit decisions.
- **Considered Options**. Use it only when the rejected alternatives are worth remembering.
- **Consequences**. Use it only when you must state non-obvious downstream effects.

## Numbering

Scan `docs/adr/` for the highest existing number and increment by one.

## When to offer an ADR

All three of these must be true:

1. **Hard to reverse.** A later change of mind costs something meaningful.
2. **Surprising without context.** A future reader will read the code and wonder "why on earth did they do it this way?"
3. **The result of a real trade-off.** There were genuine alternatives. You picked one for specific reasons.

If a decision is easy to reverse, skip it. You will just reverse it. If it is not surprising, nobody will wonder why. If there was no real alternative, there is nothing to record beyond "we did the obvious thing."

### These decisions qualify

| Kind | Example |
|---|---|
| **Architectural shape.** | "We're using a monorepo." |
| **Integration patterns between contexts.** | "Ordering and Billing communicate via domain events, not synchronous HTTP." |
| **Technology choices that carry lock-in.** | Database, message bus, auth provider, deployment target. |
| **Boundary and scope decisions.** | "Customer data is owned by the Customer context; other contexts reference it by ID only." |
| **Deliberate deviations from the obvious path.** | "We're using manual SQL instead of an ORM because X." |
| **Constraints not visible in the code.** | "We can't use AWS because of compliance requirements." |
| **Rejected alternatives when the rejection is non-obvious.** | You considered GraphQL and picked REST for subtle reasons. |

Notes on the table above.

**Architectural shape** also covers this example: "The write model is event-sourced, the read model is projected into Postgres."

**Technology choices** do not cover every library. They cover the ones that would take a quarter to replace.

**Boundary and scope decisions** include the explicit no-s. Those are as valuable as the yes-s.

**Deliberate deviations** are the cases where a reasonable reader would assume the opposite. The record stops the next engineer from "fixing" something that was deliberate.

**Constraints not visible in the code** also cover this example: "Response times must be under 200ms because of the partner API contract."

**Rejected alternatives** need a record when the rejection is non-obvious. Otherwise someone will suggest GraphQL again in six months.
