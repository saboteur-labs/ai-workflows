---
title: Refactor code for readability
category: code
tags: [refactor, readability, clean-code, naming, structure]
context_budget: medium
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2025-03-17
      note: Initial version
---

# Refactor code for readability

Refactors a provided code block to improve clarity, naming, and structure
without changing observable behaviour. Explains each change and why it
improves readability, so you understand and can validate the diff rather
than just accepting it.

Use this when code is functionally correct but hard to read, maintain, or
reason about. Not for fixing bugs or changing behaviour — use
`skills/coding/implement-feature/` or `skills/coding/debug-issue/` for those.

## When to use

- Code is correct but dense, inconsistently named, or poorly structured
- Preparing code for review or handoff to another developer
- After a first-pass AI implementation that works but reads poorly
- NOT when the code has bugs — fix correctness first, then refactor
- NOT for large files over ~250 lines without chunking —
  run once per function group

## Interfaces

| Interface | Notes                                                                                                     |
| --------- | --------------------------------------------------------------------------------------------------------- |
| IDE       | Reference the file with `@filename` or `#file:filename`. Apply the resulting diff directly in the editor. |
| Chat      | Paste the code into `{{CODE}}`. Review the proposed changes before copying back.                          |
| CLI       | Pipe the file: `cat src/utils.ts \| your-model-cli --prompt refactor-for-readability.md`                  |
| API       | Pass code programmatically. Parse the output diff for automated application.                              |

## Prompt

````
Refactor the following {{LANGUAGE}} code for readability.

```{{LANGUAGE}}
{{CODE}}
```

Rules:
1. Do not change observable behaviour. The refactored code must produce
   identical outputs for all inputs.
2. Do not add or remove functionality.
3. {{CONSTRAINTS}}

Apply improvements in these areas where relevant:
- Naming: rename variables, functions, and parameters to clearly express
  intent. Prefer specific names over generic ones (e.g. `userId` over `id`,
  `parseIsoDate` over `parse`).
- Function size: extract logic into named helper functions if a function
  exceeds ~30 lines or handles more than one distinct concern.
- Nesting: reduce nesting depth using early returns, guard clauses, or
  extracted functions. Maximum 3 levels of nesting.
- Comments: remove comments that restate what the code does. Keep comments
  that explain why a non-obvious decision was made.
- Consistency: apply naming and structural patterns consistently within
  the file. If the file uses one convention in one place, use it everywhere.

Output format:
1. The complete refactored code in a code block
2. A changelog listing each change made and why, in the format:
   - **[type]** description of change and readability benefit
   Where [type] is one of: naming, extraction, nesting, comments,
   consistency, or structure

If no meaningful improvements are possible, say so and briefly explain why.
````

### Placeholders

| Placeholder       | Description                                       | Example                                                                          |
| ----------------- | ------------------------------------------------- | -------------------------------------------------------------------------------- |
| `{{LANGUAGE}}`    | Programming language                              | `TypeScript`, `Python`                                                           |
| `{{CODE}}`        | The code to refactor                              | _(paste contents)_                                                               |
| `{{CONSTRAINTS}}` | Project-specific constraints, or use the default. | Default: `Match the naming and structural patterns of the surrounding codebase.` |

## Low-context variant

````
Refactor this {{LANGUAGE}} code for readability without changing behaviour.

```{{LANGUAGE}}
{{CODE}}
```

Focus on: naming clarity, reducing nesting, extracting long functions.
Output the refactored code, then a bullet list of changes made.
````

## Notes & tips

- Always run your test suite after applying the refactor to verify no
  behaviour changed.
- If the model renames things you want to keep (public API names, database
  column names, serialised keys), add to `{{CONSTRAINTS}}`: "Do not rename
  any exported functions, types, or class members."
- If the changelog is longer than the code, the model over-refactored. Ask:
  "Limit changes to the three most impactful improvements only."
- Related prompts:
  [`code/code-review.md`](./code-review.md),
  [`code/scaffold-module.md`](./scaffold-module.md)
- Related skills:
  [`skills/coding/implement-feature/`](../../skills/coding/implement-feature/)
