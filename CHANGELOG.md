# Changelog

All notable changes to this repo are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

When contributing, add your entry under `[Unreleased]`. When you are ready
to tag a version, move the `[Unreleased]` entries to a new dated version
section (e.g. `## [1.1.0] — YYYY-MM-DD`), add the comparison URL at the
bottom, and open a new empty `[Unreleased]` block above it.

---

## [Unreleased]

### Added

- `CHANGELOG-repo-tools.md` — a second changelog for the skills that maintain
  this repo, split out from the user-facing one. A reader who copied
  `implement-feature` into their project does not need to know that
  `repo-maintenance` was retuned. Routing is by a declared
  `metadata.audience: repo` field rather than by directory, because the two do
  not correlate: `improve-agent/` sits at the same depth as the repo tools but
  tunes the user's own agents, so it stays in this file
- `tools/lib/check-outputs.js` emits `execution_waves` and `file_conflicts` for
  task lists. `execution_order` is only one legal serialisation of the
  dependency graph and discards the fact that any parallelism was available;
  the waves preserve it. `file_conflicts` then covers what waves alone cannot —
  two tasks can be dependency-independent and still edit the same file, which a
  parallel runner discovers as a merge conflict it cannot resolve
- `skills/improve-prompt/` — tunes a prompt or skill in this repo from evidence
  of how it actually performed, consuming the retrospective log as its input
  queue. Applies the propose-before-act rule rather than editing directly, and
  guards the `dist/` trap: compiled prompts are git-ignored and wiped on every
  build, and `prompts/README.md` invites users to symlink them, so the file
  handed to a tuner is often the compiled twin rather than the source
- `prompts/agent-orchestration/retrospect-session.md` — converts a finished
  session's corrections and missing context into a small set of checkable
  candidate rules, each routed to the artifact that should carry it (project
  instructions, a prompt, a skill, or an agent definition). Closes the capture
  half of the loop whose apply half is `skills/improve-agent/`, and follows
  that skill's append-only log convention so a signal recurring across
  sessions is detected rather than remembered
- `schemas/sab.follow-up-work.v1.schema` — the contract for the follow-up-work
  file `implement-feature` writes. Deferred work is read by the next session
  and by an orchestrator choosing the next wave, which is what earns it a
  schema rather than leaving it as prose. `sequential: Item.id` is what makes
  an append-only log safe to extend across sessions: a second agent appending
  `FU-4` over an existing `FU-4` fails the check instead of silently shadowing
  the earlier entry
- `schemas/` — machine contracts for the four prompts whose output is consumed
  by an agent rather than only read by a human (`sab.product-spec/1`,
  `sab.feature-spec/1`, `sab.features/1`, `sab.tasks/1`). Each declares the
  document's required structure, ID scheme, dependency-graph invariants, and
  conventional save path; `schemas/README.md` documents the DSL
- `tools/lib/check-outputs.js` — schema engine with three jobs: assert each
  schema still agrees with the output format authored in its prompt, validate a
  produced document against its schema (including cross-document requirement
  coverage via `--against`), and emit the parsed document as JSON for agents to
  consume, with a dependency-respecting `execution_order`
- `tools/lib/check_outputs.sh` and `.github/workflows/validate-outputs.yml` —
  the drift check as a blocking local and CI check, wired into
  `tools/validate.sh --check outputs`
- `prompts/code/audit-unused-code.md` — identifies unused imports, exports,
  functions, types, dead code paths, and unused dependencies across a
  codebase; produces a prioritised removal list for human or agent-driven
  cleanup
- `prompts/planning/ideate-project.md` — interactive ideation prompt that
  turns a bare-bones idea into a structured concept document; includes
  competitive landscape, caveats, and iteration support via Mode B
- `prompts/planning/write-product-spec.md` — expands a concept document from
  `ideate-project.md` into a milestone-organized product spec with testable
  requirements, user personas, and constraints derived from the concept's
  caveats
