# Example: spec to implementation

A complete worked example of taking a feature idea from rough description
to implemented, tested code using the prompts and skills in this repo.

**Feature used in this example:** User activity CSV export — a user can
export their activity history from the account settings page as a
downloadable CSV file.

This feature is deliberately chosen to be realistic but small: it touches
a service layer, a route handler, and test coverage, without being so
large that the example becomes unwieldy. The same pipeline applies to
any feature of similar scope.

---

## What this example covers

The full chain from idea to tested implementation:

| Step | File                                                 | Prompt / skill                           |
| ---- | ---------------------------------------------------- | ---------------------------------------- |
| 1    | [`01-write-spec.md`](./01-write-spec.md)             | `prompts/planning/write-feature-spec.md` |
| 2    | [`02-break-into-tasks.md`](./02-break-into-tasks.md) | `prompts/planning/break-into-tasks.md`   |
| 3    | [`03-scaffold-module.md`](./03-scaffold-module.md)   | `prompts/code/scaffold-module.md`        |
| 4    | [`04-generate-tests.md`](./04-generate-tests.md)     | `prompts/code/generate-unit-tests.md`    |

Human review gates are marked in each step. Each file shows the prompt
sent (with placeholders filled in), the model output, and what to check
before moving to the next step.

---

## How to use this example

Read each step in order before using any of the prompts in a real project.
Seeing the full pipeline first makes each individual prompt easier to use
correctly — you'll know what good output looks like and what to do when
it isn't right.
