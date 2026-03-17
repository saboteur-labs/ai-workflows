# CLI tool workflow

Step-by-step patterns for working with AI via command-line tools — Claude
Code and Aider. Covers installation, skill injection, stdin piping, session
management, and scripting.

---

## Why CLI tools

CLI tools integrate directly into your terminal workflow. They can read your
project files without manual copying, run commands, and be composed with
standard Unix tools. The trade-off versus IDE plugins is more setup friction
and less visual feedback during long tasks.

Use CLI tools when:

- You want to script or automate AI-assisted tasks
- You're working outside an IDE (SSH sessions, CI, headless environments)
- You want to pipe file content programmatically
- You prefer terminal-first workflows

---

## Claude Code

Claude Code is Anthropic's official CLI agent. It operates on your local
codebase, can read and write files, and run shell commands.

### Installation

```sh
npm install -g @anthropic/claude-code
```

Requires Node.js 18 or later. Verify:

```sh
claude --version
```

### Authentication

Claude Code uses the Anthropic API. Set your API key:

```sh
export ANTHROPIC_API_KEY=your-key-here
```

Add this to your shell profile (`~/.zshrc`, `~/.bashrc`) to persist it.

### Basic usage

```sh
# Start an interactive session in the current directory
claude

# Run a one-shot prompt non-interactively
claude -p "Explain what this project does"

# Run with a specific file in context
claude -p "Review this file for bugs" --file src/utils.ts
```

### Injecting a skill as a system prompt

```sh
# Fetch the skill body and pass it as the system prompt
SKILL=$(./tools/fetch-prompt.sh --skill coding/implement-feature)
claude --system "$SKILL" -p "Implement the CSV export feature from spec.md"
```

For repeated use, store the skill in a file and reference it:

```sh
./tools/fetch-prompt.sh --skill coding/implement-feature > .claude-skill.md
claude --system "$(cat .claude-skill.md)" -p "Implement the CSV export feature"
```

### Using a prompt non-interactively

```sh
# Fetch a prompt, fill placeholders, pipe to claude
./tools/fetch-prompt.sh code/generate-unit-tests \
  | sed 's/{{LANGUAGE}}/TypeScript/g' \
  | sed 's/{{TEST_FRAMEWORK}}/Jest/g' \
  | sed "s/{{SOURCE_CODE}}/$(cat src/utils.ts | sed 's/[&/\]/\\&/g')/g" \
  | claude -p -
```