- `prompts/code/audit-codebase-structure.md` — analyses file and folder
  structure for empty directories, dead modules, misplaced files, excess
  depth, test organisation issues, and naming inconsistencies; produces a
  prioritised change list suitable for direct input to a restructuring session
- `prompts/code/extract-reusable-react-components.md` — scans React component
  files for duplicated JSX structure, repeated layout wrappers, shared
  conditional rendering patterns, and tightly coupled fragments; produces a
  prioritised extraction list with suggested component names and props
- `prompts/planning/surface-architecture-decisions.md` — multi-phase
  facilitation prompt that discovers explicit and implicit architectural
  decisions in a codebase, confirms intent with the user, gathers context,
  and hands off to `write-adr` with all required fields pre-filled
- `scripts/build-dist.js` — compiles all prompts into IDE-ready distribution
  formats under `dist/`: Copilot (`.github/prompts/`) and Claude Code
  (`.claude/commands/`); skips files missing `title` frontmatter or a
  `## Prompt` block

### Changed

- `skills/coding/implement-feature/` gives every open follow-up item a
  disposition, not only the ones this implementation resolved. An item can also
  lapse — the feature was cut, the approach changed, the code it described is
  gone — and previously there was nothing to do with one, so it stayed open
  forever. Everything left unticked is a claim that someone should still do it,
  and a list that fails that claim stops being read
- `prompts/agent-orchestration/retrospect-session.md` (v1.2.0) — the routing
  table gains two destinations it was missing, both found by failing to route a
  real rule. `enforcement: a hook or a check` goes first, because a rule with a
  detectable trigger and a checkable condition should be executed rather than
  read: an instruction competes for attention with everything else in the file,
  a check does not. `user-level instructions` covers a rule that holds in every
  repository, which previously had to be misfiled into one project's
  instructions or dropped. Both are exempt from the tunable-artifact
  constraint, since neither is a file in the project being retrospected. The
  Notes section also warns that an enforcement rule needs testing against the
  shapes it will really meet — a matcher written from remembered examples
  misses the fourth and fires on something harmless
- `AGENTS.md` — a "Landing a change" section: do not base a PR on another open
  PR, and confirm a merged PR's content actually reached the base branch before
  deleting its branch. A stacked PR whose base merges into the default branch
  first lands nowhere — green checks, approved review, content silently absent
- `guides/repo-maintenance/dependency-map.md` now matches what
  `check_atomicity.sh` blocks on, rather than what the couplings were intended
  to be. `prompts/README.md` on any prompt change, `skills/README.md` on any
  `SKILL.md` change, and a guide's parent `README.md` were all documented as
  recommended or not at all while CI treated them as blocking, so the map sent
  contributors into failing builds three times in one session. The examples row
  named the wrong README. Also records a real gap: both skill couplings match
  `skills/<category>/<name>/` only, so the five skills that sit a level higher
  are enforced by nothing
- `prompts/agent-orchestration/retrospect-session.md` (v1.1.0) — the
  description now names the phrases that should trigger it and the neighbours
  it is confused with, rather than describing only when it applies; a
  description is what a model reads to decide whether to load the prompt at
  all. It also prints the log entry as it appends it: that log is the one
  thing the prompt writes without asking, so it was the one part the user
  could not check
- `prompts/agent-orchestration/retrospect-session.md` — the recurrence check
  reads every project's log rather than only the current project's. Writes
  stay per-project. Most of what slows a session down is not repo-specific,
  so a project-scoped check saw one cause fire in three repositories and
  discarded it three times as three unrelated one-offs — the second firing is
  what promotes a signal, and it was invisible across a repo boundary. Where a
  signal appears now also carries information: confined to one log it wants
  that project's instructions, spread across several it wants a broader home
