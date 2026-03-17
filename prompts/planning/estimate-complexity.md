---
title: Estimate complexity and risk
category: planning
tags: [estimation, complexity, risk, sizing, planning, effort]
context_budget: low
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2025-01-01
      note: Initial version
---

# Estimate complexity and risk

Produces a structured complexity and risk assessment for a described piece
of work. Gives you a reasoned estimate with explicit assumptions and risk
factors — not just a number, but the reasoning behind it.

Use this before committing to a feature or task to calibrate expectations,
identify risks early, and decide whether decomposition is needed. Also
useful for sanity-checking estimates produced by `break-into-tasks.md`.

## When to use

- Before committing to a sprint or milestone, to pressure-test estimates
- When a task feels larger or riskier than it first appeared
- To identify which tasks in a list have the most uncertainty
- NOT as a substitute for `break-into-tasks.md` — estimates produced here
  are coarse; use that prompt for per-task estimates
- NOT for tasks you've already fully implemented — assess before, not after

## Interfaces

| Interface | Notes                                                                       |
| --------- | --------------------------------------------------------------------------- |
| IDE       | Useful as a quick pre-task check before starting an implementation session. |
| Chat      | Good for iterative refinement: "What would reduce the risk of item 2?"      |
| CLI       | Pipe a task or spec description for a quick estimate.                       |
| API       | Use for automated risk flagging in planning pipelines.                      |

## Prompt

```
Assess the complexity and risk of the following work.

Work description:
{{WORK_DESCRIPTION}}

{{#if CODEBASE_CONTEXT}}
Codebase context:
{{CODEBASE_CONTEXT}}
{{/if}}

Estimation scale: {{SCALE}}

Produce a structured assessment:

## Complexity estimate
**Estimate:** [your estimate on the {{SCALE}} scale]
**Confidence:** [high / medium / low]

**Reasoning:**
[2–4 sentences explaining the key factors driving the estimate. Be specific
about what makes this work more or less complex.]

## Risk factors
For each risk, rate it: [high / medium / low] likelihood × impact.

| Risk | Likelihood | Impact | Notes |
|------|-----------|--------|-------|
| [risk description] | H/M/L | H/M/L | [what would trigger it, how to mitigate] |

Identify at least:
- One technical risk (implementation unknowns, dependency behaviour, etc.)
- One scope risk (what could expand the work beyond the estimate)

If no meaningful risks exist, explain why.

## Assumptions
[Bullet list of assumptions made in producing the estimate. These are the
conditions that must be true for the estimate to hold. If any assumption
is wrong, the estimate changes.]

## Decomposition recommendation
Should this work be broken into smaller tasks before starting?
- **No** — scope is clear, risks are manageable, proceed as one task
- **Yes** — describe the recommended split in 2–3 bullet points

## Flags
[Any specific concerns that should be raised with a human before
proceeding. Write "None" if the work can proceed without escalation.]
```

### Placeholders

| Placeholder            | Description                                                                                                                                  | Example                                                                                          |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `{{WORK_DESCRIPTION}}` | The work to assess — a task, spec, or plain description                                                                                      | _(paste task description or spec)_                                                               |
| `{{CODEBASE_CONTEXT}}` | Optional. Relevant facts about the codebase that affect the estimate (stack, existing patterns, known debt). Remove the block if not needed. | `Node.js/Express API. No ORM — raw SQL with pg. Test coverage is sparse in the payments module.` |
| `{{SCALE}}`            | The estimation scale to use                                                                                                                  | `T-shirt sizes (S/M/L/XL)`, `story points (1/2/3/5/8/13)`, `days of effort`                      |

## Low-context variant

This prompt is already `context_budget: low`. No low-context variant needed.

## Notes & tips

- Low confidence on a medium estimate is more informative than high
  confidence on a large estimate. If the model marks confidence as low,
  that's a signal to investigate before committing.
- The assumptions list is the most actionable output — each assumption is
  something you can verify or challenge before starting. "Assumes the
  existing auth middleware can be reused" is something you can check in
  5 minutes.
- If the decomposition recommendation says "Yes", use `break-into-tasks.md`
  before proceeding rather than estimating individual sub-tasks here.
- For a task list from `break-into-tasks.md`, run this prompt once per task
  marked "high uncertainty" or with a large estimate — it surfaces risks
  that the task list format doesn't capture.
- Related prompts:
  [`planning/break-into-tasks.md`](./break-into-tasks.md),
  [`planning/write-feature-spec.md`](./write-feature-spec.md)
