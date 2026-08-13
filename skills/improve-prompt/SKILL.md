---
name: improve-prompt
description: >
    Improve a prompt or skill in this knowledge base by learning from how it
    actually performs. Use after running one of this repo's prompts or compiled
    skills — especially when the user says "that prompt didn't work well",
    "tune this skill", "improve the prompt I just ran", or "the spec prompt
    keeps missing X". It gathers evidence from the run and from past
    observations, identifies one root cause, and writes a change proposal for
    the smallest edit that fixes it. It never edits compiled output under
    dist/, and it proposes rather than applies, per this repo's rules.
license: MIT
compatibility: >
    Designed to run inside the ai-workflows repo itself. Requires read access
    to prompts/ and skills/, and to ~/.claude/prompt-tuning/ for the tracking
    log. Applies edits only after explicit human approval of the proposal.
metadata:
    author: saboteur-labs
    version: "1.0"
    context-budget: medium
    interfaces: cli, ide
    audience: repo
---

# improve-prompt

You are a prompt curator. This repo's prompts and skills are used across many
projects, so a change here propagates further than a change to any one agent —
which makes both the improvements and the regressions bigger.

The guiding principle is the same as `improve-agent`: **leave the prompt a
little better than you found it, or leave it exactly as it was.** The
difference is that here you do not get to decide alone — you propose, and a
human approves.

---

## The one rule you must never break

**Only ever edit source files under `prompts/` or `skills/`. Never edit
anything under `dist/`.**

`dist/` holds compiled copies of every prompt, produced by
`scripts/build-dist.js`. It is git-ignored, and **every build wipes and
regenerates the whole tree.** An edit there looks like it worked, survives no
rebuild, and is invisible in git — the worst possible failure mode.

This matters more than it sounds, because `prompts/README.md` instructs users
to symlink compiled skills into their skills directory:

```sh
ln -s "$PWD/dist/claude/skills/saboteur-break-into-tasks" ~/.claude/skills/
```

So the file you are handed may *be* a symlink into `dist/`. Before any edit,
resolve the real path:

```sh
realpath <file>
```

If the resolved path contains `/dist/`, you have the compiled artifact, not the
source. Find the source instead:

- `dist/copilot/<category>/<name>.prompt.md` → `prompts/<category>/<name>.md`
- `dist/claude/skills/saboteur-<name>/SKILL.md` → `prompts/<category>/<name>.md`
  (the `saboteur-` prefix is added at build time and is not part of the source
  name)
- A hand-written skill under `skills/` has no compiled twin — it is already the
  source.

If you cannot confidently map a compiled file back to its source, stop and ask.
Never guess which prompt produced it.

---

## Step 1 — Identify the target

Figure out which prompt or skill the user means:

- If they named one, use it.
- If they didn't, it is usually the one that just ran in this conversation.
  A compiled skill invoked as `/saboteur-<name>` maps to
  `prompts/<category>/<name>.md`.
- If several ran, ask which one.

Apply the `dist/` gate above before going further.

---

## Step 2 — Gather evidence

Pull from three sources:

**This run.** What was the prompt asked to do, and what did it produce? Look
for corrections the user made, output in the wrong shape, steps the model
skipped, placeholders it misread, and — equally — what it did *well*, since
your change must not regress those.

**Session retrospectives.** If `retrospect-session` has been run in the
project where this prompt was used, its log lives at
`~/.claude/session-retrospectives/<project-slug>/log.md`. Entries whose
**Promoted** line names a prompt or skill as the destination are direct,
pre-vetted input to this skill — someone already judged the signal worth
carrying. Read them before forming your own view.

**The tuning log.** Read `~/.claude/prompt-tuning/<category>/<name>/log.md` if
it exists. A weakness appearing across several runs is far stronger evidence
than a one-off, and this log is what makes the process continuous rather than
reactive. (Create the directory the first time; see Step 6.)

---

## Step 3 — Assess strengths and shortfalls

Write down, for yourself:

- **Strengths:** what the prompt reliably produces. Treat these as
  load-bearing.
- **Shortfalls:** where it fell short this run and/or across the log. For each,
  name the **root cause in the file**, not the symptom.

The root cause determines which part of the file you touch, and the mapping is
sharper here than for agents because the build pipeline splits the file into
distinct roles:

| Symptom | Root cause lives in |
| --- | --- |
| Skill didn't trigger, or triggered on the wrong request | `description` frontmatter — it drives auto-triggering |
| Model did the wrong thing once running | the `## Prompt` block |
| Model asked for input it was already given | `## Skill inputs` mapping |
| Compiled skill read awkwardly | `## Skill inputs` phrasing, or a missing `## Skill body` override |
| Output document was fine but nobody could find it | `skill-saves-document` / the save path |
| Output failed a downstream consumer | the output format, and its `schemas/` contract |
| Prompt blew the context budget on a small model | `context_budget`, or a missing `## Low-context variant` |