- `tools/lib/check-outputs.js` accepts a schema sourced from a skill, not only
  from a prompt. A skill has no `## Prompt` block to check the schema against,
  so its schema names the section holding the authored format with
  `format-section:`, and the reciprocal `output-schema:` sits under the skill's
  `metadata:` key — where the Agent Skills spec puts frontmatter it does not
  define. The both-sides-declared invariant is unchanged, and now runs in the
  skill direction too: a `SKILL.md` claiming a schema no file provides is
  reported the same way a prompt's is
- `tools/README.md` documents the `outputs` check, which was missing from the
  check table, the `validate.sh` flag list, and the `lib/` inventory
- `skills/coding/implement-feature/` records deferred work to a file rather
  than only to the session's implementation summary, which does not outlive
  the session that wrote it. The location resolves from the project's
  `references/conventions.md` first and otherwise defaults to
  `specs/features/{slug}/follow-up-work.md`, beside the task list the work
  came from; where neither resolves the skill asks, rather than inferring a
  location from whichever folder looks relevant. The skill also reads that
  file before starting, so an open item blocking the new work surfaces before
  any code is written, and ticks the `Done` checkbox on the tasks it completes
- `skills/coding/implement-feature/` writes tests before the code they cover
  and checks for existing coverage first. The previous instruction to write
  tests "alongside" the implementation left the ordering unstated, which is
  the part that decides whether a test can fail for the right reason
- `prompts/planning/write-feature-spec.md` and
  `prompts/planning/write-product-spec.md` now emit stable `FR-N`, `US-N`, and
  `OQ-N` identifiers, and require each requirement to reference the user story
  it serves. This is the shared vocabulary that lets a feature breakdown be
  checked against the spec it decomposes
- The four spec/task prompts declare `output-schema:` in frontmatter; their
  output contracts moved out of the prompt bodies into `schemas/`
- `scripts/build-dist.js` gives document-producing skills a definite save path
  taken from their schema's `output-path`, replacing a footer that invited the
  model to infer a location from whichever folder looked relevant. Prompts with
  no schema are now told to ask rather than guess
- `prompts/planning/break-into-tasks.md` — the `{{GRANULARITY}}` placeholder no
  longer sits inside the output template, where compilation substituted the
  input's description into every task's Estimate field
- `prompts/planning/write-adr.md` (v1.1.0) — added interactive file-output
  step: after generating the ADR, prompts the user to write it to a file;
  auto-detects the ADR directory and proposes the next sequential filename;
  added cross-reference to `surface-architecture-decisions.md`

### Fixed

- `templates/skill-template.md` documents the three `metadata` keys already in
  use that it never listed — `audience`, `full-skill`, and `output-schema`. The
  template is the frontmatter spec for skills, so a key it omits is one the
  next author can only find by reading a checker or copying an existing file.
  Its "prefix custom keys" guidance is also gone: five of the eight keys in use
  ignored it, nothing outside this repo's own tooling reads the block, and a
  rule followed by nobody is worse than no rule
- `tools/lib/check_atomicity.sh` enforced the `skills/README.md` coupling only
  for skills nested under a category, so the five sitting directly under
  `skills/` could drift out of the index with CI silent. The pattern now
  matches at any depth. Leaving them out was a deliberate scope once — the
  index tracked what consumers copy — but the answer is to route repo-internal
  skills to their own changelog, not to leave them unchecked
- `scripts/build-dist.js` — `extractSection` ended a section at the first
  `## ` line even inside a fenced block, so a prompt whose section ends with a
  template containing a heading compiled to a skill that stopped at the
  opening fence. `retrospect-session` shipped this way: its log-entry template
  begins `## <UTC date-time>`, and the compiled skill lost all seven lines of
  it and carried an unterminated fence. Only headings in prose close a section
  now
- The freshness-check skill was referenced as living under
  `skills/repo-maintenance/` in five places across `AGENTS.md`,
  `guides/repo-maintenance/contributing-with-ai.md`, and
  `skills/repo-maintenance/SKILL.md`. It lives at `skills/freshness-check/`,
  so every instruction to run it named a path that does not exist — including
  the two in the file agents are told to read before anything else
