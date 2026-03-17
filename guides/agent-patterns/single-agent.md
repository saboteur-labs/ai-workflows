# Single-agent patterns

How to structure work for a single AI agent in one session. This is the
foundation for everything else in the agent patterns section — multi-agent
orchestration and human-in-the-loop patterns both build on the principles
here.

"Single-agent" means one model, one session, one well-scoped task. Most
of the work in this repo's workflows is single-agent. Getting this right
is more valuable than reaching for orchestration prematurely.

---

## What makes a good single-agent task

A task is well-suited for a single agent when it has:

**A clear, testable completion condition**
The agent — and you — can tell unambiguously when the task is done. "Write
unit tests for `parseDate`" is clear. "Improve the codebase" is not.

**All required context available upfront**
Everything the agent needs to complete the task can be provided at the
start of the session — a spec, a source file, a set of requirements. Tasks
that require the agent to discover context mid-session (e.g. "figure out
what this codebase does, then improve it") span two different tasks and
should be split.

**A scope that fits the context window**
The task and all its context fits within the model's practical budget. If
it doesn't, either chunk the content
([`../context/chunking-strategies.md`](../context/chunking-strategies.md))
or split the task.

**A single coherent concern**
The task touches one logical unit of work. "Implement the user export
feature" is one concern. "Implement user export and also review the auth
module" is two. Split them — the second task will get worse output because
the agent's attention is divided.

---

## The plan-confirm-execute loop

The most reliable single-agent pattern for non-trivial tasks. Never skip
the confirmation step.

```
1. INJECT   Inject the relevant skill or paste the prompt
2. BRIEF    Describe the task and provide all required context
3. PLAN     Ask the agent to produce a plan before writing any code or output
4. CONFIRM  Review the plan — catch misunderstandings here, not after implementation
5. EXECUTE  Instruct the agent to proceed with the confirmed plan
6. VALIDATE Check the output against the completion condition
7. CLOSE    Accept, request revisions, or note follow-up work and end the session
```

The confirmation step (4) is where most value is created or destroyed. A
plan review takes 30 seconds. Catching a misunderstanding at plan stage
costs nothing. Catching it after a full implementation costs a re-run and
potentially introduces subtle errors in the revision.

**How to confirm a plan effectively:**

- Read for completeness: does the plan cover all requirements?
- Read for correctness: does each step follow logically from the last?
- Read for scope: does the plan include anything not in the requirements?
- If all three pass, say "proceed" — don't add new requirements at this stage

**If the plan is wrong:**
Correct it in plain language before the agent starts. "Step 3 should use
the existing `formatDate` utility from `src/lib/utils.ts` instead of
implementing its own." One correction per message. Avoid rewriting the
entire brief — the agent has the context from the earlier messages.

---

## Providing context effectively

The agent can only work with what it's given. Weak context produces weak
output regardless of model size or prompt quality.

**What to always provide:**

- The task description, stated precisely
- The acceptance criteria or completion condition
- Any constraints (must not break existing API, must use existing test framework)
- The relevant code, spec, or document — not the entire codebase, just
  what the task touches

**What to provide when relevant:**

- Project conventions the agent wouldn't know (naming patterns, error
  handling style, test structure)
- Non-obvious dependencies ("this module is called by the billing service
  — don't change its public interface")
- What has already been tried and didn't work (for debugging tasks)

**What not to provide:**

- Code or documents unrelated to the task — they dilute context and
  consume window space
- Vague background ("this is part of a larger project") without specifics
- Requirements that contradict each other — resolve ambiguities before the
  session, not during

---

## Output validation

Never accept agent output without validation. The appropriate depth depends
on the task's risk level.

**Low-risk tasks** (explanation, summarisation, planning documents):

- Read for coherence and completeness
- Check that the output addresses the stated requirements
- Look for hallucinated facts or confident claims that seem off

**Medium-risk tasks** (code generation, refactoring):

- Read the code before running it
- Verify the agent didn't change things it was asked not to change
- Run the test suite — don't assume tests pass because the agent said so
- Check types and linting if the project has them

**High-risk tasks** (database migrations, infrastructure changes, anything
destructive or irreversible):

- Apply the human-in-the-loop patterns from
  [`human-in-the-loop.md`](./human-in-the-loop.md) — these tasks warrant
  explicit review gates, not just a read-through

**When output is wrong:**
Be specific in correction requests. "This is wrong" produces worse
revisions than "The `validateUser` function on line 12 throws when `email`
is `undefined`, but the spec requires it to return `false` instead."

The agent has the full session context — a specific correction is all it
needs. Don't re-paste the entire brief unless the session has drifted far
enough that the agent seems to have lost track of the original requirements.

---

## Session hygiene

**One task per session.** When the task is done, close the session. Letting
a session drift from implementation to code review to architecture discussion
degrades output quality on each subsequent task as context accumulates.

**Start fresh for revisions that change scope.** If a review reveals that
the task was under-specified and the scope needs to expand significantly,
start a new session with the revised brief rather than continuing in the
same one. The accumulated context from the wrong-scope session is noise.

**Name your sessions.** Most chat interfaces support session naming. Name
each session after its task. This makes it easy to return to a session to
reference what was decided, and reinforces the one-task discipline.

**Don't use session history as documentation.** If the session produced a
decision worth preserving — an architectural choice, a spec agreed during
the session — copy it out to a file before closing. Session history is not
a reliable archive.

---

## When single-agent isn't enough

A single-agent session is insufficient when:

- **The task is too large** to complete in one session without context
  degradation — split it and use the handoff prompt between sessions
- **The task has distinct phases that require different roles** — a planner
  and an implementer benefit from separate sessions with clean context
- **The output needs independent review** — the same agent that produced
  code is not a reliable reviewer of that code; use a separate session or
  a separate agent for review
- **The task involves multiple large files** that together exceed the
  context window — use multi-agent orchestration with one agent per file
  or logical unit

In all of these cases, the answer is not a more powerful model or a longer
session — it's better task decomposition. See
[`multi-agent-orchestration.md`](./multi-agent-orchestration.md).

---

## Further reading

- [`multi-agent-orchestration.md`](./multi-agent-orchestration.md) — when
  and how to decompose work across multiple agents
- [`human-in-the-loop.md`](./human-in-the-loop.md) — inserting review
  gates for high-risk tasks
- [`../../prompts/agent-orchestration/summarize-for-handoff.md`](../../prompts/agent-orchestration/summarize-for-handoff.md)
  — carrying context between sessions
- [`../../prompts/agent-orchestration/self-critique-loop.md`](../../prompts/agent-orchestration/self-critique-loop.md)
  — lightweight output validation within a session
- [`../context/context-budget-guide.md`](../context/context-budget-guide.md)
  — scoping tasks to fit the available context window
