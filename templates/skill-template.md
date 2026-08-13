# Skill template

This template produces a skill that conforms to the
[Agent Skills specification](https://agentskills.io/specification), ensuring
compatibility with Claude Code, GitHub Copilot (agent mode), VS Code, and any
other Agent Skills-compatible tool.

---

## Directory structure

Each skill is a **directory**, not a single file. The directory name becomes
the skill's `name` value in frontmatter. The only required file is `SKILL.md`.

```
skills/
└── <skill-name>/           ← directory name must match frontmatter `name`
    ├── SKILL.md            ← required: frontmatter + instructions
    ├── scripts/            ← optional: executable scripts the agent can run
    ├── references/         ← optional: supplementary docs loaded on demand
    └── assets/             ← optional: templates, schemas, static resources
```

To create a new skill: copy this entire directory, rename it using
`lowercase-kebab-case`, update `SKILL.md`, and add any scripts or references.

---

## SKILL.md format

### Frontmatter

The spec defines six frontmatter fields. Only `name` and `description` are
required. All others are optional but recommended.

```yaml
---
# ---------------------------------------------------------------
# REQUIRED
# ---------------------------------------------------------------

# name: must match the parent directory name exactly.
# Rules: lowercase letters, numbers, hyphens only. No leading,
# trailing, or consecutive hyphens. Max 64 characters.
name: skill-name

# description: what the skill does AND when to activate it.
# This is what the agent reads at startup to decide whether to
# load the full skill. Make it specific — include trigger phrases
# and the class of task this skill handles. Max 1024 characters.
description: >
    One to three sentences describing the capability and when to
    use it. Include concrete trigger phrases, e.g. "Use when asked
    to scaffold a new module, implement a feature from a spec, or
    when the user says 'build this'."

# ---------------------------------------------------------------
# OPTIONAL — include the ones that apply
# ---------------------------------------------------------------

# license: short license name or reference to bundled file.
license: LICENSE.txt

# compatibility: only include if the skill has specific
# environment requirements (tools, OS, network access, etc.).
# Omit if the skill works in any standard dev environment.
# Max 500 characters.
compatibility: Requires git and Node.js >= 18

# metadata: arbitrary key-value pairs.
# Use this for anything not covered by the spec fields above.
# Every key this repo uses is listed below — nothing reads this block except
# this repo's own tooling, so keys are bare rather than prefixed.
metadata:
    author: saboteur-labs
    version: "1.0"
    # context-budget: how much context this skill consumes.
    # low    — fits ~1k tokens; safe for small local models (7B)
    # medium — uses ~2–4k tokens; fine for 13B+ local or any hosted
    # high   — uses 4k+ tokens; use hosted or high-VRAM local models
    context-budget: low
    # interfaces: where this skill is designed to be injected.
    # Comma-separated list of: ide, chat, cli, api
    interfaces: ide, chat, cli, api
    # review-by: optional — set for skills that reference external tools,
    # CLI flags, or APIs that may change. Format: YYYY-MM-DD.
    # CI will warn when this date passes. Omit for evergreen skills.
    # review-by: YYYY-MM-DD
    # audience: optional — set to "repo" for a skill that maintains THIS
    # repository rather than shipping to consumers. It routes the skill's
    # changelog entries to CHANGELOG-repo-tools.md instead of CHANGELOG.md,
    # and check_atomicity.sh blocks a PR that updates the wrong one. Omit for
    # any skill someone copies into their own project — including one that
    # operates on the user's files, like improve-agent.
    # audience: repo
    # full-skill: optional — on a `-minimal` variant, names the full skill it
    # is derived from, so the pair can be found from either side.
    # full-skill: implement-feature
    # output-schema: optional — the schema id in schemas/ that governs a
    # document this skill produces. The schema must name this file back with
    # `skill:`, and `format-section:` must point at the section holding the
    # authored format; tools/validate.sh --check outputs asserts the two agree.
    # output-schema: sab.follow-up-work/1


# verified-against: optional — records sources for external claims.
# verified-against:
#   - url: https://...
#     date: YYYY-MM-DD
#     note: One sentence on what was verified

# allowed-tools: space-delimited list of pre-approved tools.
# Experimental — support varies by agent implementation.
# allowed-tools: Bash(git:*) Read Write
---
```

---

### Body content

The body is freeform Markdown. Write whatever helps the agent perform the task.
There are no required sections — use the patterns below that fit your skill.

The spec recommends keeping `SKILL.md` under 500 lines / 5,000 tokens. Move
anything the agent only needs sometimes into `references/` or `assets/` and
tell the agent explicitly when to load those files.

---

## Skill body patterns

The following are recommended patterns from the spec. Copy the ones relevant
to your skill into `SKILL.md` and delete this file's instructional scaffolding.

---

### Role and scope (recommended opener)

```markdown
You are a {{ROLE}} helping with {{TASK_SCOPE}}.

Your task when this skill activates: {{TASK_DESCRIPTION}}.

This skill is NOT for: {{OUT_OF_SCOPE}}.
```

---

### Step-by-step instructions

Clear numbered steps work better than prose for procedural tasks. Be
prescriptive where the order matters or operations are fragile; give the agent
freedom where multiple approaches are valid.

```markdown
## Steps

1. {{STEP_1}}
2. {{STEP_2}}
3. {{STEP_3}}

If {{CONDITION}}, do {{ALTERNATIVE}} instead.
```

---

### Output format template

Provide a concrete template rather than describing the format in prose.
Agents pattern-match against templates more reliably than prose descriptions.
Short templates live inline; longer ones go in `assets/` and are referenced
conditionally.

```markdown
## Output format

Use this structure:

# [Title]

## Summary

[One paragraph]

## Details

- Item with supporting data

## Next steps

1. Actionable recommendation
```

---

### Gotchas

The highest-value content in many skills. Concrete corrections to mistakes the
agent will make without being told — not general advice.

```markdown
## Gotchas

- {{SPECIFIC_WRONG_ASSUMPTION}}: {{CORRECTION}}.
- The `{{FIELD_A}}` in {{SYSTEM_A}} is called `{{FIELD_B}}` in {{SYSTEM_B}}.
  They refer to the same value.
- {{COMMAND_OR_API}} returns {{MISLEADING_RESULT}} even when
  {{ACTUAL_FAILURE_CONDITION}}. Use {{CORRECT_CHECK}} instead.
```

---

### Checklist for multi-step workflows

Helps the agent track progress and avoid skipping steps.

```markdown
## Workflow

Progress:

- [ ] Step 1: {{DESCRIPTION}} (run `{{SCRIPT_OR_COMMAND}}`)
- [ ] Step 2: {{DESCRIPTION}}
- [ ] Step 3: Validate (run `{{VALIDATION_SCRIPT}}`)
- [ ] Step 4: {{DESCRIPTION}} only if step 3 passes
```

---

### Validation loop

Instruct the agent to validate its own output before proceeding.

```markdown
## Validation

After completing the task:

1. Run `{{VALIDATION_COMMAND}}`
2. If it fails, review the error, fix the issue, and run again
3. Only proceed when validation passes

Read `references/{{REFERENCE_FILE}}` if you encounter
{{SPECIFIC_ERROR_CONDITION}}.
```

---

### Script references

When scripts are bundled in `scripts/`, reference them explicitly and tell the
agent the expected inputs, outputs, and when to use each one.

```markdown
## Scripts

- `scripts/{{SCRIPT_NAME}}` — {{WHAT_IT_DOES}}.
  Input: {{INPUT_DESCRIPTION}}
  Output: {{OUTPUT_DESCRIPTION}}
  Run when: {{TRIGGER_CONDITION}}
```

---

### Conditional reference loading

Tell the agent exactly when to load supplementary files so context is used
efficiently. Do not say "see references/ for details" — be specific about the
trigger condition.

```markdown
## References

- Read `references/{{FILE}}` if {{SPECIFIC_CONDITION}}.
- Read `references/{{OTHER_FILE}}` before {{SPECIFIC_STEP}}.
```

---

## Low-context variant guidance

If `context-budget` is `medium` or `high`, create a second skill directory
named `<skill-name>-minimal/` with a stripped-down `SKILL.md` that fits ~1k
tokens. Keep only: role, core task, output format. Drop examples, verbose
instructions, and non-essential constraints. Note in the description that this
is the low-context variant and link to the full version.

---

## Skills vs prompts: quick reference

|                        | Prompt (`prompts/`) | Skill (`skills/`)                                                    |
| ---------------------- | ------------------- | -------------------------------------------------------------------- |
| Format                 | Single `.md` file   | Directory with `SKILL.md`                                            |
| Injected as            | User message        | System prompt / agent context                                        |
| Scope                  | Single request      | Full session or task                                                 |
| Has scripts/references | No                  | Yes (`scripts/`, `references/`, `assets/`)                           |
| Spec                   | Internal convention | [agentskills.io/specification](https://agentskills.io/specification) |
| Validated by           | PR checklist        | `skills-ref validate` + PR checklist                                 |

---

## Checklist before committing

- [ ] Directory name matches `name` field exactly (lowercase-kebab, no
      leading/trailing/consecutive hyphens, max 64 chars)
- [ ] `description` describes both what the skill does and when to activate it,
      with concrete trigger phrases (max 1024 chars)
- [ ] `context-budget` metadata reflects the actual token cost of `SKILL.md`
      body alone (not including task input)
- [ ] `interfaces` metadata lists only interfaces that have been verified
- [ ] `review-by` date set if skill references external tools or APIs
- [ ] `verified-against` entries added for any externally-sourced claims
- [ ] `SKILL.md` body is under 500 lines / 5,000 tokens
- [ ] Anything only needed sometimes is in `references/` or `assets/` with
      explicit conditional load instructions in the body
- [ ] Scripts in `scripts/` are referenced in the body with input/output docs
      and a trigger condition
- [ ] Gotchas section captures known failure modes and non-obvious corrections
- [ ] Low-context variant (`<name>-minimal/`) exists if `context-budget` is
      `medium` or `high`
- [ ] Entry added to the parent `skills/README.md` index table
- [ ] Entry added to `CHANGELOG.md` under `[Unreleased]`
- [ ] Run `skills-ref validate ./<skill-name>` if the CLI is available
- [ ] Change proposal submitted and approved before this directory was created
