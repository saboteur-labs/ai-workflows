---
title: Extract reusable React components
description: Identify duplicated JSX patterns in React component files and propose reusable component extractions. Use when component code has grown repetitive and you want concrete extraction candidates.
category: code
tags: [react, components, refactor, reusability, duplication, design-system]
context_budget: high
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2026-04-10
      note: Initial version
---

# Extract reusable React components

Analyses React component files and identifies inline JSX patterns, duplicated
structures, and tightly coupled logic that are candidates for extraction into
reusable components. Produces a prioritised list of extraction opportunities
with enough detail to act on each one.

Does not modify any files. The output feeds into a separate implementation
step. Separating analysis from implementation avoids premature abstraction —
extraction decisions should be made with the full picture of where duplication
actually exists, not file-by-file.

Use this before a design system build-out, when component files have grown
unwieldy, or when the same UI pattern keeps being re-implemented across
features.

## When to use

- Before introducing a shared component library or design system
- When component files exceed ~200 lines and feel hard to scan
- When the same visual pattern appears in multiple parts of the codebase but
  hasn't been unified
- When onboarding reveals that similar UI is built differently in different
  areas
- NOT when you want the extraction implemented immediately — use this to
  produce the candidate list first, then act on it in a separate session
- NOT as a substitute for a component API design review — this identifies
  what to extract, not how to design the final API

## Interfaces

| Interface | Notes                                                                                                                                                                                   |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| IDE       | Point the agent at the target directory. In Claude Code, `@folder` brings the tree into context. Agent mode allows the model to traverse files and identify cross-file patterns.        |
| Chat      | Paste one or more component files into `{{SCOPE}}`. For cross-file analysis, paste multiple files separated by filename headers. Findings will be limited to what you provide.         |
| CLI       | Run as an agentic session: `claude --scope src/components/ --prompt extract-reusable-react-components.md`. The agent will traverse the tree and read files as needed.                  |
| API       | Pass component file contents programmatically. Include any existing shared component directory so the model knows what has already been extracted and avoids duplicate recommendations. |

## Prompt

```
You are analysing the React components in {{SCOPE}} to identify what should be
extracted into reusable components.

Your goal is to find duplication, repeated patterns, and inline JSX structures
that would benefit from being shared — and to explain clearly why each
candidate warrants extraction.

Do not modify any files. Do not generate any code. Produce only the analysis
report described below.

{{#if EXISTING_COMPONENTS}}
These shared components already exist and should not be recommended again:
{{EXISTING_COMPONENTS}}
{{/if}}

{{#if ADDITIONAL_CONTEXT}}
Additional context about this codebase:
{{ADDITIONAL_CONTEXT}}
{{/if}}

---

Step 1 — Map the component landscape

Before analysing, build a picture of what exists. Traverse all files in
{{SCOPE}} and note:

- What component files are present and what they render
- Which directories or features contain the most component files
- Whether a shared component directory already exists, and what it contains
- Any UI framework or component library in use (e.g. shadcn/ui, MUI, Radix)
  — existing primitives narrow what needs to be extracted

Step 2 — Identify extraction candidates

Look for each of the following signals. For each candidate found, note the
file(s) where it appears, the nature of the pattern, and why extraction would
help.

**Duplicated JSX structure**
The same markup pattern — same element hierarchy, same className shapes, same
conditional logic — appears in two or more places. Duplication in JSX is
often harder to spot than in logic because each instance may differ only in
content or minor props. Look for structural similarity, not just copy-paste.

**Inline layout or wrapper patterns**
Repeated `<div>` or container patterns used for layout purposes — flex
wrappers, card shells, section containers, grid layouts — that appear
identically across multiple components. These are prime extraction candidates
because they have no business logic and a clear, bounded API.

**Repeated conditional rendering**
The same conditional rendering logic (`isLoading`, `isEmpty`, `isError`,
`hasPermission`) applied inline in multiple components, producing similar
guard structures. Extract into a wrapper component or slot-based pattern
rather than duplicating the condition.

**Tightly coupled UI fragments**
Chunks of JSX inside a larger component that have a clear, self-contained
purpose (a header block, a metadata row, a button group) but are not
extracted because the parent component has grown organically. These become
candidates when the fragment is large enough to obscure the parent's
structure.

**Prop drilling through intermediate components**
Props passed through one or more intermediate components that do nothing
with them except forward them down. This often signals a missing component
boundary — the intermediate layer exists to hold together what should be a
single extracted component.

**Repeated form field or input patterns**
The same combination of label, input, and error message rendered multiple
times with different field names. These are almost always worth extracting
into a field wrapper component.

**Icon + label or badge + status patterns**
Small, compositional patterns — icon with text, status dot with label, badge
with count — repeated across the UI. These make good atomic components because
their scope is narrow and their API is obvious.

Step 3 — Produce the analysis report

## Reusable Component Candidates: {{SCOPE}}

### Overview
[2–3 sentences on the overall state of component reuse. Is duplication
isolated to specific features, or systemic? What single extraction would
have the highest impact?]

### Candidates

Group findings by extraction type. Omit any type with no findings. For each
candidate, use this format:

**[TYPE]** Suggested name: `ComponentName`
Appears in: `path/to/file.tsx`, `path/to/other.tsx` (list all occurrences)
Description: One paragraph explaining the pattern, where it recurs, and what
makes it a good extraction candidate. Be specific about the JSX or logic
involved — vague descriptions make extraction harder.
Suggested props: List the props this component would need (e.g. `label: string`,
`onClick: () => void`). If the API is unclear, say so rather than guessing.
Complexity: low | medium | high
Impact: low | medium | high

Complexity guide:
- Low: structural extraction only, no logic — a layout or wrapper component
- Medium: some prop flexibility needed, may involve children or slots
- High: requires logic extraction, context, or significant API design work

Impact guide:
- High: eliminates meaningful duplication across 3+ files or a heavily used
  component
- Medium: consolidates 2 occurrences or a moderately used pattern
- Low: minor deduplication with limited scope

### Prioritised extraction list

A flat, ordered list of extractions, highest-impact first. This list is the
direct input for an implementation session — it should be specific enough to
act on without re-reading the full analysis.

Format each item as:
- `SuggestedComponentName` — one-sentence action (e.g. "extract from
  `path/a.tsx` and `path/b.tsx`, replaces inline flex wrapper pattern")

### What is already well-structured
[Component patterns that are already appropriately extracted or scoped, and
should be preserved. If nothing stands out, write "None identified."]
```

