# Step 01: Chunk the file

**Tool:** `tools/chunk-file.sh`
**Input:** A 450-line TypeScript service file
**Output:** Three chunk files, each within the local model's context budget
**Decision point:** Verify chunk sizes before sending to the model

---

## Start: estimate the token cost

Before chunking, check whether chunking is actually necessary:

```sh
./tools/chunk-file.sh --stats src/services/payment.ts
```

Example output:

```
File:   src/services/payment.ts
Lines:  450
Chars:  18,240
Tokens: ~4,560 (estimated)
Mode:   functions (auto-detected)
Chunks: ~3 at 1500 tokens each
```

**Budget calculation for this scenario:**

```
Model context window:         8,192 tokens
Response buffer:             -1,000 tokens
code-review prompt (low):    -1,200 tokens
Available for file content:   5,992 tokens
```

The file at ~4,560 tokens would technically fit in one pass, but with
only ~1,400 tokens of headroom the model would be operating near its
effective limit — reasoning quality degrades noticeably in the last 20%
of the context window. Chunking into ~1,500-token pieces gives the model
room to reason well over each section.

**Rule of thumb:** if task content exceeds 60% of your available budget,
chunk it even if it technically fits.

---

## Run the chunker

```sh
./tools/chunk-file.sh \
  --mode functions \
  --size 1500 \
  --overlap 100 \
  --output-dir /tmp/payment-review \
  src/services/payment.ts
```

Output:

```
File:   src/services/payment.ts
Tokens: ~4,560 (estimated)
Mode:   functions
Chunks: ~1500 tokens each, 100 overlap

  Wrote chunk 1/3: ~1,480 tokens → /tmp/payment-review/payment.part-001.ts
  Wrote chunk 2/3: ~1,510 tokens → /tmp/payment-review/payment.part-002.ts
  Wrote chunk 3/3: ~1,420 tokens → /tmp/payment-review/payment.part-003.ts

Done. 3 chunks written to: /tmp/payment-review/
```

---

## What `--mode functions` does here

The chunker splits at function and class declaration boundaries, so each
chunk contains one or more complete functions — never a partial one. The
`--overlap 100` flag repeats the last ~100 tokens of each chunk at the
start of the next one, giving the model context for what came immediately
before without repeating the entire previous chunk.

For a payment service, this typically produces chunks like:

- **Chunk 1:** imports, types, helper functions
- **Chunk 2:** core payment processing functions
- **Chunk 3:** error handling, retry logic, webhook handlers

---

## Verify the chunks before sending

Quickly check that each chunk looks reasonable — starts and ends at a
clean boundary:

```sh
# Check the start of each chunk
head -5 /tmp/payment-review/payment.part-001.ts
head -5 /tmp/payment-review/payment.part-002.ts
head -5 /tmp/payment-review/payment.part-003.ts

# Check no chunk is suspiciously small or large
wc -l /tmp/payment-review/payment.part-*.ts
```

If a chunk ends mid-function, it means a single function is larger than
the chunk size. In that case, increase `--size` until the function fits,
or switch to `--mode lines` as a fallback.

---

## Proceed to step 2

Once you've verified the chunks look clean, proceed to
[`02-review-chunks.md`](./02-review-chunks.md) to run the review.
