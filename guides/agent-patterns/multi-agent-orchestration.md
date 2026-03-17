# Multi-agent orchestration

Patterns for decomposing complex work across multiple AI agents — separate
sessions, each with a focused role and clean context. When to reach for
this, how to structure the handoffs, and the failure modes to watch for.

Read [`single-agent.md`](./single-agent.md) first. Multi-agent
orchestration is the right tool only when single-agent patterns have
genuinely hit their limits. Most tasks that feel like they need
orchestration actually need better task scoping.

---

## When orchestration is actually warranted

Reach for multi-agent patterns when you have hit one or more of these
genuine constraints — not just because a task feels large:

**Context overflow**
The task and its required context genuinely exceed the model's practical
window even after chunking and scope reduction. The solution is to give
each agent a focused slice, not to cram everything into one session.

**Role conflict**
The same agent cannot reliably play two opposing roles in the same session.
A model that just generated code will not critique it impartially — it has
anchoring bias toward its own output. Separate sessions with clean context
produce better reviews than asking the generating agent to self-critique
beyond a single pass.

**Sequential dependency with context bloat**
The output of phase 1 (e.g. a spec) becomes the input of phase 2 (e.g.
task breakdown), which becomes the input of phase 3 (e.g. implementation).
Running all three in one session is possible but each phase's accumulated
history crowds out the context needed for the next. Clean handoffs between
sessions keep each phase focused.

**Parallel independent units**
Multiple independent files, modules, or tasks that can be processed
simultaneously. Each gets its own agent with full context for that unit,
rather than one agent context-switching across all of them.

---

## The three core roles

Most development orchestration reduces to three roles. You don't always
need all three — use the minimum that the task requires.

**Planner**
Input: a feature idea, a requirement, or a problem statement.
Output: a structured plan, spec, or task list.
Skills: [`skills/planning/spec-writer/`](../../skills/planning/spec-writer/),
prompts: [`prompts/planning/`](../../prompts/planning/).

The planner's output is the primary artifact passed to the implementer.
It should be complete and unambiguous — the implementer should not need
to make significant decisions that belong in planning.

**Implementer**
Input: the planner's output plus relevant code context.
Output: working code, tests, and an implementation summary.
Skills: [`skills/coding/implement-feature/`](../../skills/coding/implement-feature/).

The implementer should receive a spec good enough to act on without
going back to the planner. If the implementer frequently needs to ask
clarifying questions, the planner's output is under-specified.

**Reviewer**
Input: the implementer's output plus the original spec.
Output: a structured review — findings, severity, suggested fixes.
Prompts: [`prompts/code/code-review.md`](../../prompts/code/code-review.md).

The reviewer must receive both the spec and the implementation — reviewing
code without the spec produces style comments, not correctness checks.
The reviewer session must be started fresh, without the implementer's
session history, to avoid anchoring bias.

---

## Handoff structure

A handoff is the artifact passed between agents. Its quality determines
the quality of every downstream agent's output. A weak handoff is the
most common source of failure in multi-agent workflows.

**A good handoff contains:**

- The task the next agent needs to perform (single, specific)
- The output of the previous agent that is relevant to that task
- Any constraints or context the next agent needs but won't infer
- An explicit statement of what "done" looks like for the next agent

**A bad handoff contains:**

- The full session history of the previous agent (too much noise)
- Vague summaries ("we discussed the feature") without specifics
- Missing constraints that the previous agent knew but didn't output
- Implicit assumptions ("you know what we're building")

Use [`prompts/agent-orchestration/summarize-for-handoff.md`](../../prompts/agent-orchestration/summarize-for-handoff.md)
to generate handoffs at the end of each session. Pass it the session
content and the next agent's task — it produces a compact, structured
handoff artifact.

---

## The planner-implementer-reviewer pattern

The most common orchestration pattern in this repo's workflows. Three
sessions, three clean contexts.

