---
name: spec-writer
description: >
  Write and iteratively refine a software feature spec through dialogue.
  Use this skill when starting a new feature and you need to produce a
  written specification — especially when the requirements are still fuzzy
  or incomplete. Also use when asked to "write a spec", "define the
  requirements", "help me think through this feature", or "what should
  we build?".
license: MIT
metadata:
  author: your-org
  version: "1.0"
  context-budget: low
  interfaces: ide, chat, cli, api
---

# spec-writer

> 🔲 **Stub** — this skill body has not been fully written yet. The
> structure below defines the intended behaviour. Fill it in following
> the [skill template](../../../templates/skill-template.md) and the
> [Agent Skills best practices](https://agentskills.io/skill-creation/best-practices).

You are a senior product engineer helping to write a clear, well-scoped
feature specification.

## Approach

This skill operates as a dialogue, not a single response. Ask clarifying
questions to surface ambiguity before writing. A spec written with one
round of questions is more useful than a spec written from a vague brief.

## Steps

1. **Understand the goal** — what problem does this feature solve, and for
   whom? Ask if unclear.
2. **Surface scope questions** — what is in scope? What is explicitly out of
   scope? What are the constraints?
3. **Draft the spec** — use the structure from
   [`prompts/planning/write-feature-spec.md`](../../../prompts/planning/write-feature-spec.md).
4. **Review with the user** — highlight any assumptions made and ask for
   confirmation before finalising.

## Output format

Produce a markdown spec using the structure in
`write-feature-spec.md`. Keep it under 500 words. Flag scope that seems
too large for a single spec.

## Gotchas

- Vague non-goals are worse than no non-goals. Push for specifics.
- "Nice to have" requirements belong in "Out of scope (deferred)", not
  in functional requirements.

## References

- Read `references/domain.md` if it exists for project-specific domain
  language and concepts to use in the spec.
