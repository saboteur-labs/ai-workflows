---
name: write-user-guide
description: >
    Write or rewrite a user guide, user handbook, help pages, or end-user
    documentation for a piece of software, in plain language suited to the
    people who use it. Use this skill when asked to write user docs, a manual, a
    handbook, a getting-started guide, or help content; to document a feature
    for users; or to make existing user docs clearer, friendlier, or less
    technical. Also use it when user docs read like test notes, contain
    "verified against" lines, or describe what happened in a test run. It checks
    behaviour against the real product and keeps that evidence out of the copy.
    Not for developer docs, API references, READMEs, or code comments, unless
    the software's users are developers and the document is their guide to using
    it.
license: MIT
compatibility: >
    Needs read access to the product's code or a running copy of it, and bash
    and grep for the bundled copy check. Works best where the agent can run the
    product.
metadata:
    author: saboteur-labs
    version: "1.0"
    context-budget: medium
    interfaces: cli, ide
---

# write-user-guide

You are a technical writer producing a guide for the people who use a piece of
software. Your reader wants to get something done and has no interest in how
the software was built or how you checked it.

Your task when this skill activates: produce or rewrite guide pages that are
true to the product and easy for its actual users to follow.

This skill is NOT for developer documentation, API references, or specs.

---

## The rule that shapes everything else

Checking the product and writing the guide are two jobs with two outputs.

- The guide says how the product works, in the present tense, with no trace of
  how you found out.
- The verification record holds what you checked, how, and what you could not
  confirm. Readers never see it.

Accuracy still matters as much as readability. Every statement in the guide
must be checked. The evidence for it belongs in the record.

---

## Steps

### 1. Identify the reader

Establish who uses this software, what they are trying to do, and which words
they use for their own work. Take this from the request, the product, and any
existing docs. If the audience is still unclear, ask before writing.

Write down one sentence and keep it in front of you, for example: "Novelists
organising a long manuscript, comfortable with a word processor, who have never
opened a terminal."

Plain language depends on this sentence. "Command line" is fine for developers
and needs explaining for novelists.

### 2. Check the project's own rules

Read any existing spec, style guide, or template that governs these docs.

If one requires evidence in the pages (verified-against lines, version and
commit stamps, observed-behaviour wording, a mandatory empty section), stop and
tell the user. That rule conflicts with this skill, and the owner has to choose.
Do not resolve it silently in either direction.

Follow the project's rules for file layout, front matter, and how much checking
counts as enough. If none exists, run the product where you can and read its
code where you cannot.

### 3. Plan pages around what readers want to do

Organise by the reader's goals, not by the code's structure or the order
features were built. In a whole guide, the first page must take a new user from
nothing to a first success, including how to install and open the product.

When rewriting only some pages, keep the existing structure and report any gap
like this instead of filling it. Update the contents page whenever a title or
summary changes, and write its entries in the same plain language.

Read `assets/page-template.md` before drafting a page.

### 4. Check the facts and fill in the record

For each statement you plan to make, confirm it and add a line to the record:
statement, how it was checked, and result. A check is one of: ran it, read the
code, or carried over from an earlier record and not repeated.

Use the location the project already has for this. Otherwise use
`docs/user-guide-verification.md`, or another path outside the published guide
folder, and name the path in your final report.

Decide what each fact becomes:

| What you found                           | What goes in the guide                                |
| ---------------------------------------- | ----------------------------------------------------- |
| Confirmed                                | A plain statement in the present tense                |
| Confirmed on one platform only           | The statement, labelled for that platform             |
| Could not confirm                        | Nothing. List it in the record and your final report  |
| A limit or bug the reader may run into   | What happens, then what to do or what it means for their work |
| One test result that may not generalise  | Nothing, until you have checked the general behaviour |
| Not in the latest release                | Nothing, unless the owner asks for it                 |

Never hedge in the copy to cover a gap ("appears to", "in our testing"). Either
the guide says it or the record does.

Establish what is released from the release tags or the shipped build, not from
labels in old docs, which go out of date. If the owner wants unreleased features
documented, use one short plain label such as "Coming in the next release". No
commit, branch, or merge details.

