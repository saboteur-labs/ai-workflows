# tools/

Shell-first utilities for working with the ai-workflows knowledge base.
All tools have a `.sh` entry point. Python and Node implementations of
heavier logic live in `lib/` and are called by the shell wrappers.

---

## fetch-prompt.sh

Fetch a prompt or skill from this repo and print it to stdout, copy it to
the clipboard, or install a skill into your project.

```sh
# Print a prompt (frontmatter stripped, ready to paste)
./tools/fetch-prompt.sh code/generate-unit-tests

# Print a skill's SKILL.md body
./tools/fetch-prompt.sh --skill coding/implement-feature

# Copy a prompt to clipboard
./tools/fetch-prompt.sh --copy planning/write-feature-spec

# Install a skill into .agents/skills/ in your current project
./tools/fetch-prompt.sh --install-skill coding/implement-feature

# List all available prompts with their context budget
./tools/fetch-prompt.sh --list

# List prompts in a specific category
./tools/fetch-prompt.sh --list code

# List available skills
./tools/fetch-prompt.sh --list --skill

# Fetch from remote (without cloning the repo)
./tools/fetch-prompt.sh --remote https://raw.githubusercontent.com/saboteur-labs/ai-workflows/main \
  code/generate-unit-tests
```

### Options

| Flag                | Description                                               |
| ------------------- | --------------------------------------------------------- |
| `--skill`           | Target the `skills/` directory instead of `prompts/`      |
| `--copy`            | Copy output to clipboard instead of printing              |
| `--install-skill`   | Copy skill directory to `.agents/skills/` in your project |
| `--list [category]` | List available prompts or skills                          |
| `--raw`             | Include frontmatter in output                             |
| `--remote <url>`    | Fetch from a remote base URL                              |
| `--base <path>`     | Override the local repo root path                         |
| `-q, --quiet`       | Suppress informational output                             |

---

## chunk-file.sh

Split a file into context-window-friendly chunks for processing with a
local or small-context model.

```sh
# Chunk a TypeScript file at default size (1500 tokens)
./tools/chunk-file.sh src/utils.ts

# Chunk at a smaller size with overlap
./tools/chunk-file.sh --size 1000 --overlap 100 src/large-module.ts

# Chunk a markdown doc by section headings
./tools/chunk-file.sh --mode sections docs/architecture.md

# Preview chunk plan without writing files
./tools/chunk-file.sh --dry-run src/utils.ts

# Show token estimate for a file
./tools/chunk-file.sh --stats src/utils.ts

# Write chunks to a specific directory
./tools/chunk-file.sh --output-dir /tmp/chunks src/utils.ts
```

Output files are named `<stem>.part-001.ext`, `<stem>.part-002.ext`, etc.

### Chunking modes

| Mode        | Best for                                    | Boundary detection              |
| ----------- | ------------------------------------------- | ------------------------------- |
| `auto`      | Default — detects from file extension       | Delegates to one of the below   |
| `functions` | Code files (TS, JS, Python, Go, Rust, etc.) | Function and class declarations |
| `sections`  | Markdown, docs, specs                       | Heading lines (`#`, `##`, etc.) |
| `lines`     | Any file type                               | Fixed line count                |

### Options

| Flag                     | Description                              | Default             |
| ------------------------ | ---------------------------------------- | ------------------- |
| `-s, --size <tokens>`    | Target chunk size                        | `1500`              |
| `-o, --overlap <tokens>` | Token overlap between chunks             | `100`               |
| `-m, --mode <mode>`      | `auto`, `lines`, `functions`, `sections` | `auto`              |
| `-d, --output-dir <dir>` | Output directory                         | Same as input file  |
| `-p, --prefix <str>`     | Output filename prefix                   | Input filename stem |
| `--dry-run`              | Preview only, no files written           | off                 |
| `--stats`                | Show token estimate and exit             | off                 |
| `-q, --quiet`            | Suppress informational output            | off                 |

### Processing chunks with a prompt

