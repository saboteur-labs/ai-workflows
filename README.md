# ai-workflows

A model-agnostic knowledge base for AI-augmented development workflows. This
repo contains best-practice guides, a copy-paste prompt library, and reusable
agent skills for use across projects in this organization.

Designed to work with local models (LM Studio, Ollama) and hosted models
(Claude, ChatGPT, Gemini, etc.) interchangeably. All content is
interface-agnostic and labeled for context window cost so it works on
resource-constrained machines as well as fully-hosted setups.

---

## How to use this repo

This is a **reference repo** — you read from it and copy into the project
you're working on. There are no dependencies to install and nothing to link.

**Finding something:**

- Looking for a prompt to paste into a conversation or IDE? → [`prompts/`](./prompts/)
- Looking for an agent skill to inject as a system prompt or context file? → [`skills/`](./skills/)
- Looking for guidance on workflows, context management, or model selection? → [`guides/`](./guides/)
- Want a worked end-to-end example? → [`examples/`](./examples/)
- Need a script to chunk files or fetch content from this repo? → [`tools/`](./tools/)

**Copying a prompt:**

1. Browse to the relevant file in `prompts/`
2. Check the `context_budget` field — if you're on a local model with limited
   VRAM, use prompts marked `low` or use the low-context variant in the file
3. Copy the text from the `## Prompt` section
4. Replace all `{{PLACEHOLDERS}}` before use

**Using a skill:**

1. Browse to the relevant directory in `skills/`
2. Check `context-budget` in the `SKILL.md` frontmatter
3. Copy the skill directory into `.agents/skills/` in your project (the
   standard location for Agent Skills-compatible tools), or paste the
   `SKILL.md` body as a system prompt / IDE context file
4. See [`guides/workflows/`](./guides/workflows/) for interface-specific
   injection instructions

**Fetching directly from the terminal:**

```sh
# Fetch a prompt by category and name
./tools/fetch-prompt.sh code/generate-unit-tests

# Fetch a skill
./tools/fetch-prompt.sh --skill coding/implement-feature

# Chunk a large file before feeding it to a local model
./tools/chunk-file.sh path/to/file.ts
```

See [`tools/README.md`](./tools/README.md) for full usage.

---

## Repository structure

```
ai-workflows/
│
├── guides/                         # Conceptual guides and best practices
│   ├── context/                    # Context window management
│   ├── workflows/                  # Per-interface workflow patterns
│   ├── models/                     # Model selection, local vs remote
│   └── agent-patterns/             # Single-agent, multi-agent, HITL
│
├── prompts/                        # Copy-paste prompt library
│   ├── code/                       # Code generation, review, refactoring
│   ├── planning/                   # Specs, ADRs, task breakdown
│   ├── testing/                    # Test generation and QA
│   └── agent-orchestration/        # Task decomposition, handoffs, critique
│
├── skills/                         # Agent Skills (agentskills.io spec)
│   ├── coding/                     # Implementation and debugging skills
│   └── planning/                   # Spec writing and design skills
│
├── templates/                      # Starter files for new prompts and skills
│   ├── prompt-template.md
│   └── skill-template.md
│
├── examples/                       # Worked end-to-end workflow demos
│   ├── spec-to-implementation/
│   └── low-context-chunked-review/
│
└── tools/                          # Shell scripts and utilities
    ├── fetch-prompt.sh
    ├── chunk-file.sh
    └── lib/
```

---

## Context budget

Every prompt and skill is labeled with a `context_budget` (prompts) or
`context-budget` metadata field (skills):

| Budget   | Token range | Suitable for                                                    |
| -------- | ----------- | --------------------------------------------------------------- |
| `low`    | ~1–2k       | Any model, including 7B local models with small context windows |
| `medium` | ~2–8k       | 13B+ local models, or any hosted model                          |
| `high`   | 8k+         | Hosted models (Claude, GPT-4, etc.) or high-VRAM local setups   |

If a prompt or skill is `medium` or `high`, a low-context variant is included
in the same file or as a sibling directory suffixed `-minimal`. When in doubt,
start with the low-context variant and add detail incrementally.

See [`guides/context/context-budget-guide.md`](./guides/context/context-budget-guide.md)
for a full explanation and decision tree.

---

## Supported interfaces

Content in this repo is designed to work across all common AI interfaces.
No vendor-specific syntax is used.

| Interface  | Examples                           | Notes                                                   |
| ---------- | ---------------------------------- | ------------------------------------------------------- |
| IDE plugin | Cursor, Continue.dev, Copilot Chat | Inject skills via system prompt or rules file           |
| Chat       | Claude.ai, ChatGPT, Gemini         | Paste prompts directly; skills as opening message       |
| CLI        | Claude Code, Aider                 | Pass skills via `--system` flag; pipe prompts via stdin |
| API        | Anthropic, OpenAI, local endpoints | Skills as `system` field; prompts as `user` message     |

See [`guides/workflows/`](./guides/workflows/) for step-by-step instructions
for each interface.

---

## Adding content

Contributions follow a simple convention:

1. Use the appropriate template:
    - New prompt → [`templates/prompt-template.md`](./templates/prompt-template.md)
    - New skill → [`templates/skill-template.md`](./templates/skill-template.md)
2. Fill in all frontmatter fields and replace all `{{PLACEHOLDERS}}`
3. Add an entry to the index table in the relevant `README.md`
4. Open a pull request — the frontmatter validator will run automatically

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for the full contribution guide.

---

## Skills specification

Skills in this repo conform to the
[Agent Skills open specification](https://agentskills.io/specification).
This means they work out of the box with any Agent Skills-compatible tool
(Claude Code, GitHub Copilot agent mode, VS Code, and others) without
modification.

Validate a skill locally:

```sh
skills-ref validate ./skills/<skill-name>
```

---

## Local model setup

If you're running models locally via LM Studio or Ollama:

- Filter for prompts and skills with `context_budget: low` to start
- See [`guides/context/low-memory-workarounds.md`](./guides/context/low-memory-workarounds.md)
  for chunking strategies
- See [`guides/models/lm-studio-setup.md`](./guides/models/lm-studio-setup.md)
  for recommended model configs
- Use `tools/chunk-file.sh` to split large inputs before sending to the model

---

## License

[MIT](./LICENSE)
