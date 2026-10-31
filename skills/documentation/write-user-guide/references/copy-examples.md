# Copy examples

Each pair comes from a real user handbook for a writing app. The "before" is an
accurate page written like a test report. The "after" assumes the behaviour has
been confirmed. Where it has not, the statement stays out of the guide and goes
in the verification record.

---

## Test results become plain statements

**Before:** The text documents are stitched together in the order of your
resource tree. In a test, a document inside a folder came out where that folder
sits in the tree, and after Gamma Doc was dragged above Beta Doc in the tree and
the project reloaded, both the dialog's list and the compiled file began with
Gamma Doc.

**After:** Your documents appear in the file in the same order as your resource
tree. To change the order, drag them in the tree before you compile.

---

## Provenance goes away

**Before:** Verified against GetWrite 2.2.0 (root package.json) plus unreleased
changes, base commit 0343e19a.

**After:** Delete it. The record holds the version and commit.

---

## Coverage notes go to the record

**Before:** Press **Cmd+K** or **Ctrl+K** to open search. On macOS both shortcuts
moved focus to the search field. Windows and Linux were not run.

**After:** Press **Cmd+K** (Mac) or **Ctrl+K** (Windows and Linux) to open
search.

The record says: "Windows and Linux shortcut read from the code, not run." If the
project requires every statement to be run, leave out the Windows and Linux
shortcut until someone has run it, and report that.

---

## Limits say what to do

**Before:** A folder created inside the Workspace folder through the New resource
dialog was not shown in the tree until the page was reloaded (three runs).

**After:** A new folder inside **Workspace** may not appear straight away. Reload
the page to see it.

In a guide that also covers a desktop app, name the action that works there too.

---

## History comes out

**Before:** Not yet in a release: the marks now run from the older revision to the
canonical one, the usual direction for a comparison. Checked in component tests
and in Storybook, not in the running app.

**After:** Leave it out until it ships and has been checked in the app. Then
describe only how it works at that point.

---

## Implementation detail comes out

**Before:** The name is stored with the revision (as its `metadata.name`, in the
`metadata.json` file of that revision) and shown as the heading of its card.

**After:** The name appears at the top of the revision's card.

---

## Required terms get explained

**Before:** At any moment, exactly one revision is the **canonical** revision.

**After:** A revision is a saved version of your document. The one you are working
on is marked **Canonical**. It's the version you see and edit.

**Canonical** stays because the reader sees it on screen. "Metadata" could go the
same way on a page where the reader never meets the word.

---

## Details the reader cannot act on come out

**Before:** The window is read-only: set the goal in Project Settings. No red colour
was found in the footer or the window in the states checked.

**After:** To change your goal, go to **Project Settings**.

---

## Goal-based headings

**Before:** `## Total and per-resource word-count goals`

**After:** `## Set a word goal for a project or document`

---

## Honest gaps are not copy

**Before:** Whether the original run failed for that reason was not repeated, so it
is not established. Other formats, larger compiles, a Finder launch and a .dmg
build were not tried.

**After:** Nothing in the guide. In the record: "Compile in the packaged desktop
app: not checked for formats other than txt." In the final report: the same
sentence, so the owner can decide whether to run it.
