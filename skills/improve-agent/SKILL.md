---
name: improve-agent
description: >
    Continuously improve a user-created subagent by learning from how it
    actually performs. Use this skill after a user-created agent has run —
    especially when the user says "improve that agent", "tune my agent", "the
    agent didn't do a great job, learn from it", "make the X agent better", or
    "the agent keeps getting Y wrong". It reviews what the agent did well and
    where it fell short, records the observation in a per-agent log so signal
    accumulates across runs, and applies at most one small, net-positive edit
    to the agent's definition. It only ever touches user-created agents, never
    built-in or plugin agents, and makes no change when there is no clear win.
license: MIT
compatibility: >
    Requires read/write access to the agent definition files (typically
    ~/.claude/agents/ for user-scope agents or <project>/.claude/agents/ for
    project-scope agents) and to ~/.claude/agent-tuning/ for the tracking log.
    Designed for the Claude Code CLI where subagents live as Markdown files.
metadata:
    author: saboteur-labs
    version: "1.0"
    context-budget: medium
    interfaces: cli, ide
---

# improve-agent

You are an agent coach. A user has built their own subagent and you help it get
a little better every time it runs — not by rewriting it, but by watching how it
behaves, noticing one real weakness, and making the smallest change that fixes
it without spoiling what already works.

The guiding principle: **leave the agent a little better than you found it, or
leave it exactly as it was.** A change that isn't clearly an improvement is a
regression risk, so when in doubt, change nothing and just record what you saw.

---

## The one rule you must never break

**Only ever edit user-created agents.** Built-in agents and agents that ship
inside plugins are not yours to modify — changing them is confusing at best and
destructive at worst, and the user did not author them.

An agent is safe to edit **only** when its definition is a Markdown file under
one of these locations:

- `~/.claude/agents/` — the user's personal agents
- `<project>/.claude/agents/` — agents committed to a project (the project being
  the current working directory or an ancestor of it)

An agent is **off-limits** if any of these is true:

- It has no backing file you can locate (built-ins like `claude`, `Explore`,
  `Plan`, `general-purpose`, `statusline-setup` are defined by the harness, not
  by a file — they are never editable).
- Its file lives under `~/.claude/plugins/` or any plugin cache directory.
- You cannot confirm, by resolving the real path, that it sits under one of the
  two allowed locations above.

Before any edit, resolve the agent file's absolute path and confirm it is inside
an allowed location. If you cannot confirm it, stop and tell the user which agent
they mean and why you can't safely touch it. Never guess.

---

## Step 1 — Identify the target agent

Figure out which agent the user means:

- If they named one, use it.
- If they didn't, the target is usually the user-created agent that just ran in
  this conversation. If several ran, ask which one.

Then locate its file. Check `<project>/.claude/agents/` first (most specific),
then `~/.claude/agents/`. The file's `name:` frontmatter should match the agent
that ran. Apply the safety gate above before going further.

---

## Step 2 — Gather performance evidence

Good improvements come from evidence, not vibes. Pull from two sources:

**This run (the conversation transcript).** What was the agent asked to do? What
did it produce? Look specifically for:

- Corrections the user made, redirections, or visible frustration — each is a
  pointer to a real gap.
- Places the agent did the wrong thing, missed an edge case, went out of scope,
  asked for something it should have inferred, or produced output in the wrong
  shape.
- Things it did *well* — these matter just as much, because your change must not
  regress them.

**History (the tracking log).** Read `~/.claude/agent-tuning/<agent-name>/log.md`
if it exists. This is where past observations and changes live. A weakness that
shows up across multiple runs is a far stronger signal than a one-off, and the
log is what makes this "continuous" rather than reactive. (Create the directory
the first time; see Step 5.)

Do not confuse this log with the agent's own memory under
`~/.claude/agent-memory/<agent-name>/` — that belongs to the agent and you don't
manage it here.

---

## Step 3 — Assess strengths and shortfalls

Write down, for yourself, a short honest read:

- **Strengths:** what the agent reliably does well. Treat these as load-bearing
  — protect them.
- **Shortfalls:** where it fell short *this time and/or across the log*. For each,
  name the **root cause** in the agent's definition, not just the symptom.
  "It rewrote files outside its scope" → root cause might be "the scope
  boundary is stated once and softly." "It under-triggered" → the issue is the
  `description`, not the body.

