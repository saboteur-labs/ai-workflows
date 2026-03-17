---
title: Break a spec into tasks
category: planning
tags: [tasks, breakdown, planning, estimation, sprint, kanban]
context_budget: low
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2025-01-01
      note: Initial version
---

# Break a spec into tasks

Takes a feature spec and produces a prioritised, estimated task list where
each task is independently executable in a single AI session or developer
work block. The output is the input for sequential `implement-feature`
skill sessions.

Use this immediately after `planning/write-feature-spec.md` and before any
implementation begins. A well-decomposed task list is what makes a
multi-session implementation pipeline reliable — each task has a clear
input, output, and done condition.

## When to use

- You have a reviewed feature spec and are ready to plan implementation
- You want to estimate effort before committing to a feature
- You're setting up a multi-session implementation pipeline
- NOT before the spec is reviewed — decomposing a flawed spec produces a
  flawed task list that propagates errors into implementation
- NOT for tasks so small they don't need decomposition (a single function
  change doesn't need a task list)

## Interfaces

| Interface | Notes                                                                                        |
| --------- | -------------------------------------------------------------------------------------------- |
| IDE       | Good fit — paste the spec and get a task list you can track in a project file.               |
| Chat      | Ideal for iterative refinement: "Make task 3 more specific" / "Split task 5 into two tasks." |
| CLI       | Pipe the spec file: `cat spec.md \| your-model-cli --prompt break-into-tasks.md`             |
| API       | Use for automated pipeline setup. Parse the task list for downstream session orchestration.  |

## Prompt

```
Break the following feature spec into an implementation task list.

Spec:
{{SPEC}}

Granularity: {{GRANULARITY}}

Rules for each task:
1. Each task must be executable in a single focused session — one concern,
   one area of the codebase, one logical unit of work.
2. Each task must have a clear done condition: a specific, verifiable state
   that is unambiguously true or false.
3. Tasks must be ordered by dependency — a task that depends on another
   comes after it.
4. Do not create tasks for things outside the spec's functional requirements.
   Non-goals stay non-goals.

Output format — one entry per task:

### Task N: [short title]
**What:** [one sentence — what this task produces]
**Files:** [files to create or modify, or "TBD if unknown"]
**Done when:** [specific, verifiable condition]
**Depends on:** [task numbers this task requires, or "none"]
**Estimate:** [{{GRANULARITY}} — your estimate for this task]
**Notes:** [assumptions, risks, or implementation hints. Omit if none.]

After the task list, add:

## Summary
- Total tasks: N
- Total estimated effort: [sum]
- Critical path: [the sequence of dependent tasks that determines minimum
  elapsed time, e.g. "Tasks 1 → 3 → 5 → 6"]
- Risks: [any tasks with high uncertainty or dependency risk]
```

### Placeholders

| Placeholder       | Description                           | Example                                                                                      |
| ----------------- | ------------------------------------- | -------------------------------------------------------------------------------------------- |
| `{{SPEC}}`        | The feature spec to decompose         | _(paste spec contents)_                                                                      |
| `{{GRANULARITY}}` | Desired task size and estimation unit | `half-day tasks, estimated in hours`, `story points (1/2/3/5/8)`, `T-shirt sizes (S/M/L/XL)` |

## Low-context variant

This prompt is already `context_budget: low`. If the spec is very long
(over ~600 words), summarise it first:

```
Summarise this spec as a bullet list of functional requirements only,
maximum 15 bullets:

{{SPEC}}
```

Then use the summary as `{{SPEC}}` in the main prompt.

## Notes & tips

- The "Done when" condition is the most important field. If the model
  produces vague done conditions ("the feature works correctly"), push back:
  "Rewrite the done condition for task 3 as a specific, verifiable state."
- For tasks that touch shared infrastructure (database schema, auth
  middleware), list them first — they are usually on the critical path.
- If the task list has more than ~10 tasks, the feature may be too large
  for one implementation cycle. Consider splitting the spec into a
  smaller first iteration and a deferred iteration.
- The task list is the natural input for a `human-in-the-loop` review gate
  before implementation begins. Reorder or split tasks at this point — it's
  cheaper than discovering the wrong order mid-implementation.
- Related prompts:
  [`planning/write-feature-spec.md`](./write-feature-spec.md),
  [`planning/estimate-complexity.md`](./estimate-complexity.md),
  [`agent-orchestration/decompose-task.md`](../agent-orchestration/decompose-task.md)
- Related skills:
  [`skills/coding/implement-feature/`](../../skills/coding/implement-feature/)
