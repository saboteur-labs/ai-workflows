---
title: Write a product spec from a concept document
description: Expand a structured concept document into a full product spec — milestone-organised functional requirements, user personas, constraints, and tracked open questions. Use after ideate-project and before breaking work into features or tasks. For a single feature, use write-feature-spec instead.
skill-saves-document: true
category: planning
tags: [spec, planning, requirements, product, milestones, design-doc]
context_budget: medium
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2026-04-26
      note: Initial version
---

# Write a product spec from a concept document

Expands a concept document produced by
[`ideate-project.md`](./ideate-project.md) into a full product spec —
milestone-organized functional requirements, user personas, constraints
derived from the concept's caveats, and open questions with impact tracking.

The concept document has already defined the "what and why." This prompt
derives the "what specifically" from it: testable requirements organized by
milestone, with non-goals and deferred work made explicit.

Use this immediately after `ideate-project.md` and before
[`break-into-tasks.md`](./break-into-tasks.md). If you only need to spec a
single feature rather than a full product, use
[`write-feature-spec.md`](./write-feature-spec.md) instead.

## When to use

- You have a concept document from `ideate-project.md` and are ready to write
  a formal spec
- You want requirements organized by milestone (MVP / v1 / v2) rather than a
  flat list
- You want to scope the spec to a single milestone before committing to more
- NOT before the concept document is reviewed — speccing an unreviewed concept
  propagates its assumptions into requirements
- NOT for a single feature with no milestone structure — use
  [`write-feature-spec.md`](./write-feature-spec.md)
- NOT when the concept's Open Questions are still unresolved in a way that
  would block core requirements — resolve them first or the spec will be
  riddled with blockers

## Interfaces

| Interface | Notes                                                                                                              |
| --------- | ------------------------------------------------------------------------------------------------------------------ |
| IDE       | Good fit — produce the spec file directly in the project and link it from the concept document.                    |
| Chat      | Works well for iterative refinement of individual sections after the initial draft.                                |
| CLI       | Pipe the concept document via stdin: `cat concept.md \| your-model-cli --prompt write-product-spec.md`            |
| API       | Pass the concept document as a variable; parse the milestone requirements sections for downstream task automation. |

## Prompt

```
You are a product spec writer. Your input is a structured concept document
produced by the ideate-project prompt. Your goal is to expand it into a
full product spec — a document a team can use to design, estimate, and
build the product.

The concept document has already defined the "what and why." Your job is to
derive specific, testable functional requirements from it and organise them
by milestone into a reviewable spec. Do not add capabilities that were not
in the concept document — if something seems missing, add it as an open
question.

Concept document:
<concept_document>
{{CONCEPT_DOCUMENT}}
</concept_document>

{{#if MILESTONE_SCOPE}}
Scope this spec to the following milestone(s) only: {{MILESTONE_SCOPE}}.
State the scope at the top of the document. Requirements for other milestones
move to Out of Scope (Deferred).
{{/if}}

Produce the spec using the following structure:

---

# Product Spec: [Title from concept document]

**Milestone scope:** [All milestones — MVP / v1 / v2 | or the specified scope]
**Status:** Draft
**Source concept:** [Working title from concept document]

## Overview
One paragraph. What is this product and what problem does it solve?
Synthesise the concept document's Problem & Value and Core Concept sections.
Do not add new information.

## Goals
Bullet list of 4–6 outcomes. Each goal must be verifiable, not a task.
Frame as "A [user type] can [do X]" or "The product achieves [Y]."
Derive from the concept's Key Capabilities and value proposition.

## Non-goals
Bullet list of explicit exclusions. Draw from the concept's "What This Is
Not" section. Add milestone boundary exclusions where relevant — for example,
if scoped to MVP, note that v1 features are explicitly out of scope.

## Users
For each user type from the concept's Target Audience:

**[User type]**
[One sentence: who they are and their relationship to the product]
**Key need:** [The problem this product solves for them]
**Success looks like:** [How they know the product is working]

## User Stories
Group by user type. Derive 1–2 stories per Key Capability from the concept.

"As a [user type], I want to [action] so that [outcome]."

Include only stories in scope for the specified milestone(s). Tag each with
the milestone it belongs to: [MVP], [v1], or [v2].

## Functional Requirements

Organise by milestone. For each milestone in scope:

### [Milestone name] Requirements
Numbered list of specific, testable requirements.
- Each requirement must be independently verifiable.
- Use MUST, SHOULD, or MAY (RFC 2119).
- Map each requirement to a user story: e.g., "Users MUST be able to X. [US-3]"
- Do not include implementation details.
- If an open question blocks a requirement, mark it: [BLOCKED: OQ-N]

## Constraints
Bullet list of hard constraints the implementation must respect. Derive from:
- Caveats & Pitfalls in the concept (adoption risks that constrain the
  product's behaviour or defaults)
- Technical Considerations in the concept (as constraints, not prescriptions)
- Any platform, accessibility, or integration constraints stated in user
  stories

## Open Questions
Carry over unresolved questions from the concept document's Open Questions
section. Add any new questions surfaced during speccing. For each:

**OQ-N: [Question]**
**Impact:** [Which requirement(s) or section this blocks or changes]
**Owner:** [The role — not a person — who should answer this]

## Out of Scope (Deferred)
Bullet list of capabilities from the concept document not covered by this
spec. Tag with the milestone they belong to:
"[v2] — [feature or capability description]"

---

Rules for the entire spec:
- Every functional requirement must be testable. "The system should be
  responsive" is not a requirement. "The dashboard MUST load within 2 seconds
  on a 10 Mbps connection" is.
- Derive everything from the concept document. If a requirement is not
  supported by the concept, add an open question instead of inventing scope.
- If the concept's Open Questions would make a requirement unwritable,
  write the requirement as a placeholder and mark it [BLOCKED: OQ-N].
- Keep the spec under 1500 words. If more is needed, the scope is likely too
  wide — consider speccing one milestone at a time using {{MILESTONE_SCOPE}}.
```

