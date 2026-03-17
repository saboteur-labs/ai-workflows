# Model selection guide

How to choose the right model for a given task. This guide covers the
capability profiles that matter for AI-augmented development work, how
model size and quantization affect those profiles, and a set of selection
criteria you can apply without knowing specific model names.

This guide is evergreen — it covers principles rather than specific models,
which change frequently. Apply these criteria to whatever models are
currently available in your setup.

---

## The four capability profiles that matter

Not all tasks need the same thing from a model. Development workflows draw
on four distinct capability profiles, and models vary significantly in how
well they serve each one.

### 1. Instruction following

The ability to do exactly what was asked — no more, no less — and to
maintain those instructions across a multi-turn session.

This is the most important capability for prompt-based workflows. A model
that follows instructions reliably at 13B parameters will outperform a
model that ignores them at 70B. When evaluating a new model, test this
first: give it a prompt with specific constraints and check whether it
honours them.

Signs of weak instruction following:

- Adds unrequested content ("I also noticed...")
- Ignores format requirements (asked for JSON, returns prose)
- Rewrites code it was told to leave unchanged
- Loses track of constraints after a few turns

### 2. Code generation and editing

The ability to produce syntactically correct, idiomatic code in the target
language, and to make targeted edits without breaking surrounding code.

Code-focused models (those trained or fine-tuned on large code corpora)
perform significantly better on this profile than general-purpose models of
the same size. A code-focused 7B model will often outperform a general
13B model on pure code tasks.

Key sub-capabilities:

- Correct syntax and type usage for the language
- Matching the style and patterns of surrounding code
- Making surgical edits (changing one function without touching others)
- Understanding imports, dependencies, and module boundaries

### 3. Reasoning and planning

The ability to decompose a problem, consider trade-offs, and produce a
logical plan before acting. Matters for spec writing, architectural
decisions, task breakdown, and debugging complex issues.

This profile scales more strongly with model size than the others. Small
models can follow a provided plan reliably but struggle to produce a
good plan from a vague brief. If planning quality matters, this is where
a larger or hosted model earns its cost.

Signs of weak reasoning:

- Proposes plans that contradict the stated requirements
- Misses obvious dependencies between tasks
- Produces spec sections that conflict with each other
- Debugging suggestions that don't address the actual error

### 4. Long-context coherence

The ability to reason correctly over large inputs — a full source file,
a long spec, multiple files in context — without losing track of earlier
content or producing contradictions.

This profile is partly a function of context window size (hardware) and
partly a function of how well the model was trained on long-context data.
Two models with the same `n_ctx` setting can differ substantially in how
coherently they reason over long inputs.

Signs of weak long-context coherence:

- References to content from earlier in the input that are incorrect
- Contradicts constraints stated at the start of a long prompt
- Loses awareness of earlier functions when reviewing later ones
- Produces code that re-implements utilities defined earlier in the file

---

## How model size affects each profile

| Profile                | Scales with size? | Notes                                          |
| ---------------------- | ----------------- | ---------------------------------------------- |
| Instruction following  | Weakly            | Training and fine-tuning matter more than size |
| Code generation        | Moderately        | Code-specific training matters more than size  |
| Reasoning and planning | Strongly          | Biggest gains from moving to larger models     |
| Long-context coherence | Moderately        | Architecture and training data matter too      |

The practical implication: for code generation and instruction following,
a well-trained small model is often competitive with a larger general model.
For reasoning, planning, and long-context tasks, larger is genuinely better.

---

## How quantization affects quality

Quantization reduces a model's memory footprint by using lower-precision
weights. It trades some quality for the ability to run on consumer hardware.

| Quantization | Quality impact                             | Use when                                   |
| ------------ | ------------------------------------------ | ------------------------------------------ |
| Q8 (8-bit)   | Minimal — near full quality                | You have the RAM and want best quality     |
| Q5 (5-bit)   | Small — barely noticeable on most tasks    | Good balance if RAM is moderate            |
| Q4 (4-bit)   | Moderate — noticeable on complex reasoning | Best size-to-quality ratio for most setups |
| Q3 and below | Significant — avoid for code tasks         | Only if RAM is severely constrained        |

For the workflows in this repo, Q4 is the recommended default. The quality
difference between Q4 and Q8 is small for instruction following and code
generation; it becomes more noticeable on complex reasoning tasks. If your
primary use is code review and generation, Q4 is sufficient. If you're doing
architectural planning and spec work, Q5 or Q8 is worth the extra RAM.

---

## Matching model to task

Use this as a starting point when selecting a model for a specific workflow:

| Task type                 | Priority profile                 | Minimum size recommendation                    |
| ------------------------- | -------------------------------- | ---------------------------------------------- |
| Code generation from spec | Instruction following, Code      | Smallest code-focused model that fits          |
| Code review               | Code, Long-context coherence     | Mid-size; larger if files are long             |
| Unit test generation      | Instruction following, Code      | Same as code generation                        |
| Feature spec writing      | Reasoning, Instruction following | Mid-size or hosted for best results            |
| Task breakdown            | Reasoning                        | Mid-size; hosted for complex projects          |
| Debugging                 | Reasoning, Code                  | Mid-size; larger for complex bugs              |
| Refactoring               | Code, Instruction following      | Small to mid; test instruction adherence first |
| Architecture decisions    | Reasoning, Long-context          | Hosted preferred                               |
| Summarisation / handoff   | Instruction following            | Any size                                       |

"Mid-size" means a model that fits comfortably in your RAM at Q4 while
leaving meaningful headroom — not the largest model you can just barely load.
A model under memory pressure runs slowly and may truncate context silently.

---

## A simple evaluation process for a new model

When you download a new model, run these three tests before committing to it
for development work:

**Test 1: instruction adherence**
Give it a prompt with three specific constraints — a format requirement, a
content restriction, and a length limit. Check whether all three are honoured.

```
Write a function that reverses a string in TypeScript.
Constraints:
- Use a `for` loop, not built-in methods
- Do not add comments
- Maximum 10 lines
```

**Test 2: targeted code editing**
Give it a function and ask it to change one specific thing without touching
anything else. Check whether it makes only the requested change.

```
In the following function, change the error message from "Not found" to
"Resource not found". Do not change anything else.

[paste a function]
```

**Test 3: short planning task**
Give it a small, concrete feature description and ask for a numbered
implementation plan. Check whether the plan is logical, complete, and
free of contradictions.

```
I need to add rate limiting to an Express API. The limit should be
100 requests per IP per minute. Requests over the limit should receive
a 429 response with a Retry-After header.

Write a numbered implementation plan (no code yet).
```

A model that passes all three cleanly is suitable for the workflows in
this repo. A model that fails test 1 — ignoring explicit constraints — is
not suitable regardless of how well it performs on the others.

---

## When to switch to a hosted model

The decision criteria are covered in detail in
[`local-vs-remote.md`](./local-vs-remote.md). In brief, switch to hosted
when:

- The task requires complex reasoning and your local model's planning quality
  is producing weak specs or plans
- The input is larger than your local context window after chunking
- The data is non-sensitive and output quality is the primary concern

For development tasks involving proprietary code or internal data, stay
local even if quality suffers — and improve quality through better prompting,
chunking, and the `-minimal` skill variants rather than by routing sensitive
data to a remote model.

---

## Further reading

- [`local-vs-remote.md`](./local-vs-remote.md) — when to use local vs hosted
- [`lm-studio-setup.md`](./lm-studio-setup.md) — loading and configuring
  models in LM Studio
- [`../context/context-budget-guide.md`](../context/context-budget-guide.md)
  — matching context window size to task requirements
