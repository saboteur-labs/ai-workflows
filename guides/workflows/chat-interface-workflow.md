# Chat interface workflow

Patterns for working with AI via chat interfaces — Claude.ai, ChatGPT, and
similar. Concise notes on session management, prompt pasting, and getting
consistent output without IDE tooling.

---

## How chat interfaces use prompts and skills

Chat interfaces are the most accessible entry point — no setup, no config
files. The trade-off is less automation: you paste manually, manage context
manually, and restart sessions manually.

Two injection patterns:

- **Opening system message** — paste a skill body as your very first message
  before describing any task. Some interfaces (Claude.ai Projects, ChatGPT
  Custom GPTs) support a dedicated system prompt field — use that if available.
- **User message** — paste a prompt as a regular message. The model treats it
  as a task instruction for that turn.

---

## Starting a session with a skill

If the interface has a system prompt field (Claude.ai Projects, ChatGPT
Custom GPTs, Gemini Gems):

1. Fetch the skill body: `./tools/fetch-prompt.sh --skill coding/implement-feature`
2. Paste into the system prompt field
3. Fill in any `{{PLACEHOLDERS}}` in the skill before saving

If there is no system prompt field:

1. Start a new conversation
2. Paste the skill body as your first message
3. The model will acknowledge it — then describe your task in the next message

Use the `-minimal` skill variant in chat interfaces unless you're on a plan
with a large context window, since conversation history accumulates quickly.

---

## Pasting a prompt

1. Fetch the prompt: `./tools/fetch-prompt.sh code/generate-unit-tests`
   Or copy to clipboard: `./tools/fetch-prompt.sh --copy code/generate-unit-tests`
2. Fill in all `{{PLACEHOLDERS}}` before sending — sending placeholders
   unfilled causes the model to either guess or ask, both of which waste turns
3. For prompts that take a file as input (`{{SOURCE_CODE}}`, `{{CODE}}`):
    - In Claude.ai: use the file upload button rather than pasting inline —
      it handles large files more reliably
    - In ChatGPT: paste inline for code files under ~300 lines; upload for larger
    - In all interfaces: if the file is large, chunk it first and process per
      chunk — see [`../context/chunking-strategies.md`](../context/chunking-strategies.md)

---

## Session management

**One task per session.** Chat history accumulates token cost with every
turn. A session that starts with a spec, drifts into implementation, then
architecture discussion will eventually lose coherence as early instructions
scroll out of the effective context.

Start a new conversation when:

- The task changes substantially
- The model starts ignoring earlier instructions
- You're moving to a different phase (spec → implementation, implementation
  → tests)
- The session has more than ~10 turns on a smaller model

**Saving context across sessions.** Before ending a session you'll continue
later, use `prompts/agent-orchestration/summarize-for-handoff.md` to produce
a compact summary. Paste it as the first message of the next session to
restore context cheaply.

---

## Gotchas

**Unfilled placeholders**
Always replace every `{{PLACEHOLDER}}` before sending. If you send a prompt
with placeholders intact the model often guesses values or produces a
meta-response about the prompt rather than executing it.

**Pasting large files inline**
Pasting a 500-line file inline as `{{SOURCE_CODE}}` works, but eats context
fast. Prefer file upload where available, or chunk the file and process in
passes.

**The model "forgetting" instructions**
If the model stops following the skill or prompt rules mid-session, the
instructions have likely drifted out of the effective context window. Either
start a fresh session or re-paste the key instructions as a reminder message.

**Markdown rendering**
Chat interfaces render markdown, which means a prompt containing code blocks
or tables displays formatted rather than as raw text. This is usually fine,
but if the model produces oddly structured output, check whether your prompt's
formatting is being interpreted.

---

## Further reading

- [`ide-plugin-workflow.md`](./ide-plugin-workflow.md) — persistent skill
  injection and file referencing in IDE plugins
- [`cli-tool-workflow.md`](./cli-tool-workflow.md) — scripting and
  automating model calls from the terminal
- [`../context/context-budget-guide.md`](../context/context-budget-guide.md)
  — choosing the right budget tier for your setup