### Placeholders

| Placeholder            | Description                                                                | Required | Example                                                    |
| ---------------------- | -------------------------------------------------------------------------- | -------- | ---------------------------------------------------------- |
| `{{CONCEPT_DOCUMENT}}` | The full concept document output from `ideate-project.md`                 | Yes      | _(paste full concept document)_                            |
| `{{MILESTONE_SCOPE}}`  | Optional. Limit the spec to one or more milestones. Omit for all three.   | No       | `MVP`, `MVP and v1`, `v2 only`                             |

## Low-context variant

Use when the concept document is long or the conversation has already
consumed significant context.

Changes from the full prompt:
- The Users section is reduced to one line per user type
- User story milestone tags are omitted
- Requirement-to-story mapping is omitted
- Open Questions omit the Owner field
- Word limit reduced to 1000 words

```
You are a product spec writer. Expand the following concept document into a
product spec with testable, milestone-organized functional requirements. Do
not add capabilities that are not in the concept document.

Concept document:
<concept_document>
{{CONCEPT_DOCUMENT}}
</concept_document>

{{#if MILESTONE_SCOPE}}
Scope to: {{MILESTONE_SCOPE}} only.
{{/if}}

Produce the spec with these sections:

# Product Spec: [Title]

**Milestone scope:** [All / specified scope]
**Status:** Draft

## Overview
One paragraph — what it is and what problem it solves.

## Goals
4–6 verifiable outcomes, not tasks.

## Non-goals
From "What This Is Not" in the concept, plus milestone boundary exclusions.

## Users
One line per user type: who they are and their key need.

## User Stories
1–2 stories per Key Capability. "As a [user], I want [action] so that [outcome]."
In-scope stories only.

## Functional Requirements
Organised by milestone. Numbered, testable. Use MUST / SHOULD / MAY.
Mark blocked requirements [BLOCKED: OQ-N].

## Constraints
Hard constraints derived from the concept's Caveats & Pitfalls and
Technical Considerations.

## Open Questions
From the concept's Open Questions plus any new ones.
**OQ-N:** [Question] — **Impact:** [what it blocks]

## Out of Scope (Deferred)
Capabilities not in this spec's scope, tagged [MVP] / [v1] / [v2].

Keep the spec under 1000 words.
```

## Notes & tips

- If the concept document has open questions that block core requirements,
  resolve them before running this prompt — or set expectations that the spec
  will have `[BLOCKED]` markers that need follow-up.
- The Constraints section is frequently skipped in specs written from scratch.
  Since the concept document's Caveats & Pitfalls feed directly into it,
  review that section when reviewing the spec: each caveat should appear
  either as a constraint, a non-goal, or an open question.
- Use `{{MILESTONE_SCOPE}}` to produce lightweight, focused specs. A
  milestone-scoped spec is easier to review and task-break than a full
  three-milestone spec. Common flow: spec MVP first → review → spec v1 once
  MVP ships.
- The word limit is a forcing function, not a formatting rule. If the spec
  runs long, it usually means either the scope is too large or requirements
  are being written at the wrong level of detail (too much implementation
  detail, or conversely too abstract to be testable).
- The output of this prompt is the natural input for:
  [`planning/break-into-tasks.md`](./break-into-tasks.md) (task breakdown) and
  [`planning/estimate-complexity.md`](./estimate-complexity.md) (effort sizing).
  To split the spec into independently shippable, branch-sized units first,
  run [`planning/break-into-features.md`](./break-into-features.md) and then
  break each feature into tasks separately.
- Related prompts:
  [`planning/ideate-project.md`](./ideate-project.md),
  [`planning/write-feature-spec.md`](./write-feature-spec.md),
  [`planning/break-into-features.md`](./break-into-features.md),
  [`planning/break-into-tasks.md`](./break-into-tasks.md),
  [`planning/estimate-complexity.md`](./estimate-complexity.md)

## Skill inputs

Used by the compiled Claude skill to rewrite the prompt's placeholders.

- `CONCEPT_DOCUMENT`: the concept document from this conversation or a file the user references
- `MILESTONE_SCOPE`: a milestone scope

## Skill wrap-up

1. If the spec has open questions that block core requirements, resolve them
   interactively before saving: for each, present 3–5 options with brief pros and
   cons, and wait for the user to choose (they may defer any). Update the spec
   with the resolutions.
2. After the spec is saved, offer the natural next step: split it into
   independently shippable features with `/saboteur-break-into-features`, or break
   it straight into tasks with `/saboteur-break-into-tasks`.
