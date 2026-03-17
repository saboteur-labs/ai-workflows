---
title: Decompose a complex task into sub-tasks
category: agent-orchestration
tags: [decompose, planning, agent, orchestration, subtasks, pipeline]
context_budget: low
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2025-01-01
      note: Initial version
---

# Decompose a complex task into sub-tasks

Breaks a complex or ambiguous task into independently executable sub-tasks,
each suitable for a single agent session. Designed for tasks that are too
large or multi-concern for one session, but haven't yet been through formal
spec and planning.

Use this when a task is clearly too large to execute directly but doesn't
need the full spec-writing process. For tasks that need a proper feature
spec first, use `planning/write-feature-spec.md` followed by
`planning/break-into-tasks.md` instead.

## When to use

- A task is described informally and needs to be split before execution
- A task spans multiple files, concerns, or sessions
- You're setting up a quick multi-session pipeline without a formal spec
- NOT as a replacement for `break-into-tasks.md` when a reviewed spec
  exists — that prompt produces more structured output from formal input
- NOT for tasks that are already well-scoped and executable in one session

## Interfaces

| Interface | Notes                                                                                               |
| --------- | --------------------------------------------------------------------------------------------------- |
| IDE       | Good for ad-hoc task planning before starting an implementation session.                            |
| Chat      | Best interface — conversational refinement works well here.                                         |
| CLI       | Pipe a task description for a quick decomposition.                                                  |
| API       | Use in orchestration pipelines to programmatically split tasks before routing to executor sessions. |

## Prompt

```
Decompose the following task into independently executable sub-tasks.

Task: {{TASK}}

Constraints:
{{CONSTRAINTS}}

Rules for sub-tasks:
1. Each sub-task must be executable in a single focused session without
   requiring output from a simultaneously-running sub-task.
2. Each sub-task must have a clear, verifiable done condition.
3. Sub-tasks must be ordered by dependency — list tasks that others
   depend on first.
4. Each sub-task must be scoped to a single concern. If a sub-task
   involves both data access and presentation, split it.

For each sub-task:

### Sub-task N: [short title]
**Do:** [one sentence — the specific action to take]
**Input:** [what this sub-task needs to start — output of a previous
sub-task, an existing file, a spec section, etc.]
**Output:** [what this sub-task produces]
**Done when:** [specific, verifiable condition]
**Depends on:** [sub-task numbers, or "none"]

After the list:

## Execution order
[The sequence in which sub-tasks should run. If any can run in parallel,
note them: "Sub-tasks 2 and 3 can run in parallel after sub-task 1."]

## What this decomposition assumes
[Bullet list of assumptions. These are conditions that must be true for
the decomposition to be valid. If an assumption turns out to be wrong,
the decomposition should be revised before execution begins.]
```

### Placeholders

| Placeholder       | Description                                                                         | Example                                                                                                                                                                    |
| ----------------- | ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `{{TASK}}`        | The task to decompose, in plain language                                            | `Migrate the user authentication system from session-based to JWT-based auth`                                                                                              |
| `{{CONSTRAINTS}}` | Constraints on how the decomposition should work. Use the default below or replace. | Default: `Sub-tasks must be executable sequentially. Each must be completable in a single session. Minimise the number of sub-tasks — decompose only as far as necessary.` |

## Low-context variant

This prompt is already `context_budget: low`. No low-context variant needed.

## Notes & tips

- If the model produces more than 7–8 sub-tasks, the original task is
  likely a feature that needs a proper spec and `break-into-tasks.md`
  rather than an informal decomposition.
- The "What this decomposition assumes" section is worth reading carefully
  before starting execution. A wrong assumption early (e.g. "assumes the
  existing auth middleware is stateless") invalidates later sub-tasks.
- Pass the full decomposition output as context when starting each
  sub-task session, so the executor knows where it fits in the pipeline.
- Related prompts:
  [`planning/break-into-tasks.md`](../planning/break-into-tasks.md),
  [`agent-orchestration/summarize-for-handoff.md`](./summarize-for-handoff.md),
  [`planning/write-feature-spec.md`](../planning/write-feature-spec.md)