```
Session 1: PLAN
─────────────────────────────────────────────────────
Inject:   skills/planning/spec-writer
Input:    Feature idea or requirement
Output:   Feature spec (markdown document)
Handoff:  The spec itself — no summarisation needed
          "Implement this spec: [spec]"

Session 2: IMPLEMENT
─────────────────────────────────────────────────────
Inject:   skills/coding/implement-feature
Input:    The spec from session 1 + relevant source files
Output:   Implementation + tests + implementation summary
Handoff:  summarize-for-handoff.md →
          "Review this implementation against its spec: [spec] [summary]"

Session 3: REVIEW
─────────────────────────────────────────────────────
Inject:   (no skill — use prompts/code/code-review.md directly)
Input:    The spec + the implementation summary + key code sections
Output:   Structured review with findings and severity
Handoff:  Review findings → back to implementer if fixes needed,
          or to human for final approval
```

**What makes this work:**

- Each session has exactly one role and one clear output artifact
- No session history carries forward — only the artifact
- The reviewer has both the spec and the implementation, enabling
  correctness review not just style review

---

## Parallel processing pattern

For tasks that can be split into independent units — reviewing multiple
files, generating tests for multiple modules, analysing multiple specs.

```
Decompose:  Use prompts/agent-orchestration/decompose-task.md
            to split the work into N independent units

Run N sessions in parallel (or sequentially if tooling doesn't
support parallelism):
  Session A: Unit 1 — full context for unit 1 only
  Session B: Unit 2 — full context for unit 2 only
  Session C: Unit 3 — full context for unit 3 only

Consolidate: Use prompts/agent-orchestration/summarize-for-handoff.md
             to merge outputs into a single result
```

The key requirement for this pattern is genuine independence. If unit 2
depends on the output of unit 1, they are not independent and must be
run sequentially with a handoff.

---

## Keeping humans in the loop

Multi-agent workflows can accumulate errors across sessions. An error in
the planner's spec propagates to the implementer, which propagates to
the reviewer's findings being about the wrong thing entirely.

Insert a human review gate between sessions whenever:

- The previous session's output will be difficult or expensive to redo
- The task involves irreversible operations (migrations, deployments)
- The workflow is novel and you haven't yet established that the
  handoffs produce reliable output

See [`human-in-the-loop.md`](./human-in-the-loop.md) for gate patterns.

---

## Common failure modes

**Spec that requires too many implementer decisions**
The planner produced ambiguous requirements and the implementer had to
make significant design choices. The implementation is coherent but may
not match what was intended. Fix: improve the spec before implementing,
or add a spec-review human gate.

**Reviewer anchored to the implementation**
The reviewer session was started with the implementer's session history
included. The reviewer soft-pedals issues because it has context about
why decisions were made. Fix: always start the reviewer session fresh with
only the spec and the implementation summary.

**Handoff artifact too large for the receiving session**
The planner produced a 5,000-token spec that, combined with the source
files, exceeds the implementer's context budget. Fix: trim the handoff
to only what the implementer needs, or use the `-minimal` skill variant.

**Parallel sessions producing inconsistent output**
Two implementer sessions processing different files made incompatible
design decisions because neither knew what the other was doing. Fix:
include shared constraints explicitly in every parallel session's brief,
or run sequentially with handoffs when the units aren't truly independent.

---

## Further reading

- [`single-agent.md`](./single-agent.md) — the foundation; start here
- [`human-in-the-loop.md`](./human-in-the-loop.md) — review gate patterns
  for multi-agent workflows
- [`../../prompts/agent-orchestration/decompose-task.md`](../../prompts/agent-orchestration/decompose-task.md)
  — splitting a task into independent units
- [`../../prompts/agent-orchestration/summarize-for-handoff.md`](../../prompts/agent-orchestration/summarize-for-handoff.md)
  — generating clean handoff artifacts
- [`../context/chunking-strategies.md`](../context/chunking-strategies.md)
  — splitting large inputs across agents
