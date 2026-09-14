#!/usr/bin/env bash
# PreToolUse(Write|Edit) — enforce the saboteur-ship plan gate.
#
# While a pipeline run is active and the plan has NOT been approved, no code may
# be written. Spec and task-list writes are exempt: the rungs below the plan gate
# produce them, and they are what the user approves at the gate.
#
# Keyed on the marker files, not on stage numbers, so renumbering the pipeline
# does not move this.
#
# This runs on EVERY Write/Edit in every repo, so the common path (no pipeline
# running) must be as close to free as possible: stdin is parsed with bash
# pattern matching rather than jq, and no subprocess is spawned unless the run
# is actually being gated. Fails open at every step.
set -u

input=$(cat)

# Cheap cwd extraction — no subprocess. Falls back to the environment.
cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
case "$input" in
  *'"cwd"'*)
    stripped=${input#*\"cwd\":\"}
    candidate=${stripped%%\"*}
    [ -n "$candidate" ] && cwd="$candidate"
    ;;
esac

[ -e "$cwd/.claude/.pipeline-active" ] || exit 0   # no run in progress
[ -e "$cwd/.claude/.plan-approved" ] && exit 0     # gate already cleared

# Gating is live from here on; the extra precision is worth a jq call now.
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -n "$path" ] || exit 0

case "$path" in
  "$cwd"/specs/*|"$cwd"/.claude/*|specs/*|.claude/*) exit 0 ;;
esac

jq -n --arg p "$path" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: (
      "The saboteur-ship plan gate has not cleared: the plan is not " +
      "approved, so \($p) must not be written yet. Present the task list and " +
      "get approval (which creates .claude/.plan-approved), or run the " +
      "pipeline Cleanup step to end the run."
    )
  }
}'
exit 0