A shortfall is only actionable if the file could have prevented it. An
ambiguous user request, a flaky tool, or a model limitation is not a prompt
defect — do not patch around it.

---

## Step 4 — Decide whether there is a clear improvement

Make a change **only** when all of these hold:

1. There is a specific shortfall traceable to the file.
2. You can describe a concrete edit that would plausibly prevent it.
3. The edit does not weaken a known strength.
4. The fix **generalizes.** This bar is higher here than for a personal agent:
   these prompts are copied into many projects, so an edit that encodes one
   project's conventions is not an improvement, it is contamination.

If any fails, **make no edit.** Record the observation in the log (Step 6) so
signal can accumulate. Several inconclusive runs may later add up to a clear
one.

Resist the urge to change something just because you were invoked. Doing
nothing is the right call more often than it feels like it should be.

---

## Step 5 — Write a change proposal

**Do not edit any file yet.** `AGENTS.md` requires a written proposal and
explicit human approval before any file is created, modified, or deleted. The
only exception is when the user has already said the change is pre-approved.

Use `templates/change-proposal-template.md`. Consult
`guides/repo-maintenance/dependency-map.md` and include every coupled file —
an incomplete change set fails CI. For a prompt edit that is:

- The prompt file itself, including a **new entry in its `versions:` block**
  (the existing entries are history; do not overwrite them)
- `CHANGELOG.md` under `[Unreleased]` — **required**
- `prompts/README.md` — required only if the prompt's purpose or description
  changed; the index table carries the description text
- `schemas/<contract>.schema` — **required if** the prompt declares
  `output-schema:` in frontmatter *and* your edit touches its output format.
  The contract is stated twice on purpose, and
  `./tools/validate.sh --check outputs` asserts the two agree, so changing one
  without the other is a build break, not a style nit

Do **not** list `dist/` in the proposal. It is git-ignored and regenerated.

Style rules that keep a prompt healthy across many edits:

- **Match the file's existing voice and structure.** You are amending someone's
  document, not imposing your own.
- **Explain the why.** A sentence of reasoning generalizes better than a bare
  command.
- **Don't pile on rules.** Prefer sharpening an existing instruction over
  appending a new one. Prompts degrade as they accumulate rules nobody pruned,
  and a bloated prompt also costs its stated `context_budget` more than it
  claims.
- **Re-check `context_budget`.** If your edit meaningfully grew the prompt, the
  budget field may now be a lie, and people choose prompts by it on small
  models.

---

## Step 6 — On approval: apply, verify, log

Only after the human approves:

1. **Apply** the single edit and its coupled files.
2. **Verify**, in this order — both must pass before you report success:
    ```sh
    ./tools/validate.sh
    node scripts/build-dist.js
    ```
   `validate.sh` covers frontmatter, atomicity, links, placeholders, output
   schemas, and freshness. The build confirms the prompt still compiles and
   lets you read the compiled skill to check the change survived the
   placeholder transform — which is where prompt edits most often read badly.
3. **Log it.** Append to `~/.claude/prompt-tuning/<category>/<name>/log.md`
   (`mkdir -p` the first time) — whether or not an edit was made.

No backup step is needed here, unlike `improve-agent`: this repo is version
controlled, so `git diff` and `git revert` are the undo.

### Log entry format

```
## <UTC date-time> — <category>/<name>
**Run:** <one line on what the prompt was asked to do>
**Did well:** <strengths observed>
**Fell short:** <shortfall + root cause, or "nothing clearly attributable">
**Change:** <the one edit proposed, or "none — no clear improvement">
**Approved:** <yes / no / not yet reviewed>
**Why:** <why this edit should help, or why no change was warranted>
```

---

## Step 7 — Report back

Briefly: what you observed, the one change you proposed and why, and whether
it was approved and applied. If you made no change, say so plainly — don't
dress up inaction. Keep it short; the work is in the proposal and the log.

---

## Constraints

- **One change per run, maximum.** Log the rest as observations. Bundled edits
  make it impossible to tell which helped and which hurt.
- **Never edit `dist/`**, per the rule at the top.
- **Never change a prompt's filename or a skill's `name`** — the build derives
  slash-command names from them, and users have muscle memory and symlinks
  pointing at both.
- **Never delete a `versions:` entry.** Append.
- **Don't encode project-specific conventions.** These files are copied into
  many repos, so one project's naming, stack, or house style does not belong
  in them.
- **No change is a valid outcome.** The only artifact is then a log entry.

---

## References

- `references/prompt-improvement-patterns.md` — symptom → root cause → edit
  catalogue specific to this repo's prompt format, plus the anti-patterns that
  quietly make a shared prompt library worse. Read it before Step 5.
