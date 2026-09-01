# CONTEXT.md Format

## Structure

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
{A one or two sentence description of the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

## Rules

| Rule | What to do |
|---|---|
| **Be opinionated.** | Pick the best word for a concept. List the other words as aliases to avoid. |
| **Flag conflicts explicitly.** | Record an ambiguous term under "Flagged ambiguities" with a clear resolution. |
| **Keep definitions tight.** | One or two sentences at most. Define what the term IS, not what it does. |
| **Show relationships.** | Use bold term names. State the cardinality where it is obvious. |
| **Include only terms specific to this project's context.** | Exclude general programming concepts. See the notes below. |
| **Group terms under subheadings.** | Group them when natural clusters emerge. |
| **Write an example dialogue.** | Show a dev and a domain expert who use the terms. |

Notes on the table above:

- A general programming concept does not belong, even when the project uses it a lot. Timeouts, error types, and utility patterns are examples.
- Ask one question before you add a term. Is this concept unique to this context, or is it a general programming concept? Only a concept unique to this context belongs.
- A flat list is fine when all terms belong to a single cohesive area.
- The dialogue shows how the terms interact naturally. It also clarifies the boundaries between related concepts.

## Single vs multi-context repos

**Single context (most repos):** One `CONTEXT.md` at the repo root.

**Multiple contexts:** Put a `CONTEXT-MAP.md` at the repo root. It lists the contexts, where they live, and how they relate to each other:

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md) — generates invoices and processes payments
- [Fulfillment](./src/fulfillment/CONTEXT.md) — manages warehouse picking and shipping

## Relationships

- **Ordering → Fulfillment**: Ordering emits `OrderPlaced` events; Fulfillment consumes them to start picking
- **Fulfillment → Billing**: Fulfillment emits `ShipmentDispatched` events; Billing consumes them to generate invoices
- **Ordering ↔ Billing**: Shared types for `CustomerId` and `Money`
```

The skill infers which structure applies:

- If a `CONTEXT-MAP.md` exists, read it to find the contexts.
- If only a root `CONTEXT.md` exists, the repo has a single context.
- If neither file exists, create a root `CONTEXT.md` lazily when the first term resolves.

When multiple contexts exist, infer which one the current topic relates to. If it is unclear, ask
the user.
