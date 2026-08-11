# Contributing to this repo with AI

How to use the repo's own skills and prompts to propose additions and
improvements — the meta-workflow of using AI tools to maintain an
AI workflow knowledge base.

---

## The right mental model

When adding to this repo, treat it as any other codebase you'd use AI
to help with: understand the structure first, use the repo's own patterns,
propose before implementing, review before accepting.

The repo has dedicated tooling for this:

- `skills/repo-maintenance/` — the operating instructions for an agent
  working in this repo
- `skills/freshness-check/` — assesses whether content
  is likely still accurate before it enters the repo
- `templates/change-proposal-template.md` — the required format for any
  proposed change
- `guides/repo-maintenance/dependency-map.md` — what must change together

---

## Recommended workflow for adding new content

### Step 1: orient the agent

Before asking an agent to propose any addition, inject the
`repo-maintenance` skill. This gives it the operating rules, structure
knowledge, and style guide in one shot.

```sh
# Copy the skill for use as a system prompt or IDE context
./tools/fetch-prompt.sh --skill repo-maintenance
```

For small local models, use the minimal variant:

```sh
./tools/fetch-prompt.sh --skill repo-maintenance-minimal
```

### Step 2: describe what you want

Give the agent a clear description of the addition:

```
I want to add a prompt for generating database migration scripts.
Category: code. It should accept a schema diff and produce a safe,
reversible migration file.
```

The agent will use the `repo-maintenance` skill to:

- Identify the correct template (`templates/prompt-template.md`)
- Consult the dependency map (add to `prompts/README.md` and `CHANGELOG.md`)
- Draft the content using the style guide
- Produce a proposal using `templates/change-proposal-template.md`

### Step 3: review the proposal

Read the proposal carefully before approving. Check:

- Does the draft content match the repo's style? (Compare against two or
  three existing prompts in the same category)
- Are all `{{PLACEHOLDERS}}` filled?
- Are the dependency map couplings satisfied (README + CHANGELOG)?
- Are there open questions that need your input?
- Does the "Sources" section cite sources for any external claims, or
  flag them as needing verification?

### Step 4: run freshness check on external claims

If the proposed content references external tools, specs, or settings:

```sh
# Pipe the draft file through the freshness-check skill
./tools/fetch-prompt.sh --skill freshness-check | your-model-cli \
  --system - \
  --message "Review this draft for staleness: $(cat draft.md)"
```

Review the freshness report. Verify any high-risk claims before accepting
the proposal.

### Step 5: approve and create the files

Once the proposal is approved, instruct the agent to produce the final
files. Review the diff as you would any PR.

---

## Guardrails built into this workflow

**The proposal step is mandatory.** An agent using the `repo-maintenance`
skill will not produce final content without a proposal — it is
constrained to propose first. If an agent skips the proposal and produces
files directly, something has gone wrong.

**The dependency map prevents incomplete changes.** CI will block a PR
that adds a prompt without updating `prompts/README.md` and `CHANGELOG.md`.
The proposal step should catch this before CI does, but CI is the safety net.

**The freshness-check skill surfaces staleness before it enters the repo.**
Running it on any draft that references external systems catches outdated
claims at proposal time, not six months later when someone acts on stale
guidance.

**The style guide prevents AI-typical quality degradation.** The
`repo-maintenance` skill loads the style guide and applies it when drafting.
Common AI-generated patterns (hedging language, vague requirements, "best
practices" without specifics) are flagged and replaced.

---

## Common pitfalls

**Asking the agent to "just add it" without a proposal**
Bypassing the proposal step produces content that hasn't been checked
against the dependency map, the style guide, or existing content for
contradictions. Always require a proposal first, even for small changes.

**Accepting a proposal without checking the Sources section**
An agent operating from training data will confidently assert things
about external tools that may be outdated. If the Sources section is
empty for a claim about an external tool, that's a red flag — ask the
agent to flag it as an open question or provide a source.

**Using the minimal skill for complex additions**
`repo-maintenance-minimal` is appropriate for simple, well-scoped changes
(add one prompt, update a README row). For additions that affect multiple
files or introduce new patterns, use the full `repo-maintenance` skill.

**Forgetting to update `review-by` dates when modifying content**
When you modify a guide that has a `review-by` field, reset the date
to reflect when you re-verified the content. Leaving the old date means
the file will be flagged as stale sooner than it should be.

---

## Further reading

- [`how-this-repo-is-structured.md`](./how-this-repo-is-structured.md)
- [`dependency-map.md`](./dependency-map.md)
- [`../../AGENTS.md`](../../AGENTS.md)
- [`../../templates/change-proposal-template.md`](../../templates/change-proposal-template.md)
