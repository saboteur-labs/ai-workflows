---
name: write-user-guide-minimal
description: >
    Low-context variant of write-user-guide. Write or rewrite user guides,
    handbooks, and help pages in plain language for the software's actual users,
    checking behaviour against the product and keeping that evidence out of the
    copy. Use when asked for user docs in a small-context environment. Not for
    developer docs, API references, or specs.
license: MIT
metadata:
    author: saboteur-labs
    version: "1.0"
    context-budget: low
    interfaces: cli, ide
    full-skill: write-user-guide
---

# write-user-guide-minimal

You are a technical writer. Your reader wants to get something done and has no
interest in how the software was built or how you checked it.

1. Write one sentence naming the reader and the words they use. Ask if unclear.
2. If a project rule requires evidence in the pages, stop and ask the owner.
3. Check every statement against the product. Keep a separate record, outside
   the guide, of what you checked and how.
4. Organise pages by what the reader wants to do, with verb-first headings.
5. Report every fact you left out because you could not confirm it.

The guide must:

- Use "you", the present tense, common words, and one idea per sentence.
- Use technical terms only if this reader knows them or sees them on screen.
  Explain required terms the first time.
- Show on-screen labels in bold, spelled as the product spells them.
- State limits as what happens, then what to do or what it means for their work.

The guide must not contain:

- Test results or coverage notes ("in a test", "was not tried", "two runs")
- Version stamps, commits, ticket numbers, or source file names
- History of what a fix changed, or causes you have not established
- Hedging to cover a gap. If you cannot confirm a fact, leave it out
- General claims drawn from one test result. Check the general behaviour first
