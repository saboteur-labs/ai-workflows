# IDE plugin workflow

Patterns for using AI prompts and skills inside IDE plugins. Covers the
three most common plugins — Cursor, Continue.dev, and GitHub Copilot Chat —
with concise setup and usage notes for each.

This guide assumes you've already chosen a model (local or remote). See
[`../models/local-vs-remote.md`](../models/local-vs-remote.md) and
[`../models/lm-studio-setup.md`](../models/lm-studio-setup.md) if not.

---

## How IDE plugins use prompts and skills

IDE plugins expose two injection points:

- **System prompt / context file** — loaded at the start of every session.
  This is where skills go. The model reads it before any conversation begins.
- **Chat message** — sent as a user turn. This is where prompts go.

The distinction matters: a skill injected as a system prompt shapes the
model's behaviour for the entire session. A prompt pasted as a chat message
is a one-shot instruction for a single request.

---

## Cursor

### Injecting a skill (system prompt)

Cursor reads `.cursorrules` from the project root as a persistent system
prompt for all AI interactions in that project.

```sh
# Print the skill body ready to paste into .cursorrules
./tools/fetch-prompt.sh --skill coding/implement-feature
```

Copy the output into `.cursorrules` at the project root. Or install
automatically:

```sh
./tools/fetch-prompt.sh --skill coding/implement-feature > .cursorrules
```

**Tips:**

- Keep `.cursorrules` under ~2,000 tokens for reliable adherence
- Use the `-minimal` skill variant if your project already loads heavy context
- `.cursorrules` applies to all Cursor AI features — Cmd+K, chat, and inline
  completions

### Using a prompt in Cursor chat

1. Open the Cursor chat panel (Cmd+L / Ctrl+L)
2. Fetch the prompt: `./tools/fetch-prompt.sh code/generate-unit-tests`
3. Fill in all `{{PLACEHOLDERS}}`
4. Paste into the chat panel
5. Use `@filename` to attach the relevant file rather than pasting its
   contents — Cursor handles the injection efficiently

### Gotchas

- `.cursorrules` applies to inline completions too, not just chat. Long or
  restrictive rules can slow completions. If completions degrade, trim the
  rules or switch to a `-minimal` skill variant.
- When using a local model via Cursor's custom API setting, the model name
  must exactly match what LM Studio reports at `/v1/models`. A mismatch
  silently falls back to a default model.

---

## Continue.dev

### Injecting a skill (system prompt)

Continue.dev supports per-model system prompts in `~/.continue/config.json`:

```json
{
    "models": [
        {
            "title": "Local model",
            "provider": "openai",
            "model": "local-model",
            "apiBase": "http://localhost:1234/v1",
            "apiKey": "placeholder",
            "systemMessage": "SKILL_BODY_HERE"
        }
    ]
}
```

Replace `SKILL_BODY_HERE` with the body of `SKILL.md` (after the
frontmatter). Escape any double quotes with `\"`.

For project-scoped system prompts, Continue.dev also supports
`.continuerc.json` at the project root with the same `systemMessage` field.

### Using a prompt in Continue.dev chat

1. Open the Continue.dev chat sidebar
2. Fetch and fill the prompt
3. Paste as a chat message
4. Reference files with `@filename` — Continue.dev indexes your codebase and
   resolves references automatically

### Slash commands (optional)

Register frequently-used prompts as slash commands in `config.json`:

```json
{
    "slashCommands": [
        {
            "name": "review",
            "description": "Code review the current file",
            "prompt": "PROMPT_BODY_HERE"
        }
    ]
}
```

### Gotchas

- `systemMessage` in `config.json` is global to that model profile. Use
  separate model profiles or a project-scoped `.continuerc.json` when
  switching skills between projects.
- Continue.dev's codebase auto-indexing adds context automatically. On a
  local model with a small window, limit indexing to files you're actively
  working on.

---

## GitHub Copilot Chat

### Injecting a skill (agent mode)

Copilot Chat in agent mode reads skills from `.agents/skills/` in the
project root, following the Agent Skills specification.

```sh
# Install a skill into the project
./tools/fetch-prompt.sh --install-skill coding/implement-feature
```

This copies the skill directory to `.agents/skills/implement-feature/`.
Copilot Chat in agent mode discovers and activates it automatically based
on the skill's `description` field.

### Using a prompt in Copilot Chat

1. Fetch and fill the prompt
2. Paste as your first message in the chat panel
3. Reference specific files with `#file:path/to/file`

### Gotchas

- Skill activation depends on the model matching your request to the skill's
  `description`. If a skill isn't activating, review the description for
  specificity — see the Agent Skills
  [optimizing descriptions guide](https://agentskills.io/skill-creation/optimizing-descriptions).
- Skills are only available in agent mode. Regular Copilot Chat mode does
  not read `.agents/skills/` — select agent mode from the dropdown.

---

## End-to-end workflow: spec → implement → test

A common pattern using the IDE chat panel for a complete feature cycle:

**Step 1 — Write the spec** (chat session 1)
Paste `prompts/planning/write-feature-spec.md` with a one-sentence feature
description. Review and refine the output before moving on.

**Step 2 — Install the implement skill** (once per project)

```sh
./tools/fetch-prompt.sh --install-skill coding/implement-feature
```

Fill in `references/patterns.md` and `references/conventions.md` with
project-specific details.

**Step 3 — Implement** (chat session 2, fresh)
Describe the feature. The skill guides the model through plan → implement
→ verify. Use a fresh session to avoid history from the spec session
compressing the context window.

**Step 4 — Generate tests** (chat session 3, fresh)
Paste `prompts/code/generate-unit-tests.md`, attach the implemented file,
fill in the framework placeholder.

Each step in a separate session — this prevents history accumulation from
degrading output, particularly important on local models.

---

## Further reading

- [`chat-interface-workflow.md`](./chat-interface-workflow.md) — using
  prompts and skills in chat interfaces
- [`../models/lm-studio-setup.md`](../models/lm-studio-setup.md) — connecting
  IDE plugins to a local model
- [`../context/context-budget-guide.md`](../context/context-budget-guide.md)
  — choosing the right budget tier for your IDE setup
