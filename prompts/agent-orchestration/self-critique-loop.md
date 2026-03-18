---
title: Self-critique and improve output
category: agent-orchestration
tags: [critique, review, quality, self-improvement, iteration, validation]
context_budget: low
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2025-03-17
      note: Initial version
---

# Self-critique and improve output

Asks the model to review its own previous output against the original
requirements, identify specific weaknesses, and produce an improved version.
A lightweight quality gate that catches obvious issues before your review,
so your attention focuses on the non-obvious ones.

Use at the end of any session where output quality matters but a full
separate Reviewer session is more overhead than the task warrants.

## When to use

- After an implementation session, before accepting the output
- After generating a spec or plan, before passing it to the next stage
- When output looks right but you want a quick confidence check
- As a precursor to `code/code-review.md` — self-critique first to
  handle obvious issues, human review for the subtle ones
- NOT as a substitute for human review on high-risk changes — self-critique
  is better than nothing but the model has blind spots about its own output
- NOT when the output is already clearly correct — it adds a turn of latency
  for no gain

## Interfaces

| Interface | Notes                                                                                |
| --------- | ------------------------------------------------------------------------------------ |
| IDE       | Run at the end of an implementation session before accepting the diff.               |
| Chat      | Run as a penultimate message before closing a session.                               |
| CLI       | Pipe the output to critique with the original prompt as requirements.                |
| API       | Use in automated quality gates before writing outputs to disk or passing downstream. |

## Prompt

```
Review your previous output against the original requirements and produce
an improved version.

Original requirements:
{{REQUIREMENTS}}

Your previous output:
{{ORIGINAL_OUTPUT}}

{{#if FOCUS}}
Focus this critique on: {{FOCUS}}
{{/if}}

Step 1 — Critique (do not produce the revised output yet):
Identify specific weaknesses in your previous output. For each weakness:
- What is wrong or missing
- Why it matters
- What the correct version should do instead

Be specific. "Could be clearer" is not useful. "The done condition for
task 3 is not verifiable because it uses the word 'correctly' without
defining correct behaviour" is useful.

If the output has no meaningful weaknesses, say so and explain why —
do not invent issues.

Step 2 — Revised output:
Produce the revised version incorporating all identified improvements.
Mark each change with a brief inline note: [fixed: reason].

If no changes are needed, reproduce the original output unchanged and
note "No changes required."
```

### Placeholders

| Placeholder           | Description                                                                         | Example                                                                                                  |
| --------------------- | ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `{{REQUIREMENTS}}`    | The original prompt, spec, or acceptance criteria the output should meet            | _(paste the original task description or prompt)_                                                        |
| `{{ORIGINAL_OUTPUT}}` | The output to critique                                                              | _(paste the model's previous response)_                                                                  |
| `{{FOCUS}}`           | Optional. Specific aspect to focus the critique on. Remove the block if not needed. | `correctness of the done conditions`, `completeness of error handling`, `adherence to the output format` |

## Low-context variant

This prompt is already `context_budget: low`. For very large outputs,
pass only the requirements and a summary of the output rather than the
full text:

```
Critique this output against the requirements. Identify the top 3
specific weaknesses. Then produce a revised version fixing only those
issues.

Requirements: {{REQUIREMENTS}}
Output summary: {{OUTPUT_SUMMARY}}
```

## Notes & tips

- The two-step structure (critique first, then revise) produces better
  results than asking for a direct revision. Separating diagnosis from
  treatment makes each step more focused.
- If the model critiques its own output but the revised version is
  essentially the same, the critique was genuine but the model lacked
  the information to fix it. The critique output itself is useful — it
  tells you what to investigate or provide.
- For code output, `{{FOCUS}}` values that produce the most useful
  critiques: `correctness of error handling`, `completeness of test
coverage`, `adherence to the type constraints in the requirements`.
- This prompt pairs naturally with the Reviewer role in
  `guides/agent-patterns/multi-agent-orchestration.md` as a first pass
  before a dedicated review session.
- Related prompts:
  [`code/code-review.md`](../code/code-review.md),
  [`agent-orchestration/summarize-for-handoff.md`](./summarize-for-handoff.md)
- Related guides:
  [`guides/agent-patterns/human-in-the-loop.md`](../../guides/agent-patterns/human-in-the-loop.md)