- `tools/lib/check-outputs.js` — list entries that wrapped onto indented
  continuation lines were read only as far as their first line, so a user story
  lost its `so that` clause and a requirement lost its `[US-n]` reference. This
  was the remaining half of the field-continuation fix: documents had to be
  authored as single long lines to validate, against the repo's own wrapping
  style. Indentation is required for a continuation and a blank line ends an
  entry, so prose following a list is never absorbed into it
- `examples/spec-to-implementation/01-write-spec.md` — the user stories,
  requirements, and open questions are wrapped at the normal width again, now
  that conformance no longer depends on line breaks
- `tools/lib/check-outputs.js` — field and bullet parsing lost data in two
  ways. A bullet label written with the colon inside the bold
  (`- **Total tasks:** 6`) left the closing `**` stranded at the head of the
  value, failing every typed check; and a field value that wrapped onto the
  following lines was read only as far as its first line. The truncating case
  was the more dangerous of the two — a cut `Done when` still reads as present,
  so nothing downstream could tell the condition had been shortened
- `examples/spec-to-implementation/` — the worked examples did not conform to
  the schemas their own prompts declare. `01-write-spec.md` predated the
  `FR-N`/`US-N`/`OQ-N` identifiers and RFC 2119 keywords, and
  `02-break-into-tasks.md` was missing the required `Done` checkbox on every
  task. Both now validate against `sab.feature-spec/1` and `sab.tasks/1`, and
  the downstream references to spec requirements in `02` and `03` use the
  `FR-N` scheme rather than bare numbers
- `prompts/planning/ideate-project.md` — the Next Steps instruction referenced
  `write-feature-spec.md` as a relative markdown link from inside the prompt
  body. Compilation moves that text into a flat skill directory where the path
  resolves to nothing, and the skill then wrote the dead path into the concept
  documents it produced. Other prompts are now referenced by name, and the
  guidance matches the skill wrap-up (product spec for a whole product, feature
  spec for one feature) instead of contradicting it
- `scripts/build-dist.js` warns when a prompt body contains a relative link,
  which cannot survive compilation — catching the defect at build time rather
  than as a broken link in `dist/`

## [1.0.0] — 2026-03-18

Initial release. Complete knowledge base covering context management,
model selection, AI workflow patterns, a full prompt library, agent skills,
worked examples, supporting tooling, and a full repo maintenance and
guardrail system for human and AI contributors.

### Added — Structure and templates

- `README.md` — root repo overview: how to use the repo, directory
  structure, context budget system, supported interfaces, local model
  guidance, and contribution entry points
- `CONTRIBUTING.md` — contribution guide covering prompts, skills, guides,
  and examples; proposal-first requirement; local validation instructions;
  content standards; complete CI check reference
- `AGENTS.md` — rules of engagement for AI agents working in this repo;
  covers propose-before-act rule, atomicity requirement, guardrails
  against hallucination and outdated information, protected files, and
  a quick-reference table for common tasks
- `LICENSE` — MIT license
- `templates/prompt-template.md` — canonical template for all files in
  `prompts/`; complete frontmatter reference with inline documentation,
  all body sections, `review-by` and `verified-against` fields, and a
  pre-commit checklist including change proposal requirement
- `templates/skill-template.md` — Agent Skills spec-compliant template for
  all skill directories; covers directory structure, frontmatter fields,
  body patterns (role/scope, steps, output format, gotchas, validation
  loops, progressive disclosure), `review-by` and `verified-against`
  fields, low-context variant guidance, and skills-vs-prompts reference
- `templates/change-proposal-template.md` — required format for all
  proposed changes; covers file list, before/after diffs, dependency map
  confirmation, sources section, freshness check, and validation checklist
- `templates/structures/` — document structure templates for content types
  not covered by the prompt and skill templates
    - `guide-template.md` — frontmatter with `is_evergreen`, `review-by`,
      and `verified-against` fields; body sections; pre-commit checklist
    - `example-step-template.md` — step file structure with filled-prompt
      section, representative output, and review gate checklist
    - `directory-readme-template.md` — canonical column formats for guide,
      prompt, and example README index tables
    - `changelog-entry-template.md` — entry formats for additions,
      modifications, deletions, and structural changes

