---
title: Break a product spec into features
description: Break a reviewed product spec into distinct, independently shippable features — each a full vertical slice (data, logic, interface) that can ship on its own branch. Use between writing a product spec and breaking work into tasks, when you want one branch and task list per feature. Skip for a single-feature spec.
skill-saves-document: true
category: planning
tags: [features, breakdown, planning, vertical-slice, product, milestones]
context_budget: medium
interfaces: [ide, chat, cli, api]
output-schema: sab.features/1
versions:
    - version: 1.0.0
      date: 2026-06-17
      note: Initial version
---

# Break a product spec into features

Takes a product spec produced by
[`write-product-spec.md`](./write-product-spec.md) and decomposes it into a
set of distinct, independently deliverable features. Each feature is a full
vertical slice — everything required to make that capability work end-to-end,
from data to interface — so it can be built, reviewed, and shipped on its own
branch.

This is an optional step between speccing and task breakdown. The product
spec defines the "what specifically" across the whole product; this prompt
groups those requirements into shippable units of work. Each feature it
produces becomes the input for
[`break-into-tasks.md`](./break-into-tasks.md) — useful when you want one
branch (and one task list) per feature rather than a single flat task list
for the entire spec.

Use this after `write-product-spec.md` and before `break-into-tasks.md`. Skip
it when the spec is small enough that a single task list is manageable, or
when you are not splitting work into separate branches.

## When to use

- You have a reviewed product spec and want to split it into branch-sized
  units of work before task breakdown
- You want each unit to be a vertical slice that delivers end-to-end value,
  not a horizontal layer (e.g. "all the database work")
- You're parallelising work across people, sessions, or branches
- NOT before the product spec is reviewed — slicing a flawed spec propagates
  its errors into every feature
- NOT for a single-feature spec from
  [`write-feature-spec.md`](./write-feature-spec.md) — that is already one
  feature; go straight to [`break-into-tasks.md`](./break-into-tasks.md)
- NOT when the whole spec is small enough to be one task list — the extra
  layer adds overhead without benefit

## Interfaces

| Interface | Notes                                                                                            |
| --------- | ------------------------------------------------------------------------------------------------ |
| IDE       | Good fit — produce the feature breakdown as a project file and link each feature to its branch.  |
| Chat      | Ideal for iterative refinement: "Merge features 2 and 3" / "Split feature 4 — it's two slices."  |
| CLI       | Pipe the spec file: `cat spec.md \| your-model-cli --prompt break-into-features.md`              |
| API       | Use in pipeline setup. Parse each feature block and fan out to per-feature `break-into-tasks`.   |

## Prompt

```
Break the following product spec into a set of distinct features.

Each feature must be a vertical slice: it includes everything required to
make that capability work end-to-end — data, logic, and interface — so it
can be built, reviewed, and shipped on its own branch and deliver value
without depending on features that have not shipped yet.

Product spec:
<product_spec>
{{PRODUCT_SPEC}}
</product_spec>

{{#if MILESTONE_SCOPE}}
Only break down requirements in scope for: {{MILESTONE_SCOPE}}.
{{/if}}

Rules for the feature breakdown:
1. Every functional requirement in scope must belong to exactly one feature.
   Do not drop requirements and do not duplicate them across features.
2. Each feature must be a vertical slice that delivers observable value on
   its own — not a horizontal layer (e.g. "all the API endpoints" or "the
   database schema" are not features).
3. Prefer features that can ship independently. Where one feature genuinely
   depends on another, state the dependency explicitly and keep it minimal.
4. Order features so that foundational, enabling slices come first and
   dependent slices follow.
5. Do not invent scope. If a requirement does not fit cleanly into any
   feature, list it under "Unassigned requirements" rather than inventing a
   feature for it.

Output format — one entry per feature:

### Feature N: [short, capability-focused title]
**Value:** [one sentence — the end-to-end outcome this feature delivers, for whom]
**Vertical slice:** [the layers this feature spans — data / logic / interface / etc.]
**Requirements covered:** [the spec requirement numbers or IDs this feature implements]
**User stories:** [the spec user stories this feature satisfies, or "none"]
**Depends on:** [feature numbers this feature requires before it can ship, or "none"]
**Branch suggestion:** [a short branch name, e.g. feat/export-csv]
**Notes:** [scope boundaries, risks, or shared concerns. Omit if none.]

After the feature list, add:

## Coverage check
- Requirements covered: [list every in-scope requirement ID and the feature it maps to]
- Unassigned requirements: [any in-scope requirement that did not fit a feature, or "none"]

## Summary
- Total features: N
- Suggested build order: [the sequence respecting dependencies, e.g. "1 → 2 → 4, then 3 and 5 in parallel"]
- Independently shippable: [features with no dependencies]
- Risks: [features with heavy cross-dependencies or unclear boundaries]

{{#if OUTPUT_PATH}}
When the breakdown is complete, write it to: {{OUTPUT_PATH}}
{{else}}
When the breakdown is complete, do not save it to a default or assumed
location. First ask me where to write it — the directory and filename — and
wait for my answer before writing the file.
{{/if}}
```