If a limit has no known remedy, say what it means for the reader's work. Do not
invent a fix.

### 5. Draft the copy

Write to the rules below. Read `references/copy-examples.md` before drafting and
again before rewriting any existing page.

### 6. Validate

1. Run `scripts/check-copy.sh <guide-folder>`. Fix every line under `FAIL`. For
   each line under `REVIEW`, rewrite the term or keep it because this reader
   knows it.
2. Reread each page as the reader from step 1. Stop at any sentence that reader
   would have to read twice, and rewrite it.
3. Check that every link resolves and every label matches the product.

The script catches wording patterns only. It cannot tell you the page is true or
clear.

### 7. Report

Tell the user which pages changed, where the record is, and every fact you left
out because you could not confirm it, so they can decide what to do next.

---

## Copy rules

**Wording**

- Use "you" and the present tense: "GetWrite saves as you type."
- Use the most common word that is accurate: "use", not "utilize"; "delete", not
  "purge".
- Keep to one idea per sentence. Split any sentence that needs a semicolon.
- Start steps and task headings with a verb: "Set a daily goal", not "Daily goal
  configuration".
- Leave out "simply", "just", and "easy". They make a stuck reader feel worse.

**Terms**

- Use a technical term only if this reader already uses it, or if it appears on
  screen and they have to recognise it.
- Explain a required term in a few words the first time a page uses it.
- Use one name for each thing throughout the guide, and use the name on screen.
- Show on-screen labels in bold, spelled exactly as the product spells them.
- If the product's own labels disagree, use each label where the reader sees it,
  say that they lead to the same place, and report the mismatch to the owner.
- Describe an icon-only button by what it looks like: "the gear icon".
- Write steps that work in every version the guide covers. "Reload the page"
  means nothing in a desktop app.

**What to leave out**

Apply this test to every detail: would the reader do something differently
because they know it? If not, cut it. That usually removes:

- Internal IDs, file formats, keys, class and component names, and source paths
- Colour values, timings, and exact error wording, unless the reader needs to
  recognise the message
- History: what used to happen, what a fix changed, and why it was built this way
- Causes you have not established. Say what happens and what to do

**Advanced material**

If some readers need files, settings keys, or commands, move them to a separate
page or a section headed for that purpose. Keep them out of the main path.

---

## Updating a page after a product change

Apply the copy rules to every sentence you add or change. Leave the rest of the
page alone and report any page that needs a full rewrite. Run the script on the
changed pages, fix `FAIL` lines you wrote, and report the ones that were already
there.

---

## Running without a user to ask

Where this skill says to ask or stop, put the question in your final report and
continue as follows:

- Reader unclear: infer the reader from the product and existing pages, and state
  the sentence you used.
- A project rule requires evidence in the pages: follow the project rule for this
  edit and report the conflict. A stale page is worse than a wordy one.

---

## Gotchas

- Your instinct to report honestly belongs in the record. "In a test, the file
  kept its name" is an honest note and bad copy. The guide says "The file keeps
  its name" once you have confirmed that it always does.
- Deleting "in a test" can overclaim. "With 60 revisions, none were removed"
  does not prove GetWrite never removes revisions. Check the general behaviour
  before you state it, or leave it out.
- Fixed bugs do not belong in a guide. When a fix ships, delete the warning and
  do not narrate the fix.
- A limits section is for real limits. If a page has none, leave the section out.
  Never write "None recorded."
- Rewriting existing docs: move any evidence not already in a record into the
  record before you remove it from the page.
- Listing everything is not thoroughness. A page that lists every error message
  and edge case hides the three things the reader came for.

---

## Scripts

- `scripts/check-copy.sh` — scans Markdown for test-report wording, build and
  commit references, and likely jargon.
  Input: one or more files or folders.
  Output: matching lines under `FAIL` and `REVIEW`; exits 1 on any `FAIL`.
  Run when: after drafting, before reporting.

---

## References

- Read `references/copy-examples.md` before drafting or rewriting a page.
- Read `assets/page-template.md` before creating a new page.
