# API and scripted workflow

Patterns for calling AI models programmatically — via shell scripts, the
OpenAI SDK (Node.js and Python), and local OpenAI-compatible endpoints such
as LM Studio and Ollama. Covers system prompt injection, response parsing,
batch processing, and error handling.

---

## When to use the API directly

Use the API (rather than a CLI tool or IDE plugin) when:

- You're automating a task that runs without human interaction (CI, scheduled
  jobs, build pipelines)
- You need to process many files or inputs in a loop
- You want full control over the request — model, temperature, max tokens,
  stop sequences
- You're building a tool or script that other developers will run

For interactive use, CLI tools or IDE plugins are faster to work with. The
API is for automation.

---

## Endpoint compatibility

All prompts and skills in this repo are model-agnostic. The same request
structure works against:

| Endpoint          | Base URL                       | Notes                                        |
| ----------------- | ------------------------------ | -------------------------------------------- |
| LM Studio (local) | `http://localhost:1234/v1`     | OpenAI-compatible; no real API key needed    |
| Ollama (local)    | `http://localhost:11434/v1`    | OpenAI-compatible since v0.1.24              |
| Anthropic         | `https://api.anthropic.com/v1` | Requires Anthropic SDK or compatible wrapper |
| OpenAI            | `https://api.openai.com/v1`    | Reference implementation                     |
| Other hosted      | Varies                         | Check provider docs for base URL and auth    |

