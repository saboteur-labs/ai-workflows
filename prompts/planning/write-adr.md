---
title: Write an Architecture Decision Record
category: planning
tags: [adr, architecture, decision, documentation, design, trade-offs]
context_budget: low
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2025-03-17
      note: Initial version
---

# Write an Architecture Decision Record

Produces a structured Architecture Decision Record (ADR) documenting a
technical decision — the context that drove it, the options considered, the
decision made, and its consequences. ADRs create a durable record of why
the codebase is the way it is.

Use this when making a significant technical decision that future developers
(including you, six months from now) would benefit from understanding. The
output is a markdown file suitable for committing to the repo alongside
the code it governs.

## When to use

- Choosing between two or more meaningfully different technical approaches
- Adopting or rejecting a dependency, framework, or pattern
- Establishing a convention that will apply across the codebase
- Reversing or superseding a previous decision
- NOT for minor implementation choices that don't affect the architecture
- NOT when the decision hasn't been made yet — use `write-feature-spec.md`
  to explore options, then document the chosen one here

## Interfaces

| Interface | Notes                                                                                            |
| --------- | ------------------------------------------------------------------------------------------------ |
| IDE       | Good fit — produce the ADR file directly in the project's `docs/decisions/` or `adr/` directory. |
| Chat      | Ideal for iterative refinement of the consequences section, which often needs a few passes.      |
| CLI       | Pipe a brief description and get a draft ADR to refine.                                          |
| API       | Use to auto-generate ADR drafts from structured decision data.                                   |

## Prompt

```
Write an Architecture Decision Record for the following decision.

Decision: {{DECISION}}

Context:
{{CONTEXT}}

Options considered:
{{OPTIONS}}

Write the ADR in this format:

# ADR-NNN: {{DECISION_TITLE}}

**Date:** {{DATE}}
**Status:** Accepted

## Context
What is the situation or problem that necessitated this decision? Include
relevant constraints, requirements, and the state of the system at the
time of the decision. Do not describe the decision itself here — only the
circumstances that made it necessary.

## Options considered

For each option provided, write a subsection:
### Option N: [option name]
[One paragraph describing the option]
**Pros:** [bullet list]
**Cons:** [bullet list]

## Decision
State the decision made in one sentence. Then explain the reasoning:
why this option over the others? What factors were most important?

## Consequences
### Positive
[Bullet list of beneficial outcomes of this decision]

### Negative
[Bullet list of costs, trade-offs, or risks accepted by this decision.
Be honest — every decision has costs. An ADR with no negative consequences
is incomplete.]

### Neutral
[Bullet list of things that change but are neither clearly good nor bad]

## Revisit conditions
Under what circumstances should this decision be revisited? What would
have to be true for a different choice to become correct?

Rules:
- Be specific and concrete. "Better performance" is not useful.
  "Reduces p99 latency on the export endpoint from ~2s to ~200ms" is.
- The Negative consequences section must be non-empty. Every decision
  has costs.
- Write in past tense for Context (what was true), present tense for
  Consequences (what is now true as a result).
- Do not use jargon without defining it.
```

### Placeholders

| Placeholder          | Description                                                            | Example                                                                                                                                                                            |
| -------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `{{DECISION}}`       | Plain-language statement of the decision made                          | `Use PostgreSQL instead of MongoDB for the new user activity service`                                                                                                              |
| `{{DECISION_TITLE}}` | Short title for the ADR heading                                        | `Use PostgreSQL for user activity storage`                                                                                                                                         |
| `{{DATE}}`           | Date of the decision                                                   | `2025-01-15`                                                                                                                                                                       |
| `{{CONTEXT}}`        | Background: why was this decision necessary? What constraints existed? | `We need to store structured user activity events with complex query requirements. The team has strong SQL expertise. Budget limits us to self-hosted solutions.`                  |
| `{{OPTIONS}}`        | The options that were considered, as a list or short descriptions      | `1. PostgreSQL — relational, strong query support, team expertise. 2. MongoDB — flexible schema, horizontal scaling. 3. SQLite — simple, no ops overhead but limited concurrency.` |

## Low-context variant

This prompt is already `context_budget: low`. No low-context variant needed.

## Notes & tips

- The "Revisit conditions" section is often skipped but is one of the most
  useful parts — it prevents ADRs from becoming permanent fixtures that no
  one questions even when circumstances have changed.
- If the model produces weak negative consequences ("slightly more complex
  setup"), push back: "The negative consequences section needs to be more
  specific. What are the actual trade-offs accepted by choosing PostgreSQL
  over MongoDB for this use case?"
- ADRs work best when numbered sequentially and stored in a dedicated
  directory (`docs/decisions/`, `adr/`). Include the number in the filename:
  `0012-use-postgres-for-activity-storage.md`
- For reversing a previous decision, add a "Supersedes" field below Status:
  `**Supersedes:** ADR-007`
- Related prompts:
  [`planning/write-feature-spec.md`](./write-feature-spec.md),
  [`planning/estimate-complexity.md`](./estimate-complexity.md)
