# Step 02: Review each chunk and consolidate

**Prompts used:**

- `prompts/code/code-review.md` — run once per chunk
- `prompts/agent-orchestration/summarize-for-handoff.md` — run once to consolidate

**Input:** Three chunk files from step 1
**Output:** A single consolidated review document
**Human review gate:** Triage the consolidated findings before acting

---

## Review each chunk

Run the code review prompt once per chunk. Each review is a fresh session
— no history from the previous chunk carries over, which is exactly what
you want: each session gets the full context budget for its chunk.

### Manual approach (any model CLI)

```sh
# Fetch the low-context review prompt once
./tools/fetch-prompt.sh code/code-review > /tmp/review-prompt.md

# Review each chunk, appending output to a results file
for chunk in /tmp/payment-review/payment.part-*.ts; do
  echo "\n\n---\n## Review: $chunk\n---" >> /tmp/chunk-reviews.md
  cat /tmp/review-prompt.md \
    | sed "s/{{LANGUAGE}}/TypeScript/g" \
    | sed "s/{{CODE_TYPE}}/file/g" \
    | sed "s|{{CODE}}|$(cat "$chunk")|g" \
    | sed "s/{{ADDITIONAL_FOCUS}}//g" \
    | your-model-cli >> /tmp/chunk-reviews.md
done
```

### What each chunk review looks like

Each chunk produces output in the structure defined by the `code-review`
prompt. A typical per-chunk output for this scenario:

---

**Review: payment.part-001.ts**

**[Correctness] [error-handling]** Lines 23–31: `processRefund` does not
handle the case where `originalTransaction` is null. If the transaction
ID doesn't exist, `originalTransaction.amount` will throw a TypeError.
Suggested fix: add a null check and return an appropriate error before
accessing properties.

**[Security] [validation]** Line 45: `amount` is passed directly to the
payment gateway without validating it is a positive number. A negative
amount may trigger a charge reversal at the gateway. Suggested fix:
validate `amount > 0` before calling `gateway.charge()`.

**Summary**

- Total findings: 2 (critical: 0, moderate: 2, minor: 0)
- Most important: The null check omission in `processRefund` — will throw
  in production if called with an invalid transaction ID
- Looks good: Error types are well-defined and consistently used

---

After all three chunks are reviewed, `/tmp/chunk-reviews.md` contains
three separate review outputs.

---

## Consolidate the reviews

The three chunk reviews may contain overlapping findings (the same
anti-pattern appearing in multiple chunks) and findings at different
severity levels. Use `summarize-for-handoff.md` to produce a single
consolidated review:

```sh
./tools/fetch-prompt.sh agent-orchestration/summarize-for-handoff \
  | sed "s|{{SESSION_CONTEXT}}|$(cat /tmp/chunk-reviews.md)|g" \
  | sed "s/{{NEXT_TASK}}/Triage the findings and decide which to fix/g" \
  | your-model-cli > /tmp/consolidated-review.md
```

### Example consolidated output

---

## Handoff summary

**Task completed:** Code review of `src/services/payment.ts` across 3 chunks

**Status:** Complete

### What was produced

Three per-chunk code reviews covering all 450 lines of the payment service.

### Decisions and assumptions made

- Chunk 2 and Chunk 3 both flagged missing input validation on `amount` —
  treated as one finding in this summary
- One finding (inconsistent error logging format) appeared in all three
  chunks — treated as a single systemic issue

### Current state

Reviews complete. No fixes applied. Findings ready for triage.

### What the next session should do

Review the findings below and decide which to fix. Pass the accepted
findings to a `skills/coding/debug-issue/` or
`skills/coding/implement-feature/` session with the relevant chunk as
context.

### Consolidated findings

**Critical / high priority**

- None identified

**Moderate priority**

1. Missing null check in `processRefund` before accessing
   `originalTransaction.amount` (chunk 1, line 23–31)
2. `amount` not validated as a positive number before gateway call —
   appears in `processRefund`, `processCharge`, and `processSubscription`
   (chunks 1–2, systemic)
3. Webhook signature verification is disabled when
   `NODE_ENV !== 'production'` — this disables a security control in
   all non-prod environments including staging (chunk 3, line 312)

**Minor**

1. Inconsistent error logging: some errors use `logger.error(err)`,
   others use `logger.error(err.message)` — loses stack trace in the
   latter case (systemic, all chunks)
2. `retryCount` variable is initialised but never reset between payment
   attempts within a session — may cause unexpected retry limit behaviour
   for long-lived service instances (chunk 3, line 387)

### Context to carry forward

The payment service uses a custom `PaymentError` class from
`../lib/errors`. Any fix to error handling should use this class.
The gateway client is in `../lib/gateway` and its `charge()` and
`refund()` methods both throw `GatewayError` on failure.

---

## Human review gate: triage the findings

Read the consolidated review and decide for each finding:

- [ ] **Fix now** — add to a follow-up `implement-feature` or
      `debug-issue` session
- [ ] **Defer** — log as a known issue in
      `skills/coding/debug-issue/references/known-issues.md`
- [ ] **Dismiss** — false positive or acceptable trade-off; note why

**In this example:**

- Finding 2 (amount validation) and finding 3 (webhook verification in
  non-prod) are the highest-priority fixes — both have security
  implications
- Finding 1 (null check) is a moderate correctness bug worth fixing before
  merge
- The logging inconsistency (minor finding 1) is worth a quick fix but
  not blocking
- The retry count bug (minor finding 2) warrants investigation — it may
  be intentional behaviour; check before fixing

For each "fix now" finding, open a new session with the relevant chunk
file and the finding as the task input to `skills/coding/debug-issue/`.