### Placeholders

| Placeholder               | Description                                                                                     | Example                                                                                                     |
| ------------------------- | ----------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `{{SCOPE}}`               | The directory or file(s) to analyse                                                             | `src/components/`, `src/features/dashboard`                                                                 |
| `{{EXISTING_COMPONENTS}}` | Optional. Components already in a shared library. Prevents duplicate recommendations.          | `Button, Modal, Tooltip, Card` or `src/components/ui/`                                                      |
| `{{ADDITIONAL_CONTEXT}}`  | Optional. Tech stack, design system conventions, or known constraints. Remove if not needed.   | `We use Tailwind for styling. shadcn/ui provides base primitives. New components go in src/components/ui/.` |

## Low-context variant

```
Analyse the React components in {{SCOPE}} for reusable component extraction
opportunities. Do not modify any files.

Look for: duplicated JSX structure, repeated layout wrappers, shared
conditional rendering patterns, repeated form field groups, and tightly
coupled UI fragments that obscure parent component structure.

For each candidate: suggested component name, files where it appears,
one-sentence description of the pattern, and suggested props.

End with a flat prioritised list of extractions, highest-impact first.
```

## Notes & tips

- Cross-file pattern detection is where this prompt earns its value. A
  single-file analysis will miss the most important candidates — always run
  it with agent mode or across the full feature directory.
- The "Suggested props" field is intentionally lightweight. Its purpose is
  to flag whether the API is obvious or not, not to finalise it. Complex
  prop APIs are a signal that the extraction may need design work before
  implementation.
- Use `{{EXISTING_COMPONENTS}}` to prevent the model recommending what
  already exists. If your shared components live in a directory, pass the
  path rather than listing every component by name.
- High complexity + low impact candidates are rarely worth acting on
  immediately. Use the prioritised list to sequence work — start with
  high-impact, low-complexity extractions to establish patterns before
  tackling harder cases.
- The output of this prompt feeds directly into a component implementation
  session. Pair it with [`planning/break-into-tasks.md`](../planning/break-into-tasks.md)
  if the prioritised list is long — some extractions depend on others (e.g.
  a field wrapper depends on a base input component).
- Related prompts:
  [`code/audit-codebase-structure.md`](./audit-codebase-structure.md),
  [`code/refactor-for-readability.md`](./refactor-for-readability.md),
  [`planning/break-into-tasks.md`](../planning/break-into-tasks.md)

## Skill inputs

Used by the compiled Claude skill to rewrite the prompt's placeholders.

- `SCOPE`: the directory or files to analyse
- `EXISTING_COMPONENTS`: components already in a shared library (to avoid duplicate recommendations)
- `ADDITIONAL_CONTEXT`: tech stack or design-system conventions
