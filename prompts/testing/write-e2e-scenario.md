---
title: Write an end-to-end test scenario
category: testing
tags: [e2e, integration, scenario, playwright, cypress, acceptance-test]
context_budget: low
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2025-01-01
      note: Initial version
---

# Write an end-to-end test scenario

Writes an end-to-end test scenario for a user-facing feature. Can produce
plain-language scenarios for manual testing or review, or test code in a
specified framework. Use plain language first to validate the scenario
logic before writing code.

E2E tests verify that a feature works from the user's perspective —
they test the full stack, not individual functions. Use unit tests
(`code/generate-unit-tests.md`) for logic and e2e tests for user journeys.

## When to use

- Defining acceptance tests for a feature before or after implementation
- Manual testing scripts for QA review
- Automated e2e test code for critical user journeys
- NOT for testing individual functions or modules — use unit tests
- NOT for API contract testing — those are integration tests, not e2e

## Interfaces

| Interface | Notes                                                                                               |
| --------- | --------------------------------------------------------------------------------------------------- |
| IDE       | Good for generating test files directly. Reference the relevant page or component with `@filename`. |
| Chat      | Start with plain-language output, iterate, then ask for code.                                       |
| CLI       | Pipe a feature description to get a quick scenario draft.                                           |
| API       | Use for generating e2e test scaffolds from spec data.                                               |

## Prompt

```
Write an end-to-end test scenario for the following feature.

Feature: {{FEATURE_DESCRIPTION}}

{{#if ACCEPTANCE_CRITERIA}}
Acceptance criteria:
{{ACCEPTANCE_CRITERIA}}
{{/if}}

Output format: {{OUTPUT_FORMAT}}

{{#if OUTPUT_FORMAT == "plain language"}}
Write the scenario in plain language using this structure:

### Scenario: [descriptive name]
**Given** [initial state / preconditions]
**When** [user action(s)]
**Then** [expected outcomes — one per bullet]

**Edge cases to also test:**
- [brief description of each variant or error path]

Cover:
1. The primary happy path — the user successfully completes the intended action
2. At least one validation or error path — the user does something invalid
   and receives appropriate feedback
3. Any state changes that should persist after the action completes
{{/if}}

{{#if OUTPUT_FORMAT != "plain language"}}
Write a complete test file in {{OUTPUT_FORMAT}}.

Requirements:
- One describe block for the feature
- One test per scenario (happy path + each error path)
- Use data-testid selectors where possible — not CSS classes or XPath
- Assertions must verify observable outcomes (page content, URL, network
  requests) not implementation details
- Include setup and teardown if state needs to be seeded or cleaned
- Add a comment above each test with the scenario name in plain language

Assume the app runs at `{{BASE_URL}}` (default: `http://localhost:3000`).
{{/if}}
```

### Placeholders

| Placeholder               | Description                                                                         | Example                                                                                    |
| ------------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `{{FEATURE_DESCRIPTION}}` | Description of the user-facing feature                                              | `User can export their activity history as a CSV file from the account settings page`      |
| `{{ACCEPTANCE_CRITERIA}}` | Optional. Specific acceptance criteria to test against. Remove block if not needed. | _(paste acceptance criteria from the spec)_                                                |
| `{{OUTPUT_FORMAT}}`       | What to produce                                                                     | `plain language`, `Playwright (TypeScript)`, `Cypress (JavaScript)`, `Playwright (Python)` |
| `{{BASE_URL}}`            | Base URL for the app under test. Only relevant for code output.                     | `http://localhost:3000`                                                                    |

## Low-context variant

This prompt is already `context_budget: low`. No low-context variant needed.

## Notes & tips

- Always produce plain-language scenarios first and validate them against
  the spec before generating code. Code that implements the wrong scenario
  is harder to fix than prose that describes the wrong scenario.
- For Playwright and Cypress, the model will use common selector patterns.
  If your app uses a specific selector strategy, add to the prompt:
  "Use `data-testid` attributes exclusively. Our convention is
  `data-testid='[component]-[action]'`, e.g. `data-testid='export-button'`."
- E2E tests that depend on specific test data should seed that data in
  `beforeEach` and clean it up in `afterEach`. If the model doesn't include
  this, add: "Add `beforeEach`/`afterEach` hooks to seed and clean test data."
- Related prompts:
  [`testing/generate-test-cases.md`](./generate-test-cases.md),
  [`code/generate-unit-tests.md`](../code/generate-unit-tests.md),
  [`planning/write-feature-spec.md`](../planning/write-feature-spec.md)