For complex placeholder substitution, use a small wrapper script rather
than chained `sed` — it's easier to maintain. See the pattern in
[Scripting section](#scripting-patterns) below.

### Skills via .agents/skills/

Claude Code discovers skills placed in `.agents/skills/` in your project:

```sh
./tools/fetch-prompt.sh --install-skill coding/implement-feature
```

Once installed, Claude Code loads the skill automatically when it determines
the skill is relevant to the task. You can also reference it explicitly:

```sh
claude -p "Use the implement-feature skill to build the CSV export"
```

### Session management

Claude Code maintains session context within a single invocation. For
multi-turn interactive sessions, history accumulates. To start fresh:

```sh
# Each invocation is a fresh session when using -p (non-interactive)
claude -p "Task 1"
claude -p "Task 2"  # no history from Task 1

# Interactive sessions persist until you exit
claude
> Task 1
> Task 2  # has history from Task 1
```

For long interactive sessions, use `/clear` inside the session to reset
context without exiting, or exit and restart for a fully clean slate.

### Output formats

```sh
# Default: streamed markdown to terminal
claude -p "Explain this file" --file src/utils.ts

# JSON output for scripting (includes metadata)
claude -p "List all exported functions" --file src/utils.ts \
  --output-format json | jq '.result'

# Save output to a file
claude -p "Generate unit tests" --file src/utils.ts > tests/utils.test.ts
```

---

## Aider

Aider is an open-source CLI coding assistant that works with any
OpenAI-compatible endpoint, making it well suited for local models.

### Installation

```sh
pip install aider-chat
```

Or with pipx (recommended to avoid dependency conflicts):

```sh
pipx install aider-chat
```

### Authentication and model configuration

For a hosted model:

```sh
export OPENAI_API_KEY=your-key-here
aider --model gpt-4o  # or your preferred model identifier
```

For a local model via LM Studio:

```sh
export OPENAI_API_KEY=placeholder
aider \
  --openai-api-base http://localhost:1234/v1 \
  --model local-model
```

Persist configuration in `.aider.conf.yml` at your project root:

```yaml
# .aider.conf.yml
openai-api-base: http://localhost:1234/v1
openai-api-key: placeholder
model: local-model
```

### Injecting a skill as a system prompt

```sh
# Pass skill body as system prompt
aider --system "$(./tools/fetch-prompt.sh --skill coding/implement-feature)"

# Or reference a file
./tools/fetch-prompt.sh --skill coding/implement-feature > .aider-skill.md
aider --system "$(cat .aider-skill.md)"
```

Add the system prompt to `.aider.conf.yml` to apply it automatically:

```yaml
system-prompt: .aider-skill.md
```

### Adding files to context

```sh
# Start with specific files in context
aider src/utils.ts src/types.ts

# Add files during a session
> /add src/new-file.ts

# Drop files to free context
> /drop src/utils.ts
```

Keep the active file set small on local models — every added file consumes
context. Add only the files directly relevant to the current task.

### Using a prompt non-interactively

```sh
# Run a single prompt and exit (--yes auto-confirms file changes)
aider --yes --message "$(./tools/fetch-prompt.sh code/code-review \
  | sed 's/{{LANGUAGE}}/TypeScript/g' \
  | sed 's/{{CODE}}/see attached files/g')" \
  src/utils.ts
```

### Session management

Aider maintains a `.aider.chat.history.md` file in the project root with
full session history. This history is re-loaded on the next session, which
can be useful for continuity but problematic for fresh starts.

```sh
# Start fresh (ignore history)
aider --no-chat-history-file

# Or delete the history file before starting
rm .aider.chat.history.md && aider
```

For very long sessions, use `/clear` inside the session to reset context
while keeping files in the active set.

---

## Scripting patterns

### Basic prompt + file pipeline

```sh
#!/usr/bin/env bash
# review.sh — run a code review prompt on a file

FILE="$1"
[[ -f "$FILE" ]] || { echo "Usage: review.sh <file>"; exit 1; }

LANG="${2:-TypeScript}"

./tools/fetch-prompt.sh code/code-review \
  | sed "s/{{LANGUAGE}}/$LANG/g" \
  | sed "s|{{FOCUS}}||g" \
  | sed "s|{{CODE}}|$(cat "$FILE" | sed 's/[&/\]/\\&/g')|g" \
  | claude -p -
```

### Batch processing with chunking

```sh
#!/usr/bin/env bash
# review-large.sh — chunk a large file and review each chunk

FILE="$1"
OUTPUT_DIR="/tmp/review-chunks-$$"

# Chunk the file
./tools/chunk-file.sh --output-dir "$OUTPUT_DIR" "$FILE"

# Review each chunk
for chunk in "$OUTPUT_DIR"/*.part-*; do
  echo "=== Reviewing $(basename "$chunk") ===" >> /tmp/review-output.md
  ./tools/fetch-prompt.sh code/code-review \
    | sed "s/{{LANGUAGE}}/TypeScript/g" \
    | sed "s|{{FOCUS}}||g" \
    | sed "s|{{CODE}}|$(cat "$chunk" | sed 's/[&/\]/\\&/g')|g" \
    | claude -p - >> /tmp/review-output.md
done

# Consolidate
echo "=== Consolidating reviews ==="
./tools/fetch-prompt.sh agent-orchestration/summarize-for-handoff \
  | sed "s|{{SESSION_CONTEXT}}|$(cat /tmp/review-output.md \
      | sed 's/[&/\]/\\&/g')|g" \
  | sed "s|{{NEXT_TASK}}|None — review complete|g" \
  | claude -p -

rm -rf "$OUTPUT_DIR"
```

### Environment-based model switching

```sh
# .env.local
export OPENAI_API_BASE=http://localhost:1234/v1
export OPENAI_API_KEY=placeholder
export AI_MODEL=local-model

# .env.remote
export OPENAI_API_BASE=https://api.openai.com/v1
export OPENAI_API_KEY=your-real-key
export AI_MODEL=your-chosen-model
```

```sh
# Switch model context
source .env.local
aider --openai-api-base "$OPENAI_API_BASE" --model "$AI_MODEL"
```

---

## Gotchas

**Placeholder substitution with special characters**
File contents passed via `sed` substitution break if the file contains `&`,
`/`, or `\`. Always escape before substituting:

```sh
ESCAPED=$(cat file.ts | sed 's/[&/\]/\\&/g')
```

For anything more complex, use a Python or Node script for substitution
instead of shell.

**Aider auto-commits**
Aider commits file changes automatically by default. To review changes before
committing:

```sh
aider --no-auto-commits
```

Or configure in `.aider.conf.yml`:

```yaml
auto-commits: false
```

**Claude Code file permissions**
Claude Code can read, write, and execute files. In sensitive codebases,
review what it does before confirming destructive operations. Use
`--dry-run` where available, or run in a branch.

**Local model instruction drift in long sessions**
Small local models lose instruction adherence faster than hosted models as
context fills. Keep sessions short (one task), use `-minimal` skills, and
restart rather than continuing a degraded session.

---

## Further reading

- [`api-scripted-workflow.md`](./api-scripted-workflow.md) — calling models
  programmatically from Node.js, Python, and shell scripts
- [`../models/lm-studio-setup.md`](../models/lm-studio-setup.md) — connecting
  CLI tools to a local model
- [`../context/low-memory-workarounds.md`](../context/low-memory-workarounds.md)
  — keeping sessions within budget on local models
- [`../../tools/README.md`](../../tools/README.md) — fetch-prompt.sh and
  chunk-file.sh reference
