---
title: Summarize session state for handoff
description: Summarize the current session's state — what was done, what's left, and key context — for handoff to a new session or agent. Use before a context reset or when delegating continued work.
category: agent-orchestration
tags: [handoff, summary, context, session, pipeline, continuity]
context_budget: low
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2026-03-17
      note: Initial version
---

# Summarize session state for handoff

Produces a compact, structured summary of the current session's state —
what was worked on, decisions made, current status, and what comes next.
Use at the end of any session whose output feeds into another session or
needs to be resumed later.

This is the connective tissue of multi-session pipelines. A good handoff
summary is what allows the next session to start focused rather than
reconstructing context from scratch.

## When to use

- At the end of any session in a multi-session pipeline
- Before starting a new session to continue interrupted work
- When consolidating outputs from multiple chunk-processing sessions
- When handing work to another developer or agent
- NOT mid-session as a substitute for good session discipline —
  use it at natural completion points, not as a workaround for a
  session that has drifted

## Interfaces

| Interface | Notes                                                                             |
| --------- | --------------------------------------------------------------------------------- |
| IDE       | Run at the end of an implementation or planning session before closing.           |
| Chat      | Run as the last message in any session that feeds into another.                   |
| CLI       | Pipe session output to produce a handoff document.                                |
| API       | Use in automated pipelines to generate handoff documents between executor stages. |

## Prompt

```
Summarize this session for handoff to the next session or agent.

{{#if SESSION_CONTEXT}}
Session context:
{{SESSION_CONTEXT}}
{{/if}}

Next session's task: {{NEXT_TASK}}

Produce a handoff document in this format:

## Handoff summary

**Task completed:** [one sentence — what this session set out to do]
**Status:** [complete / partial — if partial, what remains]

### What was produced
[Bullet list of concrete outputs: files created or modified, documents
written, decisions made. Be specific — include file paths and decision
outcomes, not just categories.]

### Decisions and assumptions made
[Bullet list of any decisions or assumptions that the next session needs
to know. Include the reasoning briefly — "decided X because Y" is more
useful than just "decided X".]
If none: "None beyond what is captured in the outputs."

### Current state
[A brief description of the state of the work right now. What's done,
what's in progress, what's blocked, what's deferred.]

### What the next session should do
[A specific, actionable instruction for the next session. Not "continue
the work" — something concrete like "Implement the route handler in
src/routes/export.ts using the service layer produced in this session.
The service layer is complete and tested. Start with the happy path."]

### Context to carry forward
[Anything the next session must have in its context to proceed correctly:
file contents to reference, constraints to honour, gotchas discovered
during this session. Keep this section compact — the next session has
limited context budget.]
```

### Placeholders

| Placeholder           | Description                                                                                                                                                   | Example                                                                                                        |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `{{SESSION_CONTEXT}}` | Optional. The conversation or work to summarise, if not already in context. Remove the block if the session is still open and the model has the full context. | _(paste session content or leave blank)_                                                                       |
| `{{NEXT_TASK}}`       | What the next session or agent will be doing                                                                                                                  | `Implement the route handler for the CSV export feature`, `Review the implementation produced in this session` |

## Low-context variant

This prompt is already `context_budget: low`. No low-context variant needed.

For consolidating many chunk-processing outputs (e.g. 8 code review chunks),
run a two-level consolidation to avoid hitting context limits:

**Level 1** — consolidate pairs:

```
Combine these two code review outputs into one, removing duplicates
and resolving any contradictions in favour of the more specific finding.
Keep the same format.

Review 1: {{REVIEW_1}}
Review 2: {{REVIEW_2}}
```

**Level 2** — consolidate the pair results using this prompt normally.

## Notes & tips

- The "Context to carry forward" section should be as short as possible.
  If it's growing long, the session has produced too much context to
  summarise cleanly — start a new session sooner next time.
- For chunk consolidation, the "What was produced" section should list
  each chunk's key finding, not a full reproduction. The point is a
  navigable summary, not a verbatim copy.
- Paste the handoff document as the first message of the next session,
  before injecting the skill or prompt for that session.
- Related prompts:
  [`agent-orchestration/decompose-task.md`](./decompose-task.md),
  [`agent-orchestration/self-critique-loop.md`](./self-critique-loop.md)
- Related guides:
  [`guides/agent-patterns/multi-agent-orchestration.md`](../../guides/agent-patterns/multi-agent-orchestration.md),
  [`guides/agent-patterns/single-agent.md`](../../guides/agent-patterns/single-agent.md)

## Skill inputs

Used by the compiled Claude skill to rewrite the prompt's placeholders.

- `SESSION_CONTEXT`: the conversation or work to summarise
- `NEXT_TASK`: what the next session or agent will be doing
