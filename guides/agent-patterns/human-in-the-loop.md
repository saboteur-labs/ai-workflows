# Human-in-the-loop patterns

When and how to insert human review gates into AI-augmented workflows.
The goal is not to review everything — it's to review the right things at
the right points so that errors don't compound and irreversible mistakes
don't happen.

---

## The core principle

An AI agent can propagate errors silently. A wrong assumption in a spec
becomes a wrong design decision in an implementation becomes a wrong test
that passes incorrectly. Each handoff multiplies rather than catches the
error, because the next agent treats the previous agent's output as ground
truth.

Human review gates interrupt this chain at the points where errors are
cheapest to catch and most expensive to miss.

The discipline is **not** reviewing everything — that eliminates the
productivity benefit of AI assistance. It's identifying the specific
decision points where human judgment is non-negotiable and inserting
gates only there.

---

## When a gate is non-negotiable

Some categories of operation always warrant a human gate, regardless of
how confident the agent's output appears:

**Irreversible operations**
Anything that cannot be undone without significant cost: database
migrations, data deletions, infrastructure changes, production deployments,
secrets rotation. The agent may produce a correct plan and still execute
it incorrectly. Review the plan before execution, not after.

**Changes to shared interfaces**
Public APIs, shared library interfaces, database schemas used by multiple
services, event formats consumed by other teams. A breaking change here
has blast radius beyond what the agent can see from its context window.

**Security-relevant code**
Authentication, authorisation, input validation, cryptography, session
management. These are domains where a subtle error is often invisible in
review but exploitable in production. Apply extra scrutiny proportional
to the attack surface.

**First run of a new workflow**
The first time you run a multi-agent orchestration pattern, a new skill,
or a new prompt against real work, insert gates at every handoff. Once
you've validated that the pattern produces reliable output, you can
reduce gate frequency.

**Any output that will be hard or expensive to redo**
If the agent produces something that will take significant effort to fix
if it's wrong — a large spec, a multi-file refactor, a test suite — review
it before it becomes the input to the next stage.

---

## Gate placement in single-agent workflows

In a single-agent session, the natural gate points are:

```
BRIEF  → [Gate: is the task scoped correctly?]
       → PLAN
PLAN   → [Gate: is the plan correct and complete?]  ← most valuable gate
       → EXECUTE
OUTPUT → [Gate: does the output meet the spec?]
       → ACCEPT or REVISE
```

The plan gate is almost always worth taking — it's fast (30–60 seconds to
read a plan) and it's the last point where a misunderstanding is cheap to
correct. See [`single-agent.md`](./single-agent.md) for the full
plan-confirm-execute loop.

The output gate depth should match the risk level of the task.

---

## Gate placement in multi-agent workflows

In a multi-agent workflow, insert gates between sessions at the handoff
points that carry the most downstream risk:

```
PLAN session output
  → [Gate: spec review] ← catches requirement misunderstandings
  → IMPLEMENT session

IMPLEMENT session output
  → [Gate: implementation review] ← catches correctness issues
  → REVIEWER session (or direct to merge if low-risk)

REVIEWER session output
  → [Gate: findings review] ← confirms findings before acting on them
  → fixes or approval
```

You don't always need all three. A low-risk feature with a clear spec
and no shared interfaces might only need the post-implementation gate.
A migration or API change warrants all three.

**The spec review gate** is the highest-leverage gate in the workflow.
A spec that passes human review before implementation eliminates the
largest class of multi-agent errors — requirements misunderstood by the
planner that the implementer faithfully executes. This gate should be
fast: read for ambiguity, missing non-goals, and untestable requirements.

---

## What to review at each gate

**Spec review checklist**

- [ ] Goals are outcomes, not tasks
- [ ] Non-goals explicitly exclude at least one plausible scope extension
- [ ] Every functional requirement is independently testable
- [ ] No requirement contradicts another
- [ ] Open questions are listed, not buried in requirement wording
- [ ] Scope feels right — not too large for one implementation session

**Implementation review checklist**

- [ ] Output satisfies every functional requirement in the spec
- [ ] No existing functionality was modified without explicit requirement
- [ ] Error cases are handled, not just happy paths
- [ ] Tests cover the behaviour described in the spec, not just lines
- [ ] Implementation summary's "assumptions made" are acceptable
- [ ] Linter and type checker pass — verify, don't assume

**Migration / destructive operation checklist**

- [ ] Operation is reversible, or a rollback plan is documented
- [ ] Tested against a non-production environment first
- [ ] Data that will be modified has been backed up or can be restored
- [ ] The scope of impact is understood (which services, which data)
- [ ] A second human has reviewed for high-stakes operations

---

## Designing prompts that surface uncertainty

Agents are often more confident in their output than is warranted. A
well-designed prompt asks the agent to flag its own uncertainty before
you have to find it.

Add this instruction to any prompt or skill where catching gaps matters:

```
Before presenting your output, list any:
- Assumptions you made that are not stated in the requirements
- Requirements that were ambiguous and how you resolved the ambiguity
- Areas where you are less confident in your approach
- Anything you chose not to implement and why
```

The agent won't catch everything this way — but it will surface the gaps
it knows about, which are often the most important ones. Review those
items specifically before accepting the output.

---

## Calibrating gate frequency over time

Gates are a cost. The right frequency for a given workflow depends on how
reliable that workflow has proven to be:

| Workflow maturity        | Gate frequency                         |
| ------------------------ | -------------------------------------- |
| First time running       | Gate at every handoff and every output |
| 2–5 successful runs      | Gate at handoffs; spot-check outputs   |
| Established, well-tested | Gate only at high-risk operations      |

Track failures when they occur. If a gate consistently passes without
catching anything, it's a candidate for removal. If a point in the
workflow consistently produces errors that a gate would catch, add one.

Calibration is per-workflow, not per-tool. A workflow that reliably
produces good specs may still need tight gates on implementation sessions
if the implementation skill is newer or less tested.

---

## A note on automated checks

Some tooling supports automated validation — linters, type checkers, test
runners — that can serve as lightweight gates without requiring human
attention. These complement human gates, they don't replace them.

Automated checks catch syntactic and structural errors. Human gates catch
semantic errors — the code does what it says but not what was intended.
Both are necessary for high-stakes work.

Where automated checks are available, run them before the human gate. It
saves the reviewer from finding trivial issues and lets them focus on the
semantic review that only a human can do.

---

## Further reading

- [`single-agent.md`](./single-agent.md) — the plan-confirm-execute loop
  and output validation patterns
- [`multi-agent-orchestration.md`](./multi-agent-orchestration.md) — where
  to place gates in multi-agent workflows
- [`../../prompts/agent-orchestration/self-critique-loop.md`](../../prompts/agent-orchestration/self-critique-loop.md)
  — asking the agent to surface its own uncertainty before review
- [`../../prompts/code/code-review.md`](../../prompts/code/code-review.md)
  — structured code review prompt for the implementation gate
