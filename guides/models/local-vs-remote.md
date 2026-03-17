# Local vs remote models

A practical guide to deciding when to run a model locally versus using a
hosted service. Both have genuine strengths — the right choice depends on
the task, the data, and the constraints of your current environment.

This guide is evergreen: it covers decision criteria rather than specific
model names or pricing, which change frequently.

---

## The core trade-off

Local and remote models differ on five dimensions. No option wins on all five.

| Dimension          | Local                                  | Remote (hosted)                        |
| ------------------ | -------------------------------------- | -------------------------------------- |
| **Privacy**        | Data never leaves your machine         | Data sent to a third party             |
| **Cost**           | Hardware up front, near-zero per-query | Pay-per-token, no hardware cost        |
| **Capability**     | Constrained by hardware                | Access to the largest available models |
| **Context window** | Limited by RAM; typically 8k–32k       | Large to very large; 32k–200k+         |
| **Latency**        | Fast for small models; slow for large  | Network overhead; fast for most tasks  |
| **Availability**   | Works offline                          | Requires internet and account          |

The tension is almost always between **privacy/cost** (local wins) and
**capability/context** (remote wins). Most real workflows end up using both.

---

## When to use a local model

### Privacy-sensitive work

Any task involving code, data, or documents that cannot leave your
environment — proprietary source code, customer data, internal
specifications, unreleased product details — should default to local.

This is a hard requirement, not a preference. Check your organisation's
data handling policy if unsure.

### Offline or air-gapped environments

If your development environment doesn't have reliable internet access, or
operates behind a strict firewall, local is the only option.

### High-frequency, low-complexity tasks

For tasks you run many times a day — inline code completion, short
explanations, quick rewrites — a fast local model has lower latency than
a round-trip to a hosted API, and the per-query cost of a hosted model
accumulates quickly for high-frequency use.

### Experimentation and iteration

When you're iterating rapidly on a prompt or skill — running it 20 times
to refine output — local avoids API costs during the experimental phase.
Finalise on hosted once the prompt is stable.

---

## When to use a remote (hosted) model

### Tasks that exceed local context limits

If your task requires more context than your local setup can handle — a
large codebase, a long specification, a multi-file review — a hosted model
with a large context window is the practical choice unless you can chunk
the content down to fit locally.

Calculate your available local budget first
([`../context/context-budget-guide.md`](../context/context-budget-guide.md)).
If chunking would require more than 3–4 passes, remote is usually faster
and produces more coherent output.

### Tasks requiring strongest available capability

Some tasks — complex architectural reasoning, nuanced code review, subtle
spec ambiguities — benefit from the largest available models, which exceed
what can be run locally on consumer hardware. Use remote for tasks where
output quality is the primary concern and the data permits it.

### High-context skills and `high`-budget prompts

Any prompt or skill tagged `context_budget: high` is designed for hosted
models. Running it locally requires hardware most developers don't have.
Use the `-minimal` skill variant or a `low`-budget prompt locally instead.

### Final review and polish passes

A common hybrid pattern: draft locally (fast, private, free), then do a
final quality pass on a hosted model (best capability, larger context).
The draft doesn't need to be perfect — it just needs to be good enough
to send to the hosted model with a focused improvement prompt.

---

## The hybrid approach

Local and remote are not mutually exclusive. A practical hybrid workflow:

```
Local model (fast, private)
  → First draft, exploration, iteration, high-frequency tasks

Remote model (capable, large context)
  → Final review, complex reasoning, large-context tasks, polish
```

Concretely:

- **Write and iterate** on specs, prompts, and code locally
- **Review and critique** the result on a hosted model when quality matters
- **Use local** for any content that cannot leave your environment, even if
  quality suffers — then sanitise and re-run remotely if a quality pass is
  needed on a redacted version

---

## Decision checklist

Work through this before choosing where to run a task.

**1. Can this data leave my machine?**

- No → Local only. Full stop.
- Yes → Continue.

**2. Does the task fit in my local context budget?**

- Yes → Local is viable. Continue to step 3.
- No → Can I chunk the content to fit?
    - Yes → Local with chunking (see
      [`../context/chunking-strategies.md`](../context/chunking-strategies.md))
    - No → Remote.

**3. Does the task require the strongest available capability?**

- No → Local.
- Yes → Remote (or hybrid: draft locally, polish remotely).

**4. How often will I run this task?**

- Many times per day → Local (latency and cost).
- Occasionally → Either; remote if quality matters more.

---

## Switching between local and remote

Because all prompts and skills in this repo are model-agnostic, switching
between local and remote requires only changing the endpoint your tool
points at — not the prompt or skill itself.

**In IDE plugins:** change the API base URL in settings.

**In CLI tools:** change the `--base-url` or equivalent flag, or swap
environment variables.

**In scripts:** change the `baseURL` passed to the OpenAI client.

Keep local and remote configurations in separate environment files (e.g.
`.env.local` and `.env.remote`) so switching is a one-line change:

```sh
# .env.local
OPENAI_API_BASE=http://localhost:1234/v1
OPENAI_API_KEY=placeholder
OPENAI_MODEL=local-model

# .env.remote
OPENAI_API_BASE=https://api.anthropic.com  # or openai, etc.
OPENAI_API_KEY=your-real-key
OPENAI_MODEL=your-chosen-model
```

```sh
# Switch by sourcing the right file
source .env.local   # use local model
source .env.remote  # use remote model
```

---

## Further reading

- [`lm-studio-setup.md`](./lm-studio-setup.md) — setting up a local
  model server and connecting tools to it
- [`model-selection-guide.md`](./model-selection-guide.md) — choosing
  the right model size and type for a task
- [`../context/context-budget-guide.md`](../context/context-budget-guide.md)
  — deciding which prompt/skill tier fits your current setup
- [`../context/low-memory-workarounds.md`](../context/low-memory-workarounds.md)
  — making the most of constrained local setups
