# Style guide

Voice, tone, and formatting conventions for all content in this repo.
Loaded by the `repo-maintenance` skill when drafting new content.

---

## Voice and tone

**Second person for skills, first person for prompts, plain for guides.**

- Skills address the model directly: "You are a senior engineer…",
  "Your task is to…", "Read the file before…"
- Prompts are instructions the human sends to a model: they use
  imperative mood ("Generate a test suite…", "Review the following…")
  or direct address ("I need unit tests for…")
- Guides address the reader (developer) in plain declarative prose.
  No "you should" hedging — state facts and recommendations directly.

**Specific over vague, always.**
"Reduces p99 latency by ~200ms" is better than "improves performance".
"Throws an `AppError` with `statusCode: 404`" is better than "handles
errors appropriately". Vague language is the most common quality problem
in AI-generated content — flag it and replace it.

**Concrete over abstract.**
Every claim should be accompanied by an example or a specific case where
it applies. Abstract principles without grounding read as filler.

**No hedging language in requirements.**
In prompts and skills: use `must`, `should`, `may` (RFC 2119) for
requirements. Do not use "try to", "attempt to", "if possible", or
"where appropriate" for things that are actually required.

---

## Formatting

**Sentence case everywhere.** Headings, table headers, list items, button
labels — all sentence case. Never Title Case or ALL CAPS except for
`{{PLACEHOLDER_NAMES}}` and `SCREAMING_SNAKE_CASE` constants in code.

**Two heading levels maximum in most files.** `##` for major sections,
`###` for subsections. Rarely use `####`. Never go deeper than `####`.

**No bold mid-sentence for emphasis.** Bold is for headings, table
headers, and definition terms only. For inline emphasis in prose, rewrite
the sentence so the important word is naturally prominent.

**Lists for discrete items, prose for connected ideas.** If list items
need connective tissue ("first… then… because of this…"), they belong in
prose. If they're genuinely parallel and independent, a list is fine.

**Code fences for all code, commands, and file paths longer than one
component.** Inline backticks for short references: `userId`, `SKILL.md`,
`--mode functions`. Fenced blocks for everything else.

**Nested code fences:** when a prompt file contains code blocks inside
the prompt text, use `~~~` for the outer fence and triple backticks for
inner language-tagged blocks. This prevents markdown parser failures.

---

## Frontmatter

All prompts and skills must have complete frontmatter matching their
respective templates. Partial frontmatter is not acceptable — every
field must be present even if the value is a default.

**`context_budget` / `context-budget`** must reflect the actual token
cost of the file's instructions, not a guess. When in doubt, estimate
conservatively (round up to the next tier).

**`review-by`** (optional but recommended) format: `YYYY-MM-DD`.
Set 6–12 months from the date of writing for time-sensitive content.
Set 18–24 months for content that changes slowly.

**`verified-against`** (optional) format:

```yaml
verified-against:
    - url: https://example.com/spec
      date: YYYY-MM-DD
      note: One sentence on what was verified
```

---

## Cross-linking

Every new file should link to related files where relevant. The standard
linking section at the bottom of guides and prompts uses this format:

```markdown
## Further reading

- [`path/to/file.md`](./path/to/file.md) — one sentence description
```

**All links are relative.** Never use absolute URLs for internal links.
Relative links survive repo renames and forks; absolute links do not.

**Verify links resolve before proposing.** Every internal link in a
proposed file must point to a file that actually exists in the repo.

---

## Language patterns to avoid

These are common AI-generated content patterns that reduce quality.
Flag them and rewrite when reviewing:

| Avoid                                | Replace with                                |
| ------------------------------------ | ------------------------------------------- |
| "It is important to note that…"      | State the thing directly                    |
| "This allows you to…"                | Describe what it does, not what it "allows" |
| "Feel free to…"                      | Remove — it's filler                        |
| "Simply…" / "Just…"                  | Remove — condescending and often wrong      |
| "In order to…"                       | "To…"                                       |
| "Make sure to…"                      | Use imperative: "Check that…", "Verify…"    |
| "Utilize"                            | "Use"                                       |
| "Leverage"                           | "Use"                                       |
| "Best practices" (without specifics) | Name the specific practice                  |
| "As mentioned above"                 | Re-state the thing or link to it            |
| "etc." at the end of a list          | Complete the list or cut it                 |
