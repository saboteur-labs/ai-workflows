# LM Studio setup

A configuration guide for running local models in LM Studio for
AI-augmented development. Covers model selection, server configuration,
inference settings for code tasks, and connecting to the tools and IDE
plugins used in this repo's workflows.

This guide is intentionally evergreen — it covers principles and settings
rather than specific model names or version numbers, which change frequently.
For current model recommendations, see
[`model-selection-guide.md`](./model-selection-guide.md).

---

## What LM Studio provides

LM Studio runs quantized language models locally and exposes an
OpenAI-compatible HTTP server. This means any tool that supports the OpenAI
API — IDE plugins, CLI tools, scripts — can point at LM Studio instead of a
hosted endpoint with no other changes.

The two things you configure in LM Studio for this repo's workflows:

1. **The model** — what you download and load
2. **The server** — the local endpoint your tools connect to

---

## Choosing a model

The right model depends on two hard constraints and one soft one:

**Hard constraint 1: available RAM**
The model must fit in your system RAM (or VRAM if you have a supported GPU).
A rough guide:

| Quantization | RAM per billion parameters |
| ------------ | -------------------------- |
| Q4 (4-bit)   | ~0.5 GB                    |
| Q5 (5-bit)   | ~0.6 GB                    |
| Q8 (8-bit)   | ~1.0 GB                    |

So a 7 billion parameter model at Q4 needs roughly 3.5 GB of RAM. A 13B
model at Q4 needs roughly 6.5 GB. Leave at least 2 GB free for your OS
and other processes.

**Hard constraint 2: context window**
The model's trained context window determines the maximum `n_ctx` you can
usefully set. Running with `n_ctx` higher than the model's trained limit
degrades output quality — the model was not trained to handle that length.
Check the model card for the trained context length before loading.

**Soft constraint: task type**
Models vary in how well they handle code tasks vs general instruction
following vs reasoning. See [`model-selection-guide.md`](./model-selection-guide.md)
for task-type guidance.

**General selection principles:**

- For code generation and review, prefer models explicitly trained or
  fine-tuned on code (look for "code", "coder", or "instruct" in the name)
- Instruction-following quality matters more than raw parameter count for
  the prompt-based workflows in this repo
- A smaller model that follows instructions reliably beats a larger model
  that ignores them
- When in doubt, start with the largest Q4 model your RAM comfortably fits

---

## Installing a model

1. Open LM Studio and go to the **Discover** tab
2. Search for a model by capability (e.g. "code instruct")
3. Choose a quantization that fits your RAM budget (Q4 is the best
   quality-to-size trade-off for most setups)
4. Click download — models are stored in `~/.cache/lm-studio/models/`

If you already have a GGUF file from another source, use
**File → Open Model** to load it directly.

---

## Server configuration

LM Studio's local server is what connects IDE plugins, CLI tools, and
scripts to your model. Enable it in the **Local Server** tab.

### Essential settings

| Setting                   | Recommended value               | Why                                             |
| ------------------------- | ------------------------------- | ----------------------------------------------- |
| Server port               | `1234` (default)                | Matches the default in most tool configs        |
| CORS                      | Enabled                         | Required for browser-based tools                |
| GPU layers (n_gpu_layers) | As many as your VRAM allows     | Offloads computation to GPU; 0 = CPU only       |
| Context length (n_ctx)    | Model's trained max, not higher | Exceeding trained length degrades quality       |
| Batch size (n_batch)      | `512`                           | Safe default; increase if you have RAM headroom |

### Inference settings for code tasks

These affect output quality and verbosity. Set them in the model's
**Inference Parameters** panel before starting the server.

| Setting                | Recommended value | Why                                           |
| ---------------------- | ----------------- | --------------------------------------------- |
| Temperature            | `0.1`–`0.3`       | Low = more deterministic; better for code     |
| Max tokens (n_predict) | `1024`–`2048`     | Caps response length; prevents runaway output |
| Repeat penalty         | `1.1`–`1.2`       | Reduces repetitive output                     |
| Top-P                  | `0.9`             | Leave at default unless output is erratic     |
| Top-K                  | `40`              | Leave at default                              |

For planning and spec tasks (more creative, less deterministic), raise
temperature to `0.5`–`0.7`.

### Verifying the server is running

```sh
curl http://localhost:1234/v1/models
```

Should return a JSON object listing the loaded model. If it times out,
check that the server is started in the **Local Server** tab and that
the port matches.

---

## Connecting tools to LM Studio

