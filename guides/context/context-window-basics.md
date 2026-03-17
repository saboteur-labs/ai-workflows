# Context window basics

A practical reference for understanding context windows and how they affect
AI-augmented workflows. Knowing this prevents the most common failure mode:
sending more content to a model than it can handle, or than it can reason over
effectively.

---

## What is a context window?

A context window is the maximum amount of text a model can hold in "working
memory" at one time. Everything the model can see — the system prompt, the
conversation history, the file you pasted, the instructions you gave — must
fit within this limit.

When content exceeds the limit, one of three things happens depending on the
tool:

- **Hard cutoff** — the request is rejected with an error
- **Silent truncation** — the oldest content is dropped without warning,
  causing the model to "forget" earlier instructions or context
- **Degraded reasoning** — the content fits, but the model loses coherence
  near its limit and produces lower-quality output

The third case is the most dangerous because it fails silently.

---

## How context windows are measured

Context is measured in **tokens**, not characters or words. Tokenization varies
by model family, but a useful rule of thumb:

| Content type                      | Approximate token count |
| --------------------------------- | ----------------------- |
| 1 English word                    | ~1.3 tokens             |
| 1 line of code                    | ~5–10 tokens            |
| 1 KB of plain text                | ~200–250 tokens         |
| 1 KB of code                      | ~150–200 tokens         |
| A short prompt (100 words)        | ~130 tokens             |
| A medium prompt (500 words)       | ~650 tokens             |
| A typical source file (200 lines) | ~1,000–2,000 tokens     |

These are estimates. Dense code (TypeScript with generics, regex-heavy files)
runs higher; simple prose runs lower.

---

## What consumes the context window

In a typical AI-assisted workflow, the context window is consumed by:

1. **System prompt / skill** — the instructions telling the model how to behave
2. **Conversation history** — all previous messages in the session
3. **Injected files or content** — source files, docs, specs you paste in
4. **Tool call results** — outputs from web search, code execution, etc.
5. **The model's own responses** — in multi-turn sessions, prior responses
   also consume context

This means context pressure compounds over a long session. A model that
reasoned well at the start of a conversation may degrade by turn 10 as history
accumulates.

---

## Context window sizes by model tier

Different models have very different context limits. This directly affects
which prompts and skills from this repo are viable in your current setup.

| Model tier                     | Typical context window | Practical usable context      |
| ------------------------------ | ---------------------- | ----------------------------- |
| Small local (7B)               | 2k–8k tokens           | 1k–4k (leave room for output) |
| Mid local (13B–30B)            | 4k–32k tokens          | 2k–16k                        |
| Large local (70B+)             | 8k–128k tokens         | 4k–64k                        |
| Hosted (Claude, GPT-4, Gemini) | 32k–200k+ tokens       | 16k–180k+                     |

"Practical usable context" is lower than the advertised limit because:

- The model needs room to produce its response (output tokens count too)
- Reasoning quality tends to degrade when the window is near capacity
- System prompts and history take up some of the budget before you add content

**Rule of thumb:** assume you have roughly half the advertised context window
available for your actual task content.

---

## The context budget system in this repo

Every prompt and skill in this repo is tagged with a `context_budget` field:

| Budget   | What it means                                                                                                        |
| -------- | -------------------------------------------------------------------------------------------------------------------- |
| `low`    | The prompt/skill itself uses ~1–2k tokens. Safe for any model. Leave enough room for your task content.              |
| `medium` | Uses ~2–8k tokens for instructions alone. Requires a 13B+ local model or any hosted model.                           |
| `high`   | Uses 8k+ tokens. Designed for hosted models or high-VRAM local setups. Always check if a `low` variant exists first. |

This budget covers **the prompt or skill instructions only** — not the task
content you add (the file you paste, the spec you reference, etc.). Factor
in your task content separately.

For a practical decision tree, see
[`context-budget-guide.md`](./context-budget-guide.md).

---

## Common failure patterns

**The vanishing instruction problem**
Long sessions accumulate history until early system instructions scroll out of
the context window. The model stops following rules it was given at the start.
Fix: keep system prompts short (`low` budget skills), summarize and restart
sessions periodically, or use a model with a larger context window.

**The big file problem**
Pasting a 1,000-line source file into a chat session consumes ~5,000–10,000
tokens before you've said anything. On a 7B local model with an 8k window,
that leaves almost nothing for instructions or response.
Fix: use `tools/chunk-file.sh` to split the file and process it in sections.
See [`low-memory-workarounds.md`](./low-memory-workarounds.md).

**The long prompt problem**
A detailed, comprehensive prompt is tempting — but on small models it can crowd
out the actual task content. A 3,000-token prompt leaves little room for a
file review on a model with a 4k window.
Fix: use the `-minimal` skill variant or the `low` context budget prompt
variant where available.

**The compounding history problem**
Every response the model produces gets added back to history, gradually filling
the window. This is subtle — the session feels fine until suddenly the model
seems confused or ignores earlier instructions.
Fix: start a new session for new tasks, or use a tool that supports session
summarization.

---

## Further reading

- [`chunking-strategies.md`](./chunking-strategies.md) — how to split content
  to fit within context limits
- [`low-memory-workarounds.md`](./low-memory-workarounds.md) — specific
  techniques for small local models
- [`context-budget-guide.md`](./context-budget-guide.md) — decision tree for
  choosing the right prompt/skill for your setup
- [`../models/local-vs-remote.md`](../models/local-vs-remote.md) — when to
  use a local model vs a hosted one