### Added — Guides: context

- `guides/context/context-window-basics.md` — what context windows are,
  token estimation, what consumes context in a session, context window
  sizes by model tier, the context budget system, and common failure
  patterns (vanishing instructions, big file problem, compounding history)
- `guides/context/chunking-strategies.md` — when to chunk vs summarise;
  chunking by content type (code, documentation, data files, mixed
  content); overlap strategies; reassembly patterns; shell pipeline
  for processing chunks; common chunking mistakes
- `guides/context/low-memory-workarounds.md` — seven techniques for small
  local models: budget calculation, chunking, `-minimal` skill variants,
  extract-before-sending, session summarisation, one-task-per-session,
  structured output formats, offline pre-processing; LM Studio settings
  for code tasks; quick-reference symptom-to-fix table
- `guides/context/context-budget-guide.md` — step-by-step decision tree
  for choosing the right prompt/skill tier; token estimation by content
  type; quick reference card by model class and session state; guidance
  on improving output when using a lower tier

### Added — Guides: models

- `guides/models/local-vs-remote.md` — five-dimension comparison table;
  when to use local (privacy, offline, high-frequency, experimentation);
  when to use remote (context limits, capability, `high`-budget prompts,
  polish passes); the hybrid approach; decision checklist; environment
  file pattern for switching between endpoints
- `guides/models/model-selection-guide.md` — four capability profiles
  (instruction following, code generation, reasoning, long-context
  coherence); how model size and quantization affect each profile;
  task-to-profile matching table; three-test evaluation process for a
  new model; when to switch to hosted
- `guides/models/lm-studio-setup.md` — model selection criteria (RAM,
  context window, task type); RAM-per-billion-parameters table by
  quantization; server configuration; inference settings for code tasks;
  connection instructions for Cursor, Continue.dev, Aider, and direct
  API (shell, Node, Python); context window checklist; troubleshooting

### Added — Guides: workflows

- `guides/workflows/ide-plugin-workflow.md` — inline chat vs agent mode;
  skill injection for Cursor (`.cursorrules`, chat, `--install-skill`),
  Continue.dev (`config.json`, `.continuerc.json`), and Copilot Chat;
  file reference syntax by plugin; context management in long sessions;
  feature implementation workflow; gotchas
- `guides/workflows/chat-interface-workflow.md` — when chat is the right
  interface; skill injection as first message; prompt pasting and file
  uploads; session discipline; resume pattern using
  `summarize-for-handoff.md`; spec-writing workflow; gotchas
- `guides/workflows/cli-tool-workflow.md` — system prompt flags for Claude
  Code and Aider; stdin piping patterns; scripted/non-interactive mode;
  shell script integration; session management; interface comparison
- `guides/workflows/api-scripted-workflow.md` — LM Studio local endpoint;
  Anthropic and OpenAI API calls; bash, Node.js, and Python script
  patterns; batch processing; response parsing; error handling and rate
  limit patterns

### Added — Guides: agent patterns

- `guides/agent-patterns/single-agent.md` — what makes a good single-agent
  task; the plan-confirm-execute loop; scoping tasks for a single session;
  output validation by type; connecting sessions with clean handoffs;
  common failure modes
- `guides/agent-patterns/multi-agent-orchestration.md` — when multi-agent
  is worth the overhead; the three core roles (Planner, Implementer,
  Reviewer); structured handoff format; reference pipeline from spec to
  tested implementation with human review gates; contradiction resolution;
  common orchestration failures
- `guides/agent-patterns/human-in-the-loop.md` — why review gates matter;
  the three highest-leverage review points; calibrating review depth to
  task risk; efficient review techniques; review gate checklists; when to
  skip a review gate

### Added — Guides: repo maintenance