The examples below use the OpenAI SDK's base URL pattern, which works for
local endpoints and most hosted providers. For Anthropic's native API, see
the [Anthropic SDK docs](https://docs.anthropic.com).

---

## Environment setup

Keep API configuration in environment variables, not in code. Use separate
files for local and remote:

```sh
# .env.local
OPENAI_API_BASE=http://localhost:1234/v1
OPENAI_API_KEY=placeholder
AI_MODEL=local-model

# .env.remote
OPENAI_API_BASE=https://api.openai.com/v1
OPENAI_API_KEY=your-real-api-key
AI_MODEL=your-chosen-model
```

Load with `source .env.local` or use a library like `dotenv` in Node/Python.
Never commit `.env.remote` — add it to `.gitignore`.

---

## Shell

Shell is best for simple pipelines: fetch a prompt, substitute placeholders,
send to the API, capture output.

### Single request with curl

```sh
#!/usr/bin/env bash
# Usage: ./ai-request.sh "Your prompt here"

BASE_URL="${OPENAI_API_BASE:-http://localhost:1234/v1}"
MODEL="${AI_MODEL:-local-model}"
PROMPT="$1"

curl -s "$BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OPENAI_API_KEY:-placeholder}" \
  -d "$(jq -n \
    --arg model "$MODEL" \
    --arg content "$PROMPT" \
    '{
      model: $model,
      messages: [{"role": "user", "content": $content}],
      max_tokens: 1024,
      temperature: 0.2
    }')" \
  | jq -r '.choices[0].message.content'
```

### With a skill as system prompt

```sh
#!/usr/bin/env bash
# Usage: ./ai-with-skill.sh <skill-path> "Your task description"

SKILL_PATH="$1"
TASK="$2"
BASE_URL="${OPENAI_API_BASE:-http://localhost:1234/v1}"
MODEL="${AI_MODEL:-local-model}"

SKILL_BODY=$(./tools/fetch-prompt.sh --skill "$SKILL_PATH")

curl -s "$BASE_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OPENAI_API_KEY:-placeholder}" \
  -d "$(jq -n \
    --arg model "$MODEL" \
    --arg system "$SKILL_BODY" \
    --arg user "$TASK" \
    '{
      model: $model,
      messages: [
        {"role": "system", "content": $system},
        {"role": "user", "content": $user}
      ],
      max_tokens: 2048,
      temperature: 0.2
    }')" \
  | jq -r '.choices[0].message.content'
```

### Batch processing files

```sh
#!/usr/bin/env bash
# Process all TypeScript files in src/ with a code review prompt

OUTPUT_FILE="review-results.md"
> "$OUTPUT_FILE"

for file in src/**/*.ts; do
  echo "### $file" >> "$OUTPUT_FILE"

  # Build prompt with file contents substituted
  PROMPT=$(./tools/fetch-prompt.sh code/code-review \
    | sed 's/{{LANGUAGE}}/TypeScript/g' \
    | sed 's/{{FOCUS}}//g' \
    | sed "s|{{CODE}}|$(cat "$file" | sed 's/[&/\]/\\&/g')|g")

  # Send and append output
  curl -s "${OPENAI_API_BASE:-http://localhost:1234/v1}/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${OPENAI_API_KEY:-placeholder}" \
    -d "$(jq -n --arg model "${AI_MODEL:-local-model}" --arg content "$PROMPT" \
      '{model: $model, messages: [{"role":"user","content":$content}], max_tokens: 1024, temperature: 0.2}')" \
    | jq -r '.choices[0].message.content' >> "$OUTPUT_FILE"

  echo "" >> "$OUTPUT_FILE"
done

echo "Reviews written to $OUTPUT_FILE"
```

---

## Node.js

Node is a good choice when you need JSON parsing, async concurrency, or
integration with the rest of a JavaScript/TypeScript project.

### Setup

```sh
npm install openai dotenv
```

### Single request

```js
// ai-request.mjs
import OpenAI from "openai";
import "dotenv/config";

const client = new OpenAI({
    baseURL: process.env.OPENAI_API_BASE ?? "http://localhost:1234/v1",
    apiKey: process.env.OPENAI_API_KEY ?? "placeholder",
});

async function ask(prompt, systemPrompt = null) {
    const messages = [];
    if (systemPrompt) messages.push({ role: "system", content: systemPrompt });
    messages.push({ role: "user", content: prompt });

    const response = await client.chat.completions.create({
        model: process.env.AI_MODEL ?? "local-model",
        messages,
        max_tokens: 1024,
        temperature: 0.2,
    });

    return response.choices[0].message.content;
}

const result = await ask("Explain what a context window is in one paragraph.");
console.log(result);
```

### With a skill and file content

```js
// review-file.mjs
import OpenAI from "openai";
import { readFileSync, execSync } from "fs";
import "dotenv/config";

const client = new OpenAI({
    baseURL: process.env.OPENAI_API_BASE ?? "http://localhost:1234/v1",
    apiKey: process.env.OPENAI_API_KEY ?? "placeholder",
});

function fetchSkill(skillPath) {
    return execSync(`./tools/fetch-prompt.sh --skill ${skillPath}`, {
        encoding: "utf8",
    });
}

function fetchPrompt(promptPath) {
    return execSync(`./tools/fetch-prompt.sh ${promptPath}`, {
        encoding: "utf8",
    });
}

async function reviewFile(filePath) {
    const code = readFileSync(filePath, "utf8");
    const promptTemplate = fetchPrompt("code/code-review");

    const prompt = promptTemplate
        .replace("{{LANGUAGE}}", "TypeScript")
        .replace("{{FOCUS}}", "")
        .replace("{{CODE}}", code);

    const response = await client.chat.completions.create({
        model: process.env.AI_MODEL ?? "local-model",
        messages: [{ role: "user", content: prompt }],
        max_tokens: 1024,
        temperature: 0.2,
    });

    return response.choices[0].message.content;
}

const result = await reviewFile(process.argv[2]);
console.log(result);
```

### Batch processing with concurrency control

```js
// batch-review.mjs
import OpenAI from "openai";
import { readFileSync, readdirSync } from "fs";
import { execSync } from "child_process";
import "dotenv/config";

const client = new OpenAI({
    baseURL: process.env.OPENAI_API_BASE ?? "http://localhost:1234/v1",
    apiKey: process.env.OPENAI_API_KEY ?? "placeholder",
});

const CONCURRENCY = 3; // adjust based on model throughput

async function processFile(filePath, promptTemplate) {
    const code = readFileSync(filePath, "utf8");
    const prompt = promptTemplate
        .replace("{{LANGUAGE}}", "TypeScript")
        .replace("{{FOCUS}}", "")
        .replace("{{CODE}}", code);

    const response = await client.chat.completions.create({
        model: process.env.AI_MODEL ?? "local-model",
        messages: [{ role: "user", content: prompt }],
        max_tokens: 1024,
        temperature: 0.2,
    });

    return { file: filePath, review: response.choices[0].message.content };
}

// Simple concurrency limiter
async function runWithConcurrency(tasks, limit) {
    const results = [];
    const executing = [];
    for (const task of tasks) {
        const p = task().then((r) => {
            executing.splice(executing.indexOf(p), 1);
            return r;
        });
        results.push(p);
        executing.push(p);
        if (executing.length >= limit) await Promise.race(executing);
    }
    return Promise.all(results);
}

const promptTemplate = execSync("./tools/fetch-prompt.sh code/code-review", {
    encoding: "utf8",
});
const files = readdirSync("src")
    .filter((f) => f.endsWith(".ts"))
    .map((f) => `src/${f}`);
const tasks = files.map((f) => () => processFile(f, promptTemplate));

const reviews = await runWithConcurrency(tasks, CONCURRENCY);
reviews.forEach(({ file, review }) => {
    console.log(`\n### ${file}\n`);
    console.log(review);
});
```

---

## Python

Python is a natural fit for data processing, log analysis, and pipelines
involving structured output.

### Setup

```sh
pip install openai python-dotenv
```

### Single request

```python
# ai_request.py
import os
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

