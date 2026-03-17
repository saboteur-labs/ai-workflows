# Context budget guide

A practical decision tree for choosing the right prompt or skill given your
current setup. Answers the question: **which context budget tier can I
actually use right now?**

This guide pairs with the `context_budget` and `context-budget` fields in
every prompt and skill in this repo. Understanding those fields is covered in
[`context-window-basics.md`](./context-window-basics.md) — read that first
if you're new to context window management.

---

## The three tiers

| Tier     | Prompt/skill size | Total context needed | Suitable for                            |
| -------- | ----------------- | -------------------- | --------------------------------------- |
| `low`    | ~1–2k tokens      | ~3–4k tokens         | Any model, including small local models |
| `medium` | ~2–8k tokens      | ~8–16k tokens        | Mid-size local models, any hosted model |
| `high`   | 8k+ tokens        | 16k+ tokens          | Hosted models or high-VRAM local setups |

"Total context needed" = prompt/skill size + your task content + response
buffer. The tier label only describes the prompt or skill itself — your task
content is on top of that.

---

## Step 1: establish your available context

Before choosing a tier, know your actual budget. Use this formula:

```
Available context = model context window
                  − response buffer       (reserve ~1,000–2,000 tokens)
                  − conversation history  (0 for a fresh session)
                  − system prompt / skill (~500–4,000 tokens depending on tier)
```

**Quick estimates by model class:**

| Model class        | Advertised window | Practical task budget |
| ------------------ | ----------------- | --------------------- |
| Small local (≤8B)  | 2k–8k             | 1k–4k                 |
| Mid local (9B–30B) | 4k–32k            | 3k–16k                |
| Large local (31B+) | 8k–128k           | 6k–80k                |
| Hosted (any)       | 32k–200k+         | 20k–180k+             |

If you don't know your model's context window, check the model card or your
inference tool's settings. In LM Studio, it's the `n_ctx` parameter.

---

## Step 2: estimate your task content size

Before sending, estimate how many tokens your task content will consume.

```sh
# Quick estimate from file size
wc -c myfile.ts | awk '{printf "~%d tokens\n", $1/4}'

# Dry-run with chunk-file.sh to see exact estimates
./tools/chunk-file.sh --stats myfile.ts
```

**Rules of thumb:**

| Content                               | Token estimate      |
| ------------------------------------- | ------------------- |
| A short description (1–3 sentences)   | ~30–80 tokens       |
| A spec or ADR                         | ~300–800 tokens     |
| A typical source file (100–300 lines) | ~500–2,000 tokens   |
| A large source file (300–1,000 lines) | ~2,000–7,000 tokens |
| A full git diff (small PR)            | ~500–3,000 tokens   |

---

## Step 3: decision tree

Work through this from top to bottom. Stop at the first match.

```
Is your task content small (< 1,000 tokens)?
  └─ Yes → Use any tier. Start with `low` for speed; use `medium` if
            the low prompt produces weak output.
  └─ No  ↓

Does your total (task content + low-tier prompt ~1,500 tokens) fit in
your available context budget?
  └─ Yes → Use `low` tier.
  └─ No  ↓

Does your total (task content + medium-tier prompt ~4,000 tokens) fit?
  └─ Yes → Are you on a hosted model or a local model ≥ 13B with ≥ 16k
            context?
              └─ Yes → Use `medium` tier.
              └─ No  → Use `low` tier. Expect less structured output.
                        Consider chunking the task content instead.
  └─ No  ↓

Task content is large. Options:
  A) Chunk the content and use `low` tier per chunk
     → See chunking-strategies.md
  B) Use `high` tier on a hosted model (if privacy permits)
  C) Summarise or extract the relevant section before sending
     → See low-memory-workarounds.md, Technique 3
```

---

## Step 4: when a lower tier produces weak output

Using `low` instead of `medium` means the model gets less instructional
detail. Common symptoms and fixes:

| Symptom                                 | Fix                                                                      |
| --------------------------------------- | ------------------------------------------------------------------------ |
| Tests lack edge cases                   | Add to the prompt: "Include at least two edge cases per function."       |
| Code doesn't follow project conventions | Paste a short conventions snippet as additional context                  |
| Output is generic / boilerplate         | Add a concrete example of expected output to the prompt                  |
| Model ignores specific instructions     | The instruction was likely trimmed; switch to `medium` if context allows |

The general rule: if you're on `low` and the output isn't good enough, the
next step is to add one or two specific instructions to the prompt before
escalating to `medium`. Targeted additions are cheaper than a full tier
upgrade.

---

## Step 5: the -minimal skill variant

Every `medium` and `high` skill in this repo has a `-minimal` sibling
directory. The minimal variant runs at `low` budget.

Use the minimal variant when:

- Your model class requires it (small local)
- Your task content is large enough that `medium` won't fit even on a
  capable model
- You want to do a fast first pass before deciding whether a full
  `medium` run is worth it

```sh
# Full skill
./tools/fetch-prompt.sh --skill coding/implement-feature

# Minimal variant
./tools/fetch-prompt.sh --skill coding/implement-feature-minimal
```

---

## Quick reference card

Print or bookmark this table for daily use.

| Setup                       | Max comfortable tier                      | Notes                                                      |
| --------------------------- | ----------------------------------------- | ---------------------------------------------------------- |
| Small local, ≤ 8k context   | `low` only                                | Chunk anything over ~3k tokens                             |
| Small local, 8k–16k context | `low`; `medium` for small tasks           | Watch session history accumulation                         |
| Mid local, 16k–32k context  | `medium` comfortably                      | `high` on hosted only                                      |
| Large local, 32k+ context   | `medium` always; `high` for small content |                                                            |
| Any hosted model            | All tiers                                 | Use `high` only when `medium` produces insufficient output |
| Fresh session               | One tier higher than a loaded session     | History costs nothing at turn 0                            |
| Session with 5+ turns       | Drop one tier as a precaution             | History has accumulated                                    |

---

## Further reading

- [`context-window-basics.md`](./context-window-basics.md) — how context
  windows work and what consumes them
- [`chunking-strategies.md`](./chunking-strategies.md) — splitting large
  task content to stay within budget
- [`low-memory-workarounds.md`](./low-memory-workarounds.md) — additional
  techniques for constrained environments
- [`../models/lm-studio-setup.md`](../models/lm-studio-setup.md) — finding
  and setting `n_ctx` in LM Studio