```sh
# Chunk a file, then run each chunk through a code review prompt
./tools/chunk-file.sh src/large-module.ts --output-dir /tmp/chunks

for chunk in /tmp/chunks/large-module.part-*.ts; do
  echo "--- Reviewing: $chunk ---"
  ./tools/fetch-prompt.sh code/code-review \
    | sed "s/{{CODE}}/$(cat "$chunk" | sed 's/[\/&]/\\&/g')/" \
    | your-model-cli
done
```

After reviewing all chunks, use
[`prompts/agent-orchestration/summarize-for-handoff.md`](../prompts/agent-orchestration/summarize-for-handoff.md)
to consolidate the results.

---

## validate.sh

Run all repo validation checks locally before pushing. Mirrors the full
CI check suite so failures are caught before they reach GitHub.

```sh
# Run all checks
./tools/validate.sh

# Run a single check
./tools/validate.sh --check links
./tools/validate.sh --check frontmatter
./tools/validate.sh --check atomicity
./tools/validate.sh --check placeholders
./tools/validate.sh --check freshness

# Only check files changed since last commit (fastest for pre-push)
./tools/validate.sh --changed-only

# Combine flags
./tools/validate.sh --check links --changed-only
```

### Checks and their CI equivalents

| Check          | Blocks merge? | What it verifies                                                      |
| -------------- | ------------- | --------------------------------------------------------------------- |
| `frontmatter`  | Yes           | Required fields, valid `context_budget`, skill name matches directory |
| `atomicity`    | Yes           | CHANGELOG + README index tables updated when content changes          |
| `links`        | Yes           | All internal markdown links resolve to real files                     |
| `placeholders` | Yes           | No `{{PLACEHOLDERS}}` outside code fences, no stray stub markers      |
| `freshness`    | No (warns)    | `review-by` dates not expired or expiring within 30 days              |

Exit codes: `0` = all blocking checks passed, `1` = blocking failure,
`2` = warnings only (freshness).

---

## lib/

Implementations called by the shell entry points above. Individual check
scripts can also be run directly:

```sh
bash tools/lib/check_links.sh
bash tools/lib/check_freshness.sh
```

Implementations of heavier logic called by the shell wrappers. You do not
need to call these directly.

| File                        | Language | Purpose                                                         |
| --------------------------- | -------- | --------------------------------------------------------------- |
| `lib/check_frontmatter.sh`  | Shell    | Validates frontmatter fields and values in prompts and skills   |
| `lib/check_atomicity.sh`    | Shell    | Checks dependency-map couplings are satisfied for changed files |
| `lib/check_links.sh`        | Shell    | Verifies all internal markdown links resolve to real files      |
| `lib/check_placeholders.sh` | Shell    | Detects unfilled `{{PLACEHOLDERS}}` and stray stub markers      |
| `lib/check_freshness.sh`    | Shell    | Warns on expired or soon-expiring `review-by` dates             |
| `lib/chunk_file.py`         | Python   | Token-accurate chunking using tiktoken (stub)                   |
| `lib/fetch_prompt.js`       | Node.js  | Frontmatter parsing and remote fetch (stub)                     |

The check scripts contain real, runnable logic and are called by both
`validate.sh` and the CI workflows. The `chunk_file.py` and
`fetch_prompt.js` files are stubs pending implementation.

---

## Token estimation

`chunk-file.sh` estimates tokens as `character_count / 4`. This is a
conservative approximation. Actual token counts depend on the model's
tokenizer:

| Content type              | Chars/token (approx) |
| ------------------------- | -------------------- |
| English prose             | ~4–5                 |
| Mixed code                | ~3–4                 |
| Dense TypeScript/generics | ~2.5–3               |
| JSON/YAML                 | ~2–3                 |

When in doubt, use a smaller `--size` value. It is better to produce more
smaller chunks than to exceed the context window.

For accurate token counts, install `tiktoken` (OpenAI's tokenizer, works for
most models) and use `lib/chunk_file.py` once it is implemented:

```sh
pip install tiktoken
python3 tools/lib/chunk_file.py --stats src/utils.ts
```
