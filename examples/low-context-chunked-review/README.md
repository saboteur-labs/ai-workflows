# Example: low-context chunked review

A worked example of reviewing a large source file on a small local model
by splitting it into chunks and processing each one separately, then
consolidating the results.

**Scenario:** You have a 450-line TypeScript service file that you want
to review before merging. Your local model has an 8k context window. The
file is too large to review in one pass — you need to chunk it.

---

## What this example covers

| Step | File                                           | Tool / prompt                                                                          |
| ---- | ---------------------------------------------- | -------------------------------------------------------------------------------------- |
| 1    | [`01-chunk-file.md`](./01-chunk-file.md)       | `tools/chunk-file.sh`                                                                  |
| 2    | [`02-review-chunks.md`](./02-review-chunks.md) | `prompts/code/code-review.md` + `prompts/agent-orchestration/summarize-for-handoff.md` |

---

## When to use this pattern

- Any file too large to fit within your available context budget
- Any time you're using a local model with a small context window
- As a cost-saving measure on hosted models: review chunks locally,
  only escalate complex findings to hosted for deeper analysis

For the decision of whether to chunk or use a larger model, see
[`guides/context/context-budget-guide.md`](../../guides/context/context-budget-guide.md).