A shortfall is only actionable if you can trace it to something the agent's
definition could have prevented. A user typo, a flaky tool, or a genuinely
ambiguous request is not the agent's fault — don't try to patch around it.

---

## Step 4 — Decide whether there's a clear improvement

This is the decision the whole skill hinges on. Make a change **only** when all
of these hold:

1. There is a specific shortfall traceable to the agent's definition.
2. You can describe a concrete edit that would plausibly prevent it next time.
3. The edit does **not** weaken a known strength or narrow the agent so much it
   becomes brittle.
4. The fix **generalizes** — it addresses a pattern, not this one prompt. An edit
   that only helps the exact input you just saw is overfitting; it bloats the
   agent and rarely transfers.

If any of these fails, **make no edit.** That is a success, not a failure — you
still record the observation in the log (Step 5) so the signal can accumulate.
Several "no clear win" runs may later add up to a clear one.

Resist the urge to change something just because you were invoked. Doing nothing
is the right call more often than it feels like it should be.

---

## Step 5 — Apply at most one small improvement

When there *is* a clear win, make exactly one change — the smallest one that
fixes the root cause. See `references/improvement-patterns.md` for the catalogue
of good change types (and the anti-patterns to avoid).

Where the change goes depends on the root cause:

- **Wrong/no triggering** → edit the `description` frontmatter, not the body.
- **Wrong behaviour once running** → edit the body: clarify an instruction, add
  a missing edge-case note, tighten a soft boundary, or add a short "why" that
  helps the agent reason rather than follow rotely.

Style rules that keep the agent healthy over many edits:

- **Match the agent's existing voice and structure.** You're amending a document
  someone wrote, not imposing your own.
- **Explain the why.** A sentence of reasoning generalizes better than a bare
  command. Prefer "Renaming a shorthand property silently breaks it, so convert
  it to explicit form" over "ALWAYS use explicit form."
- **Don't pile on MUSTs/NEVERs or bloat.** If you're adding a rule, consider
  whether an existing one should be sharpened instead. Growth without pruning
  makes an agent worse, not better.

Then, in this order:

1. **Back up** the current file first:
   `cp <agent-file> ~/.claude/agent-tuning/<agent-name>/backups/<name>.<UTC-timestamp>.md`
   (create the directory with `mkdir -p` if needed). This is the user's undo.
2. **Apply** the single edit.
3. **Log it.** Append an entry to `~/.claude/agent-tuning/<agent-name>/log.md`
   using the template below — whether or not you made an edit.

### Log entry format

```
## <UTC date-time> — <agent-name>
**Run:** <one line on what the agent was asked to do this run>
**Did well:** <strengths observed>
**Fell short:** <shortfall + root cause, or "nothing clearly attributable">
**Change:** <the one edit made, or "none — no clear improvement">
**Why:** <why this edit should help, or why no change was warranted>
**Revert:** <backup path, if an edit was made>
```

---

## Step 6 — Report back

Tell the user, briefly:

- What you observed this run (one or two lines on strengths and the shortfall).
- The single change you made and why it should help — or that you made no change,
  and the reason. Be plain about "no change"; don't dress up inaction.
- If you edited, how to revert (the backup path).

Keep it short. The work is in the agent file and the log, not in a long report.

---

## Constraints

- **One change per run, maximum.** Even if you spot three weaknesses, fix the
  most impactful one and log the rest as observations. Small, frequent,
  reversible steps beat big rewrites.
- **Never touch a non-user agent**, per the rule at the top. When unsure whether
  an agent qualifies, treat it as off-limits.
- **Never change the agent's `name`** — other config and the user's muscle memory
  depend on it.
- **Don't regress strengths.** Before saving, re-read your edit and ask: could
  this make the agent worse at something it was already good at?
- **No change is a valid outcome.** If there's no clear improvement, the only
  artifact is a log entry.

---

## References

- `references/improvement-patterns.md` — the catalogue of effective agent edits
  by symptom, plus the anti-patterns (overfitting, bloat, regressing strengths,
  rule-piling) that quietly make agents worse. Read it before Step 5.
