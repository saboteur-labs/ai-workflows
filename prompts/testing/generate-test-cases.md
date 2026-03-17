---
title: Generate test cases for a feature or function
category: testing
tags: [test-cases, testing, qa, acceptance-criteria, given-when-then]
context_budget: low
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2025-01-01
      note: Initial version
---

# Generate test cases for a feature or function

Generates a structured list of test cases — without writing test code —
for a feature, function, or set of acceptance criteria. Produces the test
thinking before the test writing, which surfaces edge cases and failure
modes that are easy to miss when going straight to code.

Use this before `prompts/code/generate-unit-tests.md`. A test case list
is faster to review than test code, and catching missing cases at this
stage is cheaper than finding them after the tests are written.

## When to use

- Before writing tests, to establish what needs to be covered
- When reviewing a spec or acceptance criteria for testability gaps
- When a feature is complex enough that test case discovery benefits from
  explicit planning
- As a QA review step: "Does this test case list cover the spec?"
- NOT when you want test code directly — use `code/generate-unit-tests.md`
- NOT for trivial functions where coverage is obvious

## Interfaces

| Interface | Notes                                                                           |
| --------- | ------------------------------------------------------------------------------- |
| IDE       | Good pre-test-writing step. Reference the spec or source file with `@filename`. |
| Chat      | Well-suited for iterative refinement: "Add cases for concurrent access."        |
| CLI       | Pipe a spec or function signature for a quick case list.                        |
| API       | Use for automated test planning in CI pipelines or PR checks.                   |

## Prompt

```
Generate a test case list for the following.

{{INPUT_TYPE}}:
{{INPUT}}

Format: {{FORMAT}}

Generate test cases covering:

1. Happy paths
   Normal, expected inputs producing correct outputs. Include the most
   common use patterns, not just the trivial base case.

2. Boundary values
   Inputs at the edges of valid ranges: empty collections, zero, maximum
   values, minimum values, single-element collections, exact limit values.

3. Invalid inputs
   Inputs that should be rejected: wrong types, null/undefined where not
   allowed, malformed data, values outside valid ranges.

4. Error conditions
   Situations that should produce errors or exceptions: missing dependencies,
   unavailable resources, permission failures, timeout conditions.

5. Edge cases specific to this {{INPUT_TYPE}}
   Non-obvious scenarios that could cause incorrect behaviour given the
   specific logic or domain involved.

For each test case, specify:
- A descriptive name (should read as a sentence: "[subject] [condition]
  [expected outcome]")
- The input or precondition
- The expected output or behaviour
- Which category it belongs to (happy path / boundary / invalid /
  error / edge case)

At the end, add:
## Coverage gaps
Any scenarios you could not cover because the {{INPUT_TYPE}} specification
is ambiguous or incomplete. If none, write "None identified."
```

### Placeholders

| Placeholder      | Description                                  | Example                                                                                         |
| ---------------- | -------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `{{INPUT_TYPE}}` | What you're generating cases for             | `function`, `feature`, `API endpoint`, `acceptance criteria`                                    |
| `{{INPUT}}`      | The spec, function signature, or description | _(paste spec, signature, or acceptance criteria)_                                               |
| `{{FORMAT}}`     | Output format for the cases                  | `numbered list`, `Given/When/Then`, `table with columns: Name \| Input \| Expected \| Category` |

## Low-context variant

This prompt is already `context_budget: low`. No low-context variant needed.

## Notes & tips

- The "Coverage gaps" section is the most valuable output when the spec is
  incomplete. Gaps in the test case list surface spec gaps before
  implementation begins.
- For API endpoints, always check that the model includes cases for: missing
  required fields, extra unexpected fields, authentication failure, and
  authorisation failure (authenticated but not permitted).
- After reviewing the test case list, pass it to
  `prompts/code/generate-unit-tests.md` as additional context:
  "Use these test cases as the basis for the test suite: [list]"
- Related prompts:
  [`code/generate-unit-tests.md`](../code/generate-unit-tests.md),
  [`testing/review-test-coverage.md`](./review-test-coverage.md),
  [`testing/write-e2e-scenario.md`](./write-e2e-scenario.md)
