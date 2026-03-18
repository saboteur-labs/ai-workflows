---
title: Generate unit tests for a module
category: code
tags: [unit-test, testing, jest, pytest, vitest, mocha]
context_budget: medium
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2025-03-17
      note: Initial version
---

# Generate unit tests for a module

Given a source file or module, generates a comprehensive unit test suite
covering happy paths, edge cases, and failure modes. Produces idiomatic tests
in the framework and language of the source file.

Use this when you have a completed or near-complete module and want to build
test coverage from scratch. Not suitable for integration or end-to-end tests —
see `testing/write-e2e-scenario.md` for those.

## When to use

- You have a module or set of functions with no existing tests
- You want a first-pass test suite to iterate from
- You're reviewing someone else's code and want to understand its behaviour
  through tests
- NOT for files over ~300 lines — chunk the file first and run this prompt
  per logical unit (see
  [`guides/context/low-memory-workarounds.md`](../../guides/context/low-memory-workarounds.md))
- NOT when you need integration, contract, or e2e tests

## Interfaces

| Interface | Notes                                                                                                                                                              |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| IDE       | Paste the prompt into the chat panel with the source file open or attached. In Cursor, use `@file` to reference the file directly instead of pasting its contents. |
| Chat      | Paste the source file contents into `{{SOURCE_CODE}}` before sending.                                                                                              |
| CLI       | Pipe the source file via stdin: `cat src/utils.ts \| sed "s/{{SOURCE_CODE}}/$(cat)/g" prompt.md \| aider --message -`                                              |
| API       | Use as a `user` message. Pass the source file content programmatically into `{{SOURCE_CODE}}`.                                                                     |

## Prompt

````
I need unit tests for the following {{LANGUAGE}} code.

Framework: {{TEST_FRAMEWORK}}

Source code:
```{{LANGUAGE}}
{{SOURCE_CODE}}
```

Generate a complete unit test file that:

1. Covers all exported functions and classes
2. Tests the happy path for each function
3. Tests edge cases: empty inputs, null/undefined, boundary values, type
   coercion where relevant
4. Tests failure modes: invalid inputs, thrown errors, rejected promises
5. Uses mocks/stubs only where the code has genuine external dependencies
   (network calls, file system, database). Do not mock internal logic.
6. Groups related tests in describe blocks named after the function or class
   being tested
7. Uses descriptive test names in the format:
   "[function name] [condition] [expected outcome]"
   e.g. "parseDate returns null when given an empty string"

Output the complete test file only. No explanations outside the file.
Include import statements. Assume the test file lives at the same directory
level as the source file.

{{ADDITIONAL_INSTRUCTIONS}}
````

### Placeholders

| Placeholder                   | Description                                                               | Example                                                                                                                |
| ----------------------------- | ------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `{{LANGUAGE}}`                | Programming language of the source file                                   | `TypeScript`, `Python`, `JavaScript`                                                                                   |
| `{{TEST_FRAMEWORK}}`          | Test framework to use                                                     | `Jest`, `Pytest`, `Vitest`, `Mocha + Chai`                                                                             |
| `{{SOURCE_CODE}}`             | Full contents of the source file to test                                  | _(paste file contents)_                                                                                                |
| `{{ADDITIONAL_INSTRUCTIONS}}` | Any project-specific conventions or constraints. Remove the line if none. | `Use our custom \`renderHook\` helper from \`test-utils\`. All async tests must use \`async/await\`, not \`.then()\`.` |

## Low-context variant

Use when `context_budget: medium` is too large for your setup. Removes
framework-specific detail and output constraints. Expect less structured
output; you may need to clean up the result.

````
Write unit tests for this {{LANGUAGE}} code using {{TEST_FRAMEWORK}}.

Cover: happy paths, edge cases, error cases.
Use mocks only for external I/O.

```{{LANGUAGE}}
{{SOURCE_CODE}}
```

Output the test file only, with imports.
````

## Notes & tips

- If the model produces tests that mock internal logic (e.g. mocking a helper
  function defined in the same file), add: "Do not mock any functions defined
  in this file. Only mock external dependencies."
- For large classes, run the prompt once per method group rather than the
  whole class at once.
- If the source file has no type annotations and the model produces incorrect
  type assumptions, add a types summary to `{{ADDITIONAL_INSTRUCTIONS}}`:
  "The `userId` parameter is always a string UUID, never a number."
- Generated tests often need minor fixes (import paths, mock setup). Treat
  output as a strong first draft, not final code.
- Related prompts:
  [`testing/review-test-coverage.md`](../testing/review-test-coverage.md),
  [`testing/generate-test-cases.md`](../testing/generate-test-cases.md)
- Related skills:
  [`skills/coding/implement-feature/`](../../skills/coding/implement-feature/)