client = OpenAI(
    base_url=os.getenv("OPENAI_API_BASE", "http://localhost:1234/v1"),
    api_key=os.getenv("OPENAI_API_KEY", "placeholder"),
)

def ask(prompt: str, system_prompt: str | None = None) -> str:
    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({"role": "user", "content": prompt})

    response = client.chat.completions.create(
        model=os.getenv("AI_MODEL", "local-model"),
        messages=messages,
        max_tokens=1024,
        temperature=0.2,
    )
    return response.choices[0].message.content

if __name__ == "__main__":
    result = ask("Explain what a context window is in one paragraph.")
    print(result)
```

### Structured (JSON) output

For tasks where you need to parse the model's response programmatically,
prompt for JSON output and parse the result:

````python
import json
import subprocess

def fetch_prompt(path: str) -> str:
    return subprocess.check_output(
        ["./tools/fetch-prompt.sh", path], text=True
    )

def ask_for_json(prompt: str) -> dict:
    full_prompt = prompt + "\n\nRespond with a JSON object only. No explanation, no markdown."
    raw = ask(full_prompt)
    # Strip markdown code fences if present
    raw = raw.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()
    return json.loads(raw)

# Example: extract function signatures from a file
code = open("src/utils.ts").read()
prompt = f"""
List all exported functions in this TypeScript file.

{code}
"""
result = ask_for_json(prompt + "\n\nReturn JSON: {{\"functions\": [{{\"name\": str, \"description\": str}}]}}")
for fn in result["functions"]:
    print(f"{fn['name']}: {fn['description']}")
````

### Batch processing with error handling

```python
# batch_review.py
import os
import subprocess
from pathlib import Path
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

client = OpenAI(
    base_url=os.getenv("OPENAI_API_BASE", "http://localhost:1234/v1"),
    api_key=os.getenv("OPENAI_API_KEY", "placeholder"),
)

def get_prompt_template(path: str) -> str:
    return subprocess.check_output(["./tools/fetch-prompt.sh", path], text=True)

def review_file(file_path: Path, template: str) -> str:
    code = file_path.read_text()
    prompt = (
        template
        .replace("{{LANGUAGE}}", "Python")
        .replace("{{FOCUS}}", "")
        .replace("{{CODE}}", code)
    )
    response = client.chat.completions.create(
        model=os.getenv("AI_MODEL", "local-model"),
        messages=[{"role": "user", "content": prompt}],
        max_tokens=1024,
        temperature=0.2,
    )
    return response.choices[0].message.content

template = get_prompt_template("code/code-review")
results = {}

for path in Path("src").glob("**/*.py"):
    print(f"Reviewing {path}...")
    try:
        results[str(path)] = review_file(path, template)
    except Exception as e:
        results[str(path)] = f"ERROR: {e}"
        print(f"  Failed: {e}")

for file_path, review in results.items():
    print(f"\n### {file_path}\n{review}")
```

---

## Error handling patterns

### Retry on rate limit or transient error

```python
import time
from openai import RateLimitError, APIError

def ask_with_retry(prompt: str, max_retries: int = 3, backoff: float = 2.0) -> str:
    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(
                model=os.getenv("AI_MODEL", "local-model"),
                messages=[{"role": "user", "content": prompt}],
                max_tokens=1024,
                temperature=0.2,
            )
            return response.choices[0].message.content
        except RateLimitError:
            if attempt < max_retries - 1:
                wait = backoff ** attempt
                print(f"Rate limited. Retrying in {wait}s...")
                time.sleep(wait)
            else:
                raise
        except APIError as e:
            print(f"API error on attempt {attempt + 1}: {e}")
            if attempt == max_retries - 1:
                raise
    raise RuntimeError("Max retries exceeded")
```

### Validate response before use

```python
def ask_validated(prompt: str, validator=None) -> str:
    result = ask(prompt)
    if validator and not validator(result):
        raise ValueError(f"Response failed validation: {result[:100]}...")
    return result

# Example: ensure the response is non-empty and contains code
import_check = lambda r: len(r.strip()) > 0 and ("def " in r or "function " in r or "class " in r)
code_output = ask_validated("Write a Python function to...", validator=import_check)
```

---

## Further reading

- [`cli-tool-workflow.md`](./cli-tool-workflow.md) — Claude Code and Aider
  for interactive and scripted terminal use
- [`../models/lm-studio-setup.md`](../models/lm-studio-setup.md) — local
  endpoint configuration
- [`../models/local-vs-remote.md`](../models/local-vs-remote.md) — choosing
  between local and hosted endpoints for scripts
- [`../context/chunking-strategies.md`](../context/chunking-strategies.md)
  — handling large inputs in batch scripts
- [`../../tools/README.md`](../../tools/README.md) — fetch-prompt.sh and
  chunk-file.sh for use in scripts
