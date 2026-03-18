# Repo structure reference

Complete file tree and directory purpose reference. Loaded by the
`repo-maintenance` skill when verifying file paths or locating content.

---

## Top-level structure

```
ai-workflows/
├── AGENTS.md              ← AI agent rules of engagement (read first)
├── README.md              ← Human-facing repo overview
├── CONTRIBUTING.md        ← Contribution guide
├── CHANGELOG.md           ← Version history
│
├── guides/                ← Conceptual guides and best practices
├── prompts/               ← Copy-paste prompt library
├── skills/                ← Agent Skills (agentskills.io spec)
├── templates/             ← Authoring templates
├── examples/              ← Worked end-to-end workflow demos
├── tools/                 ← Shell scripts and utilities
└── .github/               ← CI workflows and GitHub templates
```

---

## guides/

```
guides/
├── README.md
├── context/
│   ├── README.md
│   ├── context-window-basics.md
│   ├── chunking-strategies.md
│   ├── low-memory-workarounds.md
│   └── context-budget-guide.md
├── workflows/
│   ├── README.md
│   ├── ide-plugin-workflow.md
│   ├── chat-interface-workflow.md
│   ├── cli-tool-workflow.md
│   └── api-scripted-workflow.md
├── models/
│   ├── README.md
│   ├── local-vs-remote.md
│   ├── model-selection-guide.md
│   └── lm-studio-setup.md
├── agent-patterns/
│   ├── README.md
│   ├── single-agent.md
│   ├── multi-agent-orchestration.md
│   └── human-in-the-loop.md
└── repo-maintenance/
    ├── README.md
    ├── how-this-repo-is-structured.md
    ├── dependency-map.md
    └── contributing-with-ai.md
```

**Naming:** `kebab-case.md`. One topic per file. Files are evergreen by
default; use `review-by` frontmatter for time-sensitive content.

**README tables:** Each subdirectory README contains a status table with
columns `File | Status | Description`. Status values: `✅ Done`, `🔲 Stub`.

---

## prompts/

```
prompts/
├── README.md              ← Index table of all prompts
├── code/
│   ├── generate-unit-tests.md
│   ├── code-review.md
│   ├── refactor-for-readability.md
│   ├── scaffold-module.md
│   └── explain-codebase.md
├── planning/
│   ├── write-feature-spec.md
│   ├── break-into-tasks.md
│   ├── write-adr.md
│   └── estimate-complexity.md
├── testing/
│   ├── generate-test-cases.md
│   ├── review-test-coverage.md
│   └── write-e2e-scenario.md
└── agent-orchestration/
    ├── decompose-task.md
    ├── summarize-for-handoff.md
    └── self-critique-loop.md
```

**Categories:** `code`, `planning`, `testing`, `agent-orchestration`.
New categories require explicit approval — do not create ad-hoc categories.

**Nested code fences:** Prompts that contain code blocks within the prompt
text use `~~~` for the outer fence and ` ``` ` for inner blocks.

---

## skills/

```
skills/
├── README.md              ← Index table of all skills
├── coding/
│   ├── implement-feature/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   │   ├── patterns.md    (per-project stub)
│   │   │   └── conventions.md (per-project stub)
│   │   └── assets/
│   │       └── implementation-summary-template.md
│   ├── implement-feature-minimal/
│   │   └── SKILL.md
│   ├── debug-issue/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── patterns.md    (per-project stub)
│   │       └── known-issues.md (per-project stub)
│   └── debug-issue-minimal/
│       └── SKILL.md
├── planning/
│   ├── spec-writer/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── domain.md      (per-project stub)
│   └── spec-writer-minimal/
│       └── SKILL.md
└── repo-maintenance/
    ├── SKILL.md
    ├── references/
    │   ├── repo-structure.md  (this file)
    │   └── style-guide.md
    └── freshness-check/
        ├── SKILL.md
        └── references/
            └── external-claims-registry.md
```

**Spec:** Skills conform to [agentskills.io/specification](https://agentskills.io/specification).
Directory name must match `name` field in `SKILL.md` frontmatter.

**Minimal variants:** Every `medium`-budget skill must have a `-minimal`
sibling directory. Minimal variants end in `-minimal` and declare
`context-budget: low`.

**Per-project stubs:** `references/` files marked "(per-project stub)"
are intentionally incomplete. They contain `🔲 Stub` markers and are
filled in when the skill is copied into a target project. Do not attempt
to fill them in this repo.

---

## templates/

```
templates/
├── prompt-template.md         ← Canonical prompt file template
├── skill-template.md          ← Canonical skill directory template
├── change-proposal-template.md ← Agent/human change proposal template
└── structures/
    ├── guide-template.md
    ├── example-step-template.md
    ├── directory-readme-template.md
    └── changelog-entry-template.md
```

**Protection:** Template files may not be modified without explicit human
approval. Changes to templates affect all future content of that type.

---

## examples/

```
examples/
├── README.md
├── spec-to-implementation/
│   ├── README.md
│   ├── 01-write-spec.md
│   ├── 02-break-into-tasks.md
│   ├── 03-scaffold-module.md
│   └── 04-generate-tests.md
└── low-context-chunked-review/
    ├── README.md
    ├── 01-chunk-file.md
    └── 02-review-chunks.md
```

**Naming:** Steps are numbered with zero-padded two-digit prefixes
(`01-`, `02-`, etc.). Each example directory has its own README.

---

## tools/

```
tools/
├── README.md
├── fetch-prompt.sh        ← Fetch/copy/install prompts and skills
├── chunk-file.sh          ← Split large files into chunks
└── lib/
    ├── chunk_file.py      ← Stub: token-accurate chunker (tiktoken)
    └── fetch_prompt.js    ← Stub: Node.js programmatic API
```

---

## .github/

```
.github/
├── ISSUE_TEMPLATE/
│   ├── new-prompt.md
│   └── new-skill.md
├── pull_request_template.md
└── workflows/
    ├── validate-frontmatter.yml       ← Blocks: missing/invalid frontmatter
    ├── validate-change-atomicity.yml  ← Blocks: incomplete change sets
    ├── validate-links.yml             ← Blocks: broken internal links
    ├── validate-placeholders.yml      ← Blocks: unfilled {{PLACEHOLDERS}}
    └── validate-freshness.yml         ← Warns: expired review-by dates
```
