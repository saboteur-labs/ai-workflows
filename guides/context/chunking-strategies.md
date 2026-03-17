# Chunking strategies

How to split different types of content into pieces that fit within a model's
practical context window. Chunking is the primary technique for working with
large inputs on any model — local or hosted — when the content exceeds what
can be reasoned over effectively in a single request.

Read [`context-window-basics.md`](./context-window-basics.md) first if you
haven't — understanding why chunking is necessary makes the strategies here
easier to apply correctly.

---

## The core principle

A chunk should be **independently useful**. The model processing chunk 3
should not need to have read chunk 2 to do its job. When that's not possible,
use overlap to carry forward just enough context to maintain coherence.

This principle determines everything else: where to split, how large to make
chunks, and how much to overlap.

---

## When to chunk vs when to summarise

Chunking and summarisation solve different problems. Choosing the wrong one
wastes effort.

| Situation                                    | Use chunking                       | Use summarisation            |
| -------------------------------------------- | ---------------------------------- | ---------------------------- |
| Reviewing or analysing content               | Yes — need full detail per section | No — lossy                   |
| Building context for a task                  | No                                 | Yes — compress prior context |
| Generating output from content               | Yes — process each section         | No                           |
| Passing prior session state to a new session | No                                 | Yes                          |
| Content has natural independent units        | Yes                                | Either                       |
| Content is densely interdependent            | Chunk with high overlap            | Consider summarising instead |

If the content is so interdependent that every chunk needs the full document to
make sense, chunking will produce poor results. In that case: summarise the
document first to extract the key facts, then use the summary as context for
your task.

---

## Chunking by content type

### Code files

**Preferred boundary:** function or class declaration.

Split at the start of each function, class, or module-level declaration. Never
split a function body across chunks — a partial function is uninterpretable.

**Overlap strategy:** include the last function signature or class header from
the previous chunk as the first line of the next. This gives the model the
calling context without repeating the entire body.

**Practical rules:**

- One class per chunk is a good default for object-oriented code
- For files with many small functions, group related functions (same domain
  concern) into one chunk rather than splitting at every boundary
- Always include import statements in every chunk — the model needs them to
  understand types and dependencies
- For TypeScript/typed languages, include type definitions that the chunk's
  code depends on, even if they're defined earlier in the file

**Tool:** `tools/chunk-file.sh --mode functions <file>`

---

### Documentation and specifications

**Preferred boundary:** section heading (`#`, `##`, `###`).

Markdown documents are naturally chunked by their heading structure. Split at
heading boundaries, keeping each heading and its body together.

**Overlap strategy:** include the parent heading (if any) at the top of each
chunk. This preserves the document hierarchy so the model knows where in the
document it is.

**Practical rules:**

- A single top-level section (`##`) and all its subsections is a good chunk
  size for most documents
- For very long sections, split at `###` boundaries instead
- Never split a table, code block, or numbered list across chunks — these are
  atomic units
- For specs that reference earlier sections ("as defined in section 2"), add a
  brief inline note in the chunk: `[Note: term X is defined in an earlier
section as: ...]`

**Tool:** `tools/chunk-file.sh --mode sections <file>`

---

### Data files (CSV, JSON, JSONL, logs)

**Preferred boundary:** record boundary — never split a record across chunks.

For CSV: split at row boundaries. Include the header row in every chunk.

For JSON arrays: split the array into sub-arrays, each a valid JSON document.

For JSONL (newline-delimited JSON): split at line boundaries — each line is
already a complete record.

For log files: split at logical event boundaries (timestamp changes, request
IDs, error blocks).

**Overlap strategy:** generally not needed for data files — records are
independent. Exception: if processing sequential log events where earlier
events establish context for later ones, include the last 2–3 records of the
previous chunk.

**Practical rules:**

- Always include column headers or schema in every chunk
- For JSON with nested objects, keep related nested objects together — do not
  split an object's properties across chunks
- For large JSON objects (not arrays), chunk by top-level key groupings

**Tool:** `tools/chunk-file.sh --mode lines <file>` (with header preservation
handled manually or via `lib/chunk_file.py` once implemented)

---

### Mixed content (e.g. a large PR diff, a repo export)

**Preferred boundary:** file boundary within the diff/archive.

For diffs: split at `diff --git` boundaries. Each chunk is one or more
complete file diffs.

For repo exports or directory listings: split by directory or logical module
boundary.