LM Studio exposes an OpenAI-compatible API, so any tool with an OpenAI
base URL setting can point at it.

### fetch-prompt.sh and chunk-file.sh

These tools produce prompt text to stdout — they don't call the model
directly. Pipe their output to your model CLI of choice:

```sh
# Example with a generic OpenAI-compatible CLI
./tools/fetch-prompt.sh code/generate-unit-tests \
  | your-openai-cli --base-url http://localhost:1234/v1 \
                    --model local-model
```

### Cursor

1. Open **Settings → Features → AI → Custom API**
2. Set the base URL to `http://localhost:1234/v1`
3. Set the model name to match what LM Studio reports (check
   `/v1/models` endpoint)
4. Leave the API key field blank or enter any placeholder string —
   LM Studio does not validate it

### Continue.dev

In `~/.continue/config.json`:

```json
{
    "models": [
        {
            "title": "Local model",
            "provider": "openai",
            "model": "local-model",
            "apiBase": "http://localhost:1234/v1",
            "apiKey": "placeholder"
        }
    ]
}
```

Replace `"local-model"` with the model name from the `/v1/models` endpoint.

### Aider

```sh
aider --openai-api-base http://localhost:1234/v1 \
      --openai-api-key placeholder \
      --model local-model
```

Or set environment variables to avoid repeating flags:

```sh
export OPENAI_API_BASE=http://localhost:1234/v1
export OPENAI_API_KEY=placeholder
aider --model local-model
```

### Direct API calls (scripts)

```sh
curl http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local-model",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Say hello."}
    ],
    "max_tokens": 100,
    "temperature": 0.2
  }'
```

In Node.js using the OpenAI SDK:

```js
import OpenAI from "openai";

const client = new OpenAI({
    baseURL: "http://localhost:1234/v1",
    apiKey: "placeholder",
});

const response = await client.chat.completions.create({
    model: "local-model",
    messages: [{ role: "user", content: "Say hello." }],
    max_tokens: 100,
    temperature: 0.2,
});
```

In Python:

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:1234/v1",
    api_key="placeholder",
)

response = client.chat.completions.create(
    model="local-model",
    messages=[{"role": "user", "content": "Say hello."}],
    max_tokens=100,
    temperature=0.2,
)
```

---

## Context window checklist

Before running any prompt or skill from this repo, verify:

- [ ] The model's trained context length is ≥ the n_ctx you've set
- [ ] n_ctx is set high enough for your task (prompt + content + response)
- [ ] You know the `context_budget` of the prompt/skill you're using
- [ ] Your task content fits within the available budget
      (use `./tools/chunk-file.sh --stats <file>` to estimate)

See [`context-budget-guide.md`](../context/context-budget-guide.md) for
the full decision tree.

---

## Troubleshooting

**Slow inference**

- Enable GPU offloading (increase `n_gpu_layers`) if you have a supported GPU
- Reduce `n_ctx` — larger context windows use more memory and slow inference
- Reduce `n_batch` if you're RAM-constrained

**Degraded or incoherent output on long inputs**

- You've likely exceeded the model's trained context length
- Check the model card for the trained max and reduce `n_ctx` to match
- If the content is genuinely long, chunk it — see
  [`../context/chunking-strategies.md`](../context/chunking-strategies.md)

**Model ignores instructions**

- Lower the temperature — higher values increase randomness and reduce
  instruction adherence
- Check the model supports instruction following (look for "instruct" or
  "chat" in the model name — base models do not follow instructions reliably)
- Try a smaller, sharper prompt — verbose prompts on small models can dilute
  the key instructions

**Tool can't connect to server**

- Confirm the server is started in the **Local Server** tab (green indicator)
- Check the port matches — default is `1234`
- Check CORS is enabled if connecting from a browser-based tool
- Try `curl http://localhost:1234/v1/models` to confirm the server responds

**Out of memory crash**

- The model is too large for your available RAM
- Either switch to a smaller model or a lower quantization (Q4 instead of Q8)
- Close other applications before loading

---

## Further reading

- [`local-vs-remote.md`](./local-vs-remote.md) — deciding when to use a
  local model vs a hosted one
- [`model-selection-guide.md`](./model-selection-guide.md) — choosing the
  right model size and type for a given task
- [`../context/context-budget-guide.md`](../context/context-budget-guide.md)
  — choosing the right prompt/skill tier for your setup
- [`../context/low-memory-workarounds.md`](../context/low-memory-workarounds.md)
  — techniques for constrained local setups
