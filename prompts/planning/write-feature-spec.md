---
title: Write a feature spec
category: planning
tags: [spec, planning, requirements, feature, design-doc]
context_budget: low
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2026-03-17
      note: Initial version
---

# Write a feature spec

Produces a structured feature specification from a rough idea or brief
description. The output is a markdown document suitable for review, task
breakdown, and as context for an implementation skill or prompt.

Use this at the beginning of a feature — before writing any code — to turn
an informal idea into a shared, reviewable definition of what is being built
and why. The resulting spec becomes the input for
[`break-into-tasks.md`](./break-into-tasks.md) and the
[`skills/coding/implement-feature/`](../../skills/coding/implement-feature/)
skill.

## When to use

- You have a feature idea, user story, or brief and need a written spec
- You want to sanity-check scope before committing to implementation
- You need a document to share for review or async alignment
- NOT when the feature is already well-specified — jump to
  [`break-into-tasks.md`](./break-into-tasks.md) directly
- NOT for architectural decisions that require evaluating alternatives —
  use [`write-adr.md`](./write-adr.md) instead

## Interfaces

| Interface | Notes                                                                                                                  |
| --------- | ---------------------------------------------------------------------------------------------------------------------- |
| IDE       | Works well as a chat prompt with no file attachment needed. Use when you want the spec saved directly to your project. |
| Chat      | Cleanest interface for this prompt — conversational back-and-forth to refine the spec works well.                      |
| CLI       | Pipe a brief text description via stdin for a quick first draft.                                                       |
| API       | Pass the feature description programmatically; parse the markdown output for downstream automation.                    |

## Prompt

```
Write a feature spec for the following:

Feature: {{FEATURE_DESCRIPTION}}

{{#if EXISTING_CONTEXT}}
Additional context:
{{EXISTING_CONTEXT}}
{{/if}}

Produce a markdown spec document with these sections:

## Overview
One paragraph. What is this feature and what problem does it solve?
Do not describe how it works yet — only what and why.

## Goals
Bullet list. What should be true when this feature is complete?
Frame as outcomes, not tasks. Maximum 5 goals.

## Non-goals
Bullet list. What is explicitly out of scope for this feature?
Include at least one item — if nothing is out of scope, the feature
is probably under-specified.

## User stories
List of user stories in the format:
"As a [user type], I want to [action] so that [outcome]."
Include only the stories directly addressed by this feature.

## Functional requirements
Numbered list of specific, testable requirements.
Each requirement must be independently verifiable.
Use "must", "should", or "may" to indicate priority (RFC 2119).

## Open questions
Bullet list of unresolved questions that must be answered before or
during implementation. If none, write "None identified."

## Out of scope (deferred)
Bullet list of related features or improvements that are intentionally
deferred to a future iteration.

Rules for the entire document:
- Be specific and concrete. Avoid vague language like "improve",
  "enhance", or "better". Prefer "reduce latency by 200ms" over
  "improve performance".
- Do not describe implementation details or technology choices unless
  they are constraints given in the feature description.
- Keep the document under 500 words. If more is needed, the scope is
  likely too large — note this at the top.
```

### Placeholders

| Placeholder               | Description                                                                                                            | Example                                                                                                                          |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `{{FEATURE_DESCRIPTION}}` | The feature idea in plain language. Can be rough — a sentence or a paragraph.                                          | `Allow users to export their activity history as a CSV file from the account settings page.`                                     |
| `{{EXISTING_CONTEXT}}`    | Optional. Relevant background: existing system behavior, constraints, prior decisions. Remove the block if not needed. | `We already have a data export job that runs nightly for internal reporting. The user-facing export should reuse this pipeline.` |

## Low-context variant

This prompt is already `context_budget: low`. No low-context variant is needed
— it is safe for small local models.

If `{{EXISTING_CONTEXT}}` is very large (e.g. you're pasting in a long PRD or
prior spec), trim it to the most relevant 2–3 paragraphs before sending, or
use a summarization pass first:

```
Summarize the following document in 3 bullet points, focusing on
constraints and decisions relevant to a new feature:

{{LONG_CONTEXT_DOCUMENT}}
```

Then paste the summary as `{{EXISTING_CONTEXT}}`.

## Notes & tips

- The most common failure mode is a spec that is too vague in the functional
  requirements section. If the output says things like "the system should
  handle errors gracefully", push back: "Make requirement 4 specific and
  testable. What exact error conditions? What is the expected behavior?"
- The "Non-goals" section is the most valuable section for preventing scope
  creep during implementation. If the model produces weak non-goals, prompt:
  "What are three things a developer might assume is in scope but isn't?"
- For large or ambiguous features, run this prompt twice with different
  phrasings of `{{FEATURE_DESCRIPTION}}` and compare the specs — differences
  reveal ambiguity in the original idea.
- The output of this prompt is the natural input for:
  [`break-into-tasks.md`](./break-into-tasks.md) (task breakdown) and
  [`skills/coding/implement-feature/`](../../skills/coding/implement-feature/)
  (implementation)
- Related prompts:
  [`planning/break-into-tasks.md`](./break-into-tasks.md),
  [`planning/write-adr.md`](./write-adr.md),
  [`planning/estimate-complexity.md`](./estimate-complexity.md)
