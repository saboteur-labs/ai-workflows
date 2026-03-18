---
title: Review code for quality and correctness
category: code
tags: [code-review, quality, conventions, bugs, security]
context_budget: medium
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2025-03-17
      note: Initial version
---

# Review code for quality and correctness

Performs a structured code review of a provided file or diff. Produces a
prioritised list of findings across correctness, security, maintainability,
and conventions. Does not rewrite the code — findings are inputs for a
targeted fix session or human action.

Use this when you want a second-pass review before merging, when onboarding
to an unfamiliar codebase, or as the Reviewer session in a multi-agent
pipeline. For a full implementation review across multiple files, run once
per file and consolidate with
[`agent-orchestration/summarize-for-handoff.md`](../agent-orchestration/summarize-for-handoff.md).

## When to use

- Pre-merge review of a diff or changed file
- Review of AI-generated implementation output before accepting it
- Onboarding review of an unfamiliar module
- NOT for files over ~300 lines — chunk first (see
  [`guides/context/low-memory-workarounds.md`](../../guides/context/low-memory-workarounds.md))
- NOT when you want fixes inline — use this to identify issues, then use
  `skills/coding/implement-feature/` or `skills/coding/debug-issue/` to fix them

## Interfaces

| Interface | Notes                                                                                                           |
| --------- | --------------------------------------------------------------------------------------------------------------- |
| IDE       | Use `@filename` or `#file:filename` to reference the file rather than pasting. Set `{{CODE}}` to the reference. |
| Chat      | Paste the file contents or diff into `{{CODE}}`. For diffs, set `{{CODE_TYPE}}` to `diff`.                      |
| CLI       | Pipe via stdin: `git diff HEAD \| sed "s/{{CODE}}/$(cat)/g" prompt.md \| your-model-cli`                        |
| API       | Pass file contents or diff programmatically into `{{CODE}}`.                                                    |

## Prompt

````
Review the following {{LANGUAGE}} {{CODE_TYPE}} for quality and correctness.

```{{LANGUAGE}}
{{CODE}}
```

Produce a structured review with findings grouped into these categories.
Only include a category if you have findings for it — omit empty categories.

## Correctness
Bugs, logic errors, incorrect assumptions, unhandled edge cases, and
broken error handling. Label each finding: [bug], [logic], [edge-case],
or [error-handling].

## Security
Input validation gaps, injection risks, authentication or authorisation
issues, secrets in code, unsafe operations. Label each: [injection],
[auth], [secrets], [unsafe], or [validation].

## Maintainability
Code that is unnecessarily complex, poorly named, inadequately tested,
or structured in a way that will make future changes difficult. Label
each: [complexity], [naming], [structure], or [testability].

## Conventions
Deviations from the language's idiomatic style or the patterns visible
in the surrounding code. Label each: [style] or [pattern].

Format each finding as:
**[CATEGORY] [label]** Line N (or lines N–M): description of the issue
and why it matters. Suggested fix in one sentence.

After all findings, add:
## Summary
- Total findings: N (critical: X, moderate: Y, minor: Z)
- Most important to fix: [one sentence identifying the highest-priority issue]
- Looks good: [one sentence on what the code does well, if anything]

Severity guide:
- Critical: could cause data loss, security breach, or incorrect behaviour
  in production
- Moderate: likely to cause bugs or maintenance problems
- Minor: style or convention issue with no functional impact

{{ADDITIONAL_FOCUS}}
````

### Placeholders

| Placeholder            | Description                                                | Example                                                          |
| ---------------------- | ---------------------------------------------------------- | ---------------------------------------------------------------- |
| `{{LANGUAGE}}`         | Programming language                                       | `TypeScript`, `Python`                                           |
| `{{CODE_TYPE}}`        | What is being reviewed                                     | `file`, `diff`, `function`                                       |
| `{{CODE}}`             | The code or diff to review                                 | _(paste contents)_                                               |
| `{{ADDITIONAL_FOCUS}}` | Optional extra instruction. Remove the line if not needed. | `Pay particular attention to error handling in async functions.` |

## Low-context variant

````
Review this {{LANGUAGE}} {{CODE_TYPE}} for bugs, security issues, and
maintainability problems.

```{{LANGUAGE}}
{{CODE}}
```

List findings in order of severity. For each: line number, issue,
suggested fix. End with a one-sentence summary of the most critical issue.
````

## Notes & tips

- For a diff review, set `{{CODE_TYPE}}` to `diff` and paste `git diff HEAD`
  output directly. The model handles unified diff format well.
- If the model flags many minor style issues, add to `{{ADDITIONAL_FOCUS}}`:
  "Focus on correctness and security only. Skip style findings."
- The output of this prompt is a natural input for
  `skills/coding/debug-issue/` (for bug findings) or
  `skills/coding/implement-feature/` (for structural improvements).
- Related prompts:
  [`testing/review-test-coverage.md`](../testing/review-test-coverage.md),
  [`code/refactor-for-readability.md`](./refactor-for-readability.md)
- Related skills:
  [`skills/coding/debug-issue/`](../../skills/coding/debug-issue/),
  [`skills/coding/implement-feature/`](../../skills/coding/implement-feature/)
