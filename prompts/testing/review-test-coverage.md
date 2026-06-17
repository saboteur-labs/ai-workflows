---
title: Review test coverage and quality
description: Review an existing test suite for coverage gaps and test-quality issues. Use to find what is untested or weakly tested before relying on a suite.
category: testing
tags: [test-review, coverage, quality, gaps, assertions]
context_budget: medium
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2026-03-17
      note: Initial version
---

# Review test coverage and quality

Reviews an existing test suite against the source code it covers.
Identifies missing cases, weak assertions, redundant tests, and tests that
don't actually verify the behaviour they claim to.

Use this after generating tests with `code/generate-unit-tests.md` to
catch quality issues, or as a standalone review of a test suite that has
grown organically and may have drifted from the code it covers.

## When to use

- After AI-generated tests to validate coverage before committing
- When a test suite is passing but bugs are still escaping to production
- When refactoring source code, to check tests still cover the right things
- NOT when you have no tests and want to generate them —
  use `code/generate-unit-tests.md` instead
- NOT for files over ~200 lines of test code without chunking —
  run once per describe block or test group

## Interfaces

| Interface | Notes                                                                                                     |
| --------- | --------------------------------------------------------------------------------------------------------- |
| IDE       | Reference both files: `@source-file @test-file`. Both must be in context for the review to be meaningful. |
| Chat      | Paste both files. If both are large, paste the source and a summary of the test file's describe blocks.   |
| CLI       | Pipe both files concatenated, separated by a clear delimiter.                                             |
| API       | Pass both files as separate content blocks with labels.                                                   |

## Prompt

````
Review the test suite for the following {{LANGUAGE}} code.

Source code:
```{{LANGUAGE}}
{{SOURCE_CODE}}
```

Test code:
```{{LANGUAGE}}
{{TEST_CODE}}
```

Produce a structured coverage review:

## Missing cases
Test cases that should exist but don't. For each:
- **[function/behaviour]**: what scenario is untested and why it matters

Group by: happy paths, boundary values, error conditions, edge cases.

## Weak assertions
Tests that exist but don't verify the right thing. Common patterns:
- Tests that only check that no error is thrown, without checking output
- Tests that assert on implementation details (mocked internals) rather
  than observable behaviour
- Tests that pass vacuously (always pass regardless of the code's behaviour)
For each: test name, what it currently asserts, what it should assert.

## Redundant tests
Tests that duplicate coverage already provided by another test, or that
test behaviour that isn't meaningful to verify. List only clear redundancies.

## Test quality issues
Structural problems that make the suite harder to maintain or understand:
- Misleading test names (name doesn't match what the test checks)
- Tests with too many assertions covering unrelated concerns
- Tests that rely on test execution order
- Tests with unclear setup that obscures what's being tested

## Summary
- Coverage assessment: [strong / adequate / weak / poor]
- Most critical gap: [the single highest-priority missing case]
- Recommended action: [what to do first to improve this suite]
````

### Placeholders

| Placeholder       | Description                  | Example                |
| ----------------- | ---------------------------- | ---------------------- |
| `{{LANGUAGE}}`    | Programming language         | `TypeScript`, `Python` |
| `{{SOURCE_CODE}}` | The source file being tested | _(paste source)_       |
| `{{TEST_CODE}}`   | The existing test file       | _(paste test file)_    |

## Low-context variant

Use when both files are large. Summarise the test file first:

````
List all test names from this test file, grouped by describe block.
No other output.

```{{LANGUAGE}}
{{TEST_CODE}}
```
````

Then use the name list as `{{TEST_NAMES}}` in this reduced prompt:

````
Review coverage for this {{LANGUAGE}} source file given these existing
test names.

Source:
```{{LANGUAGE}}
{{SOURCE_CODE}}
```

Existing tests (names only):
{{TEST_NAMES}}

Identify: missing cases (most important), weak assertion patterns you'd
expect given the test names, and the single highest-priority gap.
````

## Notes & tips

- The "weak assertions" section surfaces the most common AI test generation
  failure: tests that call a function and assert the return value isn't
  null, without checking what the value actually is.
- After reviewing, pass the "Missing cases" section to
  `prompts/code/generate-unit-tests.md` as `{{ADDITIONAL_INSTRUCTIONS}}`:
  "Also add these specific test cases: [missing cases list]"
- Related prompts:
  [`code/generate-unit-tests.md`](../code/generate-unit-tests.md),
  [`testing/generate-test-cases.md`](./generate-test-cases.md)

## Skill body

A verbatim skill body (overrides the placeholder transform, since the source and
test code come from context rather than pasted fenced blocks).

```
Review the test suite for the source the user wants assessed — both the source
code and its existing tests, from this conversation or files the user references.
Infer the language from the code.

Produce a structured coverage review:

## Missing cases
Test cases that should exist but don't. For each:
- **[function/behaviour]**: what scenario is untested and why it matters

Group by: happy paths, boundary values, error conditions, edge cases.

## Weak assertions
Tests that exist but don't verify the right thing. Common patterns:
- Tests that only check that no error is thrown, without checking output
- Tests that assert on implementation details (mocked internals) rather than
  observable behaviour
- Tests that pass vacuously (always pass regardless of the code's behaviour)
For each: test name, what it currently asserts, what it should assert.

## Redundant tests
Tests that duplicate coverage already provided by another test, or that test
behaviour that isn't meaningful to verify. List only clear redundancies.

## Test quality issues
Structural problems that make the suite harder to maintain or understand:
- Misleading test names (name doesn't match what the test checks)
- Tests with too many assertions covering unrelated concerns
- Tests that rely on test execution order
- Tests with unclear setup that obscures what's being tested

## Summary
- Coverage assessment: [strong / adequate / weak / poor]
- Most critical gap: [the single highest-priority missing case]
- Recommended action: [what to do first to improve this suite]
```
