# Prompt improvement patterns

A catalogue of effective edits by symptom, and the anti-patterns to avoid. Use
this to turn an observed shortfall (Step 3) into the single smallest edit that
fixes its root cause (Step 5).

This repo's prompt format splits one file into several roles — frontmatter that
drives skill triggering, a `## Prompt` block that drives behaviour, a
`## Skill inputs` map that drives the compiled skill's phrasing. Most bad
prompt edits are edits made to the wrong role, so start by locating the role.

## Match symptom → root cause → edit

| Symptom you observed | Likely root cause | Smallest effective edit |
| --- | --- | --- |
| Compiled skill never auto-triggered | `description` doesn't lead with the use case, or omits the phrasing the user actually used | Add the missing intent to `description`. Body untouched |
| Skill triggered on requests it shouldn't handle | `description` is too broad | Carve out the near-miss case in `description` — don't add a body rule to undo a triggering problem |
| Model asked for input the user had already supplied | The `{{VAR}}` has no entry in `## Skill inputs`, so it compiled to a generic humanized name | Add the mapping, written as a plain noun |
| Compiled skill reads awkwardly at an optional block | `## Skill inputs` phrasing duplicates the transform's own lead-in (e.g. a mapping ending in ", if one exists" under an "If the user provided…" line) | Reword the mapping to a plain noun. Reach for a `## Skill body` override only if it still reads badly — the override is a second copy that can drift |
| Output shape varied between runs | The format is described in prose rather than pinned | Add a short template in the section that already describes the output |
| A downstream prompt couldn't consume the output | The authored output format and the `schemas/` contract disagree | Fix both together; `./tools/validate.sh --check outputs` is what proves they agree |
| Unusable on a small local model | `context_budget` is understated, or there's no low-context variant | Correct the budget field, or add the `## Low-context variant` section |
| Model followed the letter and missed the intent | Instructions are commands without reasoning | Add one sentence of "why" next to the instruction |
| Model repeated a mistake the user already corrected | The correction lives in chat history, not in the file | Encode the corrected behaviour as a brief, general rule with its rationale |
| Document was produced but nobody could find it later | `skill-saves-document` is unset, or the save path is unstated | Set the flag, or state the conventional path |

## What a good edit looks like

- **Small.** A sentence, a clause, a sharpened phrase. If the diff is large,
  you're rewriting, not improving — stop and reconsider.
- **In the right role.** Triggering problems are `description` problems.
  Behaviour problems are `## Prompt` problems. Phrasing problems in the
  compiled output are `## Skill inputs` problems.
- **General.** It addresses the class of mistake, not the one input.
- **Reasoned.** It carries a short "why".
- **In voice.** It reads like the rest of the file.
- **Budget-honest.** After the edit, `context_budget` still describes reality.

## Anti-patterns — these quietly make a shared prompt library worse

- **Editing `dist/`.** The compiled tree is git-ignored and wiped on every
  build. The edit appears to work and then vanishes. This is the one
  unrecoverable mistake in this skill.
- **Project contamination.** Encoding one project's stack, naming, or house
  style into a prompt that other projects copy. A personal agent may be
  overfitted to its owner; a shared prompt may not.
- **Overfitting to one run.** Encoding the file names, values, or phrasing from
  the single session that prompted the change.
- **Rule-piling.** Adding a new instruction every time something goes slightly
  wrong. Prefer sharpening an existing one. Growth without pruning also
  silently invalidates the `context_budget` that people select prompts by.
- **All-caps absolutism.** Walls of MUST/NEVER/ALWAYS read as noise and crowd
  out judgement. Reserve absolutes for genuine invariants.
- **Regressing a strength.** "Fixing" a prompt that over-produces by making it
  terse, or fixing scope creep by making it refuse legitimate adjacent work.
  Re-read the edit against the strengths list before proposing it.
- **Breaking the schema pair.** Changing an output format without changing its
  contract in `schemas/`, or the reverse. The duplication is deliberate — it is
  the drift check.
- **Fixing what isn't the prompt's fault.** An ambiguous request, a flaky tool,
  or a model limitation is not a prompt defect.
- **Multiple changes at once.** Bundling makes it impossible to attribute the
  win or the regression.

## When the right move is no change

If the shortfall isn't traceable to the file, or any fix you can think of would
risk a strength or only help this exact input, make no edit. Record the
observation in the log so the pattern can accumulate. A weakness seen once is
noise; the same weakness across three runs is a clear, safe target later.