- `guides/repo-maintenance/how-this-repo-is-structured.md` — authoritative
  reference for what lives where and why; design principles, directory
  purposes, structural invariants, and what-belongs-where decision guide
- `guides/repo-maintenance/dependency-map.md` — defines which files must
  change together for every type of repo modification; enforces atomicity
  for prompts, skills, guides, examples, tools, templates, and CI changes
- `guides/repo-maintenance/contributing-with-ai.md` — how to use the
  repo's own skills to propose additions; step-by-step workflow;
  guardrail descriptions; common pitfalls

### Added — Prompts: code

- `prompts/code/generate-unit-tests.md` — unit test suite generation;
  covers happy paths, edge cases, failure modes; enforces mock discipline
  (external I/O only); test naming convention; low-context variant
- `prompts/code/code-review.md` — structured review across correctness,
  security, maintainability, and conventions; per-finding severity labels;
  summary section; diff review support; low-context variant
- `prompts/code/refactor-for-readability.md` — behaviour-preserving
  refactor focused on naming, function size, nesting, comments, and
  consistency; produces refactored code plus a typed changelog of changes;
  low-context variant
- `prompts/code/scaffold-module.md` — generates module skeleton with typed
  signatures, placeholder bodies, test file scaffold, and barrel file;
  convention-driven; low-context variant
- `prompts/code/explain-codebase.md` — audience- and depth-calibrated
  explanation covering purpose, key components, how it works, dependencies,
  and things to know before modifying; low-context variant

### Added — Prompts: planning

- `prompts/planning/write-feature-spec.md` — structured spec from a rough
  idea; produces overview, goals, non-goals, user stories, functional
  requirements, open questions, and deferred scope; enforces 500-word
  limit and RFC 2119 priority language
- `prompts/planning/break-into-tasks.md` — ordered task list from a
  reviewed spec; each task has a done condition, file list, dependency
  links, and estimate; produces critical path and risk summary
- `prompts/planning/write-adr.md` — Architecture Decision Record with
  context, options considered, decision, consequences (positive, negative,
  neutral), and revisit conditions; enforces non-empty negative consequences
- `prompts/planning/estimate-complexity.md` — structured complexity and
  risk assessment with estimate, confidence level, reasoning, risk factor
  table, assumption list, decomposition recommendation, and escalation flags

### Added — Prompts: testing

- `prompts/testing/generate-test-cases.md` — test case list (no code)
  covering happy paths, boundary values, invalid inputs, error conditions,
  and domain-specific edge cases; coverage gaps section surfaces spec
  ambiguities; supports Given/When/Then and table formats
- `prompts/testing/review-test-coverage.md` — reviews test suite against
  source for missing cases, weak assertions, redundant tests, and quality
  issues; coverage assessment and recommended action; low-context variant
- `prompts/testing/write-e2e-scenario.md` — plain-language or framework
  code e2e scenarios; supports Playwright (TypeScript/Python) and Cypress;
  covers primary happy path, validation/error paths, and state persistence

### Added — Prompts: agent-orchestration

- `prompts/agent-orchestration/decompose-task.md` — breaks a complex task
  into independently executable sub-tasks; each sub-task has a done
  condition, input/output specification, and dependency links; produces
  execution order and assumption list
- `prompts/agent-orchestration/summarize-for-handoff.md` — structured
  session handoff document covering what was produced, decisions made,
  current state, next instruction, and context to carry forward;
  two-level consolidation pattern for chunk processing
- `prompts/agent-orchestration/self-critique-loop.md` — two-step (critique
  then revise) self-review against original requirements; optional focus
  parameter; inline change markers on revised output

### Added — Skills: coding

- `skills/coding/implement-feature/` — feature implementation from a spec;
  plan-confirm-execute loop; surveys codebase before coding; incremental
  implementation; convention adherence; error handling; test generation;
  structured implementation summary output format; constraints and gotchas
    - `references/patterns.md` — per-project stub for code patterns
    - `references/conventions.md` — per-project stub for naming and structure
    - `assets/implementation-summary-template.md` — output format template