**Overlap strategy:** include a one-line summary of the previous chunk's
files at the top of each new chunk: `[Previous chunk covered: src/auth/,
src/middleware/]`

---

## Overlap: how much is enough

Overlap carries context from one chunk into the next. Too little and the model
loses the thread; too much and you waste context window on redundant content.

| Content type                   | Recommended overlap                                  |
| ------------------------------ | ---------------------------------------------------- |
| Code (function-boundary split) | Last function signature only (~5–10 lines)           |
| Code (line-boundary split)     | ~10% of chunk size                                   |
| Documentation                  | Parent heading + first paragraph of previous section |
| Data files                     | 2–3 records (or none, if records are independent)    |
| Logs                           | Last complete event from previous chunk              |

The default in `chunk-file.sh` is 100 tokens of overlap, which is appropriate
for most code and documentation. Increase to 200–300 tokens for content with
high cross-references; decrease to 0 for independent records.

---

## Reassembly: combining chunk outputs

After processing all chunks, you typically need to combine the results into a
single coherent output. The right approach depends on what you asked each chunk
to produce.

**For reviews and analysis:** collect one output per chunk, then use
[`prompts/agent-orchestration/summarize-for-handoff.md`](../../prompts/agent-orchestration/summarize-for-handoff.md)
to consolidate. Pass all chunk outputs to the consolidation prompt.

**For generated code or text:** chunk outputs are usually not directly
concatenatable — there will be duplication, inconsistencies, or missing
connective tissue. Treat them as drafts and do a final synthesis pass:

```
I processed a large file in chunks and got the following outputs.
Synthesise them into a single coherent [review / refactor / document].
Remove duplicates. Resolve any contradictions in favour of the later chunk.

Chunk 1 output:
[...]

Chunk 2 output:
[...]
```

**For test generation:** chunk outputs can often be concatenated directly,
since test functions are independent. Check for and remove duplicate test
names after concatenating.

---

## Shell pattern: process all chunks with a prompt

```sh
# 1. Chunk the file
./tools/chunk-file.sh --mode functions src/utils.ts --output-dir /tmp/chunks

# 2. Process each chunk
for chunk in /tmp/chunks/utils.part-*.ts; do
  echo "=== $chunk ===" >> /tmp/reviews.md
  # Replace {{CODE}} in the prompt with the chunk contents
  # (adjust to your model CLI's actual interface)
  cat prompts/code/code-review.md \
    | sed "s|{{LANGUAGE}}|TypeScript|g" \
    | sed "s|{{CODE}}|$(cat "$chunk")|g" \
    | your-model-cli >> /tmp/reviews.md
done

# 3. Consolidate
cat prompts/agent-orchestration/summarize-for-handoff.md \
  | sed "s|{{SESSION_CONTEXT}}|$(cat /tmp/reviews.md)|g" \
  | your-model-cli
```

---

## Common mistakes

**Splitting at an arbitrary line count without checking boundaries**
A 500-line chunk that ends mid-function is worse than a 700-line chunk that
ends at a clean boundary. Always prefer semantic boundaries over even sizes.

**Not including imports or headers in every chunk**
A code chunk without its imports is missing type information the model needs.
A CSV chunk without its header row is ambiguous. Always repeat the essential
preamble in every chunk.

**Overlap that's too small for highly-interdependent content**
If the model's output for chunk 3 seems unaware of context established in
chunk 2, increase overlap. The symptom is output that contradicts or ignores
earlier content.

**Consolidating too aggressively**
If the consolidation prompt receives 10 chunk outputs at once, it may hit its
own context limit. For large files producing verbose per-chunk output, do a
two-level consolidation: first consolidate pairs of chunks, then consolidate
the pair results.

---

## Further reading

- [`context-window-basics.md`](./context-window-basics.md) — why chunking is
  necessary and how context limits work
- [`low-memory-workarounds.md`](./low-memory-workarounds.md) — chunking in
  the context of small local models
- [`context-budget-guide.md`](./context-budget-guide.md) — deciding whether
  to chunk or use a different prompt/skill tier
- [`../../tools/README.md`](../../tools/README.md) — `chunk-file.sh` usage
  and options
- [`../../prompts/agent-orchestration/summarize-for-handoff.md`](../../prompts/agent-orchestration/summarize-for-handoff.md)
  — consolidating chunk outputs