### Placeholders

| Placeholder           | Description                                                              | Required | Example                                |
| --------------------- | ------------------------------------------------------------------------ | -------- | -------------------------------------- |
| `{{PRODUCT_SPEC}}`    | The full product spec output from `write-product-spec.md`               | Yes      | _(paste full product spec)_            |
| `{{MILESTONE_SCOPE}}` | Optional. Restrict the breakdown to one or more milestones from the spec | No       | `MVP`, `MVP and v1`, `v2 only`         |
| `{{OUTPUT_PATH}}`     | Optional. Where to write the feature breakdown. Omit to be asked before the file is saved. | No | `docs/planning/features.md`            |


## Low-context variant

Use when the product spec is long or the conversation has already consumed
significant context.

Changes from the full prompt:
- Drop the User stories field per feature
- Drop the Coverage check section (keep only Unassigned requirements as a line)
- Keep the vertical-slice rule — it is the point of this prompt

```
Break this product spec into distinct features. Each feature must be a
vertical slice that works end-to-end and can ship on its own branch — not a
horizontal layer. Every in-scope requirement must belong to exactly one
feature; do not invent scope.

Product spec:
<product_spec>
{{PRODUCT_SPEC}}
</product_spec>

{{#if MILESTONE_SCOPE}}
Only break down: {{MILESTONE_SCOPE}}.
{{/if}}

One entry per feature:

### Feature N: [title]
**Value:** [end-to-end outcome, for whom]
**Requirements covered:** [requirement IDs]
**Depends on:** [feature numbers, or "none"]
**Branch suggestion:** [short branch name]

After the list:
- Unassigned requirements: [any requirement that did not fit, or "none"]
- Suggested build order: [sequence respecting dependencies]

{{#if OUTPUT_PATH}}
Write the result to: {{OUTPUT_PATH}}
{{else}}
Before saving, ask me where to write the file and wait for my answer.
{{/if}}
```

## Notes & tips

- Set `{{OUTPUT_PATH}}` when you already know where the breakdown should live
  (e.g. a `docs/planning/` directory). Leave it unset and the model will ask
  before writing, so the document never lands in an unexpected place. In a
  pure CLI/API run with no interaction, always set it explicitly.
- The defining test of a good feature here is the vertical slice. If a
  "feature" is really a layer — "the data model", "the API", "the UI" — push
  back: "Re-slice these so each feature delivers value end-to-end." Three
  horizontal layers that only deliver value once all three ship are one
  feature, not three.
- The Coverage check is the safeguard against dropped scope. Every in-scope
  requirement from the spec must appear against exactly one feature. If
  something lands in "Unassigned requirements", either the spec has a gap or
  a feature boundary is wrong — resolve it before task breakdown.
- Minimise dependencies. A breakdown where every feature depends on every
  other defeats the purpose (independent branches). If you see a dependency
  web, ask the model to re-slice for independence, accepting a little
  duplication of plumbing if it buys shippability.
- The output of this prompt is the natural input for:
  [`planning/break-into-tasks.md`](./break-into-tasks.md) — run it once per
  feature to get a per-branch task list, or
  [`planning/estimate-complexity.md`](./estimate-complexity.md) to size each
  feature before committing.
- Common flow: `ideate-project` → `write-product-spec` → `break-into-features`
  (this prompt) → `break-into-tasks` per feature → `implement-feature` per task.
- Related prompts:
  [`planning/write-product-spec.md`](./write-product-spec.md),
  [`planning/break-into-tasks.md`](./break-into-tasks.md),
  [`planning/write-feature-spec.md`](./write-feature-spec.md),
  [`planning/estimate-complexity.md`](./estimate-complexity.md)

## Skill inputs

Used by the compiled Claude skill to rewrite the prompt's placeholders.

- `PRODUCT_SPEC`: the product spec from this conversation or a file the user references
- `MILESTONE_SCOPE`: a milestone scope

## Skill wrap-up

After saving the breakdown, offer the natural next step: break a chosen feature
into an implementation task list with `/saboteur-break-into-tasks` — run once per
feature to get one task list (and one branch) per feature.