- `skills/coding/implement-feature-minimal/` — low-context variant (~400
  tokens); retains role, plan-first rule, output format, and core
  constraints
- `skills/coding/debug-issue/` — systematic root cause diagnosis;
  hypothesis-evidence-isolation-fix-verify workflow; constraints against
  symptom suppression and unrelated changes; async, type coercion, test
  isolation, and stack trace gotchas
    - `references/patterns.md` — per-project stub for debug patterns
    - `references/known-issues.md` — per-project stub for known bugs and
      recurring failure modes
- `skills/coding/debug-issue-minimal/` — low-context variant

### Added — Skills: planning

- `skills/planning/spec-writer/` — iterative spec writing through dialogue;
  ask-before-draft approach with 2–3 targeted questions; prioritised
  question categories (scope, constraints, success); RFC 2119 language
  enforcement; 500-word limit; gotchas for vague acceptance criteria and
  over-broad non-goals
    - `references/domain.md` — per-project stub for domain language and
      business rules
- `skills/planning/spec-writer-minimal/` — low-context variant

### Added — Skills: repo tools

- `skills/repo-maintenance/` — agent skill for maintaining this repo;
  loads `AGENTS.md` rules, applies dependency map, enforces propose-
  before-act, uses templates, checks for contradictions and stale claims
    - `references/repo-structure.md` — complete file tree loaded on demand
    - `references/style-guide.md` — voice, tone, formatting, and language
      patterns to avoid
- `skills/repo-maintenance-minimal/` — low-context variant
- `skills/freshness-check/` — assesses whether a file's external claims
  are likely still accurate; produces a prioritised verification checklist;
  does not verify facts itself
    - `references/external-claims-registry.md` — log of verified external
      claims with source URLs and verification dates

### Added — Examples

- `examples/spec-to-implementation/` — complete four-step worked example
  using a user activity CSV export feature; shows filled-in prompts and
  representative model output; includes human review gate checklists
    - `01-write-spec.md` — spec writing with open question surfacing
    - `02-break-into-tasks.md` — task decomposition with critical path and
      performance risk identification
    - `03-scaffold-module.md` — TypeScript service scaffold with type
      decision rationale
    - `04-generate-tests.md` — Jest test generation with mock patterns and
      coverage gap analysis
- `examples/low-context-chunked-review/` — two-step worked example
  reviewing a 450-line TypeScript service on a local 8k-context model
    - `01-chunk-file.md` — token estimation, chunker invocation, chunk
      verification, 60%-budget-threshold rule
    - `02-review-chunks.md` — per-chunk review pattern, consolidated output
      example, finding triage checklist

### Added — Tools

- `tools/fetch-prompt.sh` — fetches prompts and skills from the repo;
  supports `--copy` (clipboard), `--install-skill` (copies skill directory
  to `.agents/skills/`), `--list` (with context budget display), `--remote`
  (raw GitHub URL fetch), `--raw` (include frontmatter); auto-detects repo
  root from script location; colour output with `NO_COLOR` support
- `tools/chunk-file.sh` — splits files into context-window-friendly chunks;
  three modes (`functions`, `sections`, `lines`; auto-detects from file
  extension); configurable chunk size and overlap; `--dry-run` and
  `--stats` flags; supports 8 language families for function-boundary
  detection; degrades gracefully to `lines` for unknown file types
- `tools/validate.sh` — runs all repo validation checks locally before
  pushing; supports `--check <name>` to run a single check,
  `--changed-only` to scan only modified files, and named check aliases
  matching the CI workflows
- `tools/lib/check_frontmatter.sh` — validates required frontmatter
  fields, `context_budget` values, skill name/directory match, and
  description length; blocks merge on failure
- `tools/lib/check_atomicity.sh` — verifies all dependency-map couplings
  are satisfied for changed files (CHANGELOG, README index tables,
  minimal skill variants); blocks merge on failure
