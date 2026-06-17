# Agent improvement patterns

A catalogue of effective edits by symptom, and the anti-patterns to avoid. Use
this to turn an observed shortfall (Step 3) into the single smallest edit that
fixes its root cause (Step 5).

## Match symptom → root cause → edit

| Symptom you observed | Likely root cause | Smallest effective edit |
| --- | --- | --- |
| Agent didn't activate when it should have, or activated when it shouldn't | The `description` doesn't cover the user's phrasing, or is too broad | Add/trim trigger phrasing in the `description` frontmatter — add the missing intent, or carve out the near-miss case. Body untouched. |
| Agent did work outside its remit | A scope boundary is stated once and softly | Sharpen the existing boundary and add the *why* (what goes wrong when scope creeps), rather than adding a new rule elsewhere |
| Agent missed a recurring edge case | The case isn't mentioned anywhere | Add one concise edge-case note where the relevant step already lives |
| Agent asked the user for something it could have inferred | No guidance on inferring vs. asking | Add a line on what to infer from context and when asking is actually warranted |
| Output was the wrong shape/format | Format is implied, not specified | Pin the output format with a short template in the existing output section |
| Agent followed instructions rotely and missed intent | Instructions are commands without reasoning | Add a sentence of "why" so the agent can reason about the goal, not just the letter |
| Agent repeated a mistake the user already corrected once | The correction lives only in chat history, not the definition | Encode the corrected behaviour as a brief, general rule with its rationale |

## What a good edit looks like

- **Small.** A sentence, a clause, a sharpened phrase. If the diff is large, you're
  rewriting, not improving — stop and reconsider.
- **General.** It addresses the *class* of mistake, not the one input. Ask: "Would
  this help across many future runs, or only re-runs of today's exact prompt?"
- **Reasoned.** It carries a short "why" so the agent understands the goal.
- **In voice.** It reads like the rest of the agent — same tone, same structure.
- **Additive-safe.** It doesn't contradict or quietly weaken an existing strength.

## Anti-patterns — these quietly make agents worse

- **Overfitting.** Encoding the specific file names, values, or phrasing from this
  one run. It bloats the agent and rarely transfers. Generalize or skip it.
- **Bloat / rule-piling.** Adding a new MUST every time something goes slightly
  wrong. Agents degrade as they accumulate rules nobody pruned. Prefer sharpening
  an existing instruction over appending a new one; if you add, consider what to
  cut.
- **All-caps absolutism.** A wall of MUST/NEVER/ALWAYS reads as noise and crowds
  out judgement. Reserve hard absolutes for genuine safety invariants; explain
  everything else.
- **Regressing a strength.** "Fixing" over-eagerness by making the agent timid, or
  fixing scope creep by making it refuse legitimate adjacent work. Re-read the
  edit against the strengths list before saving.
- **Fixing what isn't the agent's fault.** A user typo, a flaky tool, or a
  genuinely ambiguous request isn't a definition defect. Patching around external
  noise adds rules that fire on the wrong cases.
- **Multiple changes at once.** Bundling several edits makes it impossible to tell
  which helped and which hurt. One change per run keeps the signal clean and the
  revert simple.

## When the right move is no change

If the shortfall isn't traceable to the definition, or any fix you can think of
would risk a strength or only help this exact prompt, make no edit. Record the
observation in the log so the pattern can accumulate. A weakness seen once is
noise; the same weakness across three runs is a clear, safe target later.
