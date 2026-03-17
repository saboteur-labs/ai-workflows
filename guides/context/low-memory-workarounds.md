# Low-memory workarounds

Practical techniques for getting useful work out of small local models — 7B to
13B parameter models running in LM Studio, Ollama, or similar tools — where
context windows are tight and RAM is the limiting constraint.

These techniques also apply when working with any model on tasks that exceed
its practical context limit, even if the model itself is large.

---

## Know your actual budget before you start

Before sending anything to a local model, establish the real available context:

```sh
# Estimate token count of a file before sending it
wc -c path/to/file.ts | awk '{printf "Approx tokens: %d\n", $1/4}'

# More accurate: use the chunk tool with --dry-run to see chunk sizes
./tools/chunk-file.sh --dry-run path/to/file.ts
```

A rough budget calculation for a typical local model session:

```
Total context window (e.g. 8,192 tokens)
  - System prompt / skill:     ~500 tokens   (use a `low` budget skill)
  - Response buffer:           ~1,000 tokens  (space for the model to respond)
  - Conversation history:      ~500 tokens    (prior turns in this session)
  ──────────────────────────────────────────
  Available for task content:  ~6,192 tokens  (~25 KB of text or ~600 lines)
```

When in doubt, leave more room than you think you need. Models degrade
noticeably when their window is over ~80% full.

---

## Technique 1: Chunking

Break large inputs into pieces and process each chunk in a separate request.
This is the most reliable workaround for the big-file problem.

### Using the built-in tool

```sh
# Split a file into chunks of ~1,500 tokens each
./tools/chunk-file.sh path/to/file.ts

# Outputs: file.part-1.ts, file.part-2.ts, ...

# Process each chunk with a prompt
for chunk in file.part-*.ts; do
  ./tools/fetch-prompt.sh code/code-review | \
    sed "s/{{CODE}}/$(cat $chunk)/" | \
    your-model-cli
done
```

### Manual chunking rules of thumb

- For code review: chunk by logical unit (function, class, module) rather than
  by line count. Never split a function across chunks.
- For documentation or specs: chunk by section heading.
- For data files: chunk by record batch.
- Overlap chunks by ~10% (repeat the last few lines of the previous chunk) so
  the model has context for what it's continuing from.

### Reassembly

After processing all chunks, consolidate the results with a final synthesis
prompt. See
[`../../prompts/agent-orchestration/summarize-for-handoff.md`](../../prompts/agent-orchestration/summarize-for-handoff.md)
for a low-context prompt designed for this.

---

## Technique 2: Use `-minimal` skill variants

Every `medium` and `high` context budget skill in this repo has a `-minimal`
sibling directory. The minimal variant strips the skill down to role, core
task, and output format — typically under 500 tokens — leaving the bulk of the
context window for your task content.

```
skills/
  coding/implement-feature/         ← full skill (~2k tokens)
  coding/implement-feature-minimal/ ← stripped variant (~400 tokens)
```

Use the minimal variant when:

- Your model has an 8k or smaller context window
- Your task content (the file, spec, or codebase excerpt) is large
- You've hit the compounding history problem mid-session

The trade-off is reduced instruction detail. The minimal variant gives the
model less guidance, which increases the chance of generic or imprecise output.
Use it when context pressure forces the choice, not as the default.

---

## Technique 3: Extract before sending

Instead of sending an entire file, extract only the relevant portion.

```sh
# Send only the function you're asking about
sed -n '/function myFunc/,/^}/p' src/utils.ts | pbcopy

# Send only the lines around an error
grep -n "error" src/utils.ts | head -20
```

For code review or debugging, you rarely need the entire file — the relevant
function plus its immediate dependencies is usually sufficient.

---

## Technique 4: Summarize history before it accumulates

Long sessions fill the context window with conversation history. When you're
approaching the limit (watch for the model starting to ignore early
instructions), summarize the session and restart.

A good mid-session summarization prompt:

```
Summarize our conversation so far in bullet points. Include:
- The task we were working on
- Decisions made
- Current state of the work
- What we were about to do next

Keep the summary under 300 words.
```

Paste that summary as the first message of a new session to restore context
without the accumulated token cost.

---

## Technique 5: One task per session

Every message in a session adds to the history cost. A session that starts
with code review and drifts into refactoring, then architecture discussion,
will exhaust its context window faster than three focused sessions.

**Pattern:** one clearly scoped task per session. Start a new session when the
task changes, not just when the window fills up.

This also tends to produce better output — models respond more reliably to a
single focused instruction than to a long conversation with many topic shifts.

---

## Technique 6: Prefer structured output formats

When the model produces structured output (JSON, markdown with clear headers,
numbered lists), it tends to be more concise than freeform prose. Less verbose
output means less history accumulation and more room for subsequent turns.

Add an explicit output constraint to any prompt when working with limited
context:

```
Respond in bullet points only. Maximum 10 bullets. No prose.
```

or

```
Respond with a JSON object only. No explanation.
```

---

## Technique 7: Offline pre-processing

Some tasks can be partially completed without an AI model, reducing what needs
to be sent:

- **Linting before review**: run ESLint/Pylint first and send only the
  flagged sections for AI review, not the whole file
- **Diff instead of full file**: for a change review, send `git diff HEAD`
  rather than the entire modified file
- **Filtered logs**: grep for the relevant error lines before sending logs
  to the model

```sh
# Send only the changed lines for review
git diff HEAD -- src/utils.ts | ./tools/fetch-prompt.sh code/code-review
```

---

## Model configuration tips for LM Studio

When running models locally, these settings help with constrained contexts:

| Setting                | Recommendation                         | Reason                                                     |
| ---------------------- | -------------------------------------- | ---------------------------------------------------------- |
| Context length (n_ctx) | Set to model's trained max, not higher | Exceeding the trained context degrades quality             |
| Temperature            | 0.1–0.3 for code tasks                 | Lower = more deterministic, fewer wasted tokens on hedging |
| Max tokens (n_predict) | 512–1024 for focused tasks             | Prevents runaway verbose responses that fill history       |
| Repeat penalty         | 1.1–1.2                                | Reduces repetitive output, keeps responses tighter         |
| Batch size (n_batch)   | Match your RAM; 512 is a safe default  | Affects speed, not quality                                 |

For model selection guidance, see
[`../models/lm-studio-setup.md`](../models/lm-studio-setup.md).

---

## Quick reference: which technique for which problem

| Symptom                            | Likely cause                  | Technique                              |
| ---------------------------------- | ----------------------------- | -------------------------------------- |
| "File too long" error              | Task content exceeds context  | Chunking (Technique 1)                 |
| Model ignores system instructions  | History overflow              | Summarize and restart (Technique 4)    |
| Output is generic or imprecise     | Skill too large for window    | Use `-minimal` variant (Technique 2)   |
| Slow responses, high RAM usage     | Context window near capacity  | Extract relevant section (Technique 3) |
| Session drifts and loses coherence | Too many tasks in one session | One task per session (Technique 5)     |
| Responses are very long and wordy  | No output constraint          | Structured output format (Technique 6) |
| Reviewing a large changed file     | Full file unnecessary         | Offline pre-processing (Technique 7)   |

---

## Further reading

- [`context-window-basics.md`](./context-window-basics.md) — foundational
  concepts behind everything above
- [`chunking-strategies.md`](./chunking-strategies.md) — deeper coverage of
  chunking approaches for different content types
- [`context-budget-guide.md`](./context-budget-guide.md) — decision tree for
  choosing the right prompt/skill for your setup
- [`../models/lm-studio-setup.md`](../models/lm-studio-setup.md) — LM Studio
  configuration and model selection
- [`../../tools/README.md`](../../tools/README.md) — `chunk-file.sh` and
  `fetch-prompt.sh` usage