- `tools/lib/check_links.sh` — verifies all internal markdown links
  resolve to existing files; skips links inside code fences and known
  placeholder patterns; blocks merge on failure
- `tools/lib/check_placeholders.sh` — detects unfilled `{{PLACEHOLDER}}`
  tokens outside code fences and inline backtick spans; handles nested
  fence types including VSCode-converted quadruple backtick fences;
  blocks merge on failure
- `tools/lib/check_freshness.sh` — warns on files whose `review-by` date
  has passed or expires within 30 days; non-blocking; runs on PR and
  weekly schedule
- `tools/lib/chunk_file.py` — stub; token-accurate chunker using tiktoken
- `tools/lib/fetch_prompt.js` — stub; Node.js programmatic API for
  `fetch-prompt.sh`

### Added — GitHub configuration

- `.github/ISSUE_TEMPLATE/new-prompt.md` — structured issue template for
  proposing or contributing a new prompt
- `.github/ISSUE_TEMPLATE/new-skill.md` — structured issue template for
  proposing or contributing a new skill
- `.github/pull_request_template.md` — PR checklist covering prompts,
  skills, and general changes
- `.github/workflows/validate-frontmatter.yml` — thin CI wrapper calling
  `tools/lib/check_frontmatter.sh`; blocks merge
- `.github/workflows/validate-change-atomicity.yml` — thin CI wrapper
  calling `tools/lib/check_atomicity.sh`; blocks merge
- `.github/workflows/validate-links.yml` — thin CI wrapper calling
  `tools/lib/check_links.sh`; blocks merge
- `.github/workflows/validate-placeholders.yml` — thin CI wrapper calling
  `tools/lib/check_placeholders.sh`; blocks merge
- `.github/workflows/validate-freshness.yml` — thin CI wrapper calling
  `tools/lib/check_freshness.sh`; warns only; runs on PR and weekly cron

### Design decisions

- **Model-agnostic throughout** — no model names, vendor-specific syntax,
  or pricing in any prompt, skill, or guide; content uses capability tiers
  and interface types instead
- **Context budget as first-class field** — every prompt and skill declares
  `context_budget` / `context-budget` to make local model viability
  immediately visible without reading the content
- **Agent Skills specification compliance** — skills use directory-per-skill
  structure with spec-defined frontmatter; custom metadata (context budget,
  interfaces) goes in the `metadata` map to avoid field conflicts; validated
  by `skills-ref validate` and the CI workflow
- **Outer tilde / quadruple backtick fences for nested code blocks** —
  prompt files that contain code blocks within the prompt text use `~~~`
  (or ` ` ```` after VSCode conversion) for the outer fence and
  triple backticks for inner language-tagged blocks, preventing markdown
  parser failures; the placeholder checker handles any run of 3+ fence
  characters of the same type
- **Copy-not-link distribution** — the repo is used by reading and copying
  into projects, not as a git submodule or dependency; `tools/fetch-prompt.sh`
  and `--install-skill` support this workflow without submodule overhead
- **Per-project reference stubs** — skills include `references/` files
  that are intentionally incomplete stubs; filling them in with
  project-specific patterns and conventions is how skills are adapted for
  a new codebase
- **Propose-before-act for all contributors** — human and AI contributors
  must submit a change proposal (`templates/change-proposal-template.md`)
  before creating or modifying files; `AGENTS.md` encodes this as a hard
  rule for AI agents; CI enforces atomicity automatically
- **Validation scripts run locally and in CI** — all CI checks are
  implemented as shell scripts in `tools/lib/` so developers can run the
  same checks locally before pushing; CI workflows are thin wrappers
- **macOS / bash 3.2 compatibility** — all shell scripts avoid bash 4+
  features (`mapfile`, `grep -P`, `match()` with alternation) to work
  without Homebrew bash on macOS

[1.0.0]: https://github.com/your-org/ai-workflows/releases/tag/v1.0.0
