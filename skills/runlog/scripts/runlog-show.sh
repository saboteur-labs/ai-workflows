#!/usr/bin/env bash
# runlog-show.sh — read runlogs written by runlog-record.sh.
#
# Usage:
#   runlog-show.sh --list [DIR]     List sessions filed under DIR's repo (default: $PWD)
#   runlog-show.sh SESSION_ID       Print one session as a timeline
#   runlog-show.sh FILE.jsonl       Print one session file as a timeline
#
# The timeline states what was recorded and nothing more. A PreToolUse with no
# matching PostToolUse or PostToolUseFailure is shown as "no result recorded" —
# not as denied or interrupted, because the log alone cannot tell which.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
record="$here/runlog-record.sh"
root=$(bash "$record" --root)

command -v jq >/dev/null 2>&1 || { echo "runlog-show: jq is required" >&2; exit 1; }

usage() { sed -n '/^# Usage:/,/^[^#]/{ /^#/{ s/^# \{0,1\}//; p; }; }' "$0"; exit "${1:-0}"; }

case "${1:-}" in
  ''|-h|--help) usage ;;
  --list)
    key=$(bash "$record" --repo-key "${2:-$PWD}")
    dir="$root/repos/$key"
    [ -d "$dir" ] || { echo "No runlogs for $key under $root"; exit 0; }
    echo "repo: $key"
    # Newest first. The running session is usually, but not necessarily, the
    # newest: two sessions in the same repo write concurrently.
    ls -t "$dir"/*.jsonl 2>/dev/null | while read -r f; do
      jq -R 'fromjson? // empty' "$f" | jq -rs --arg id "$(basename "$f" .jsonl)" '
        (map(select(.event == "UserPromptSubmit"))[0].payload
          | (.prompt // .user_prompt // "") | gsub("\\s+"; " ") | .[0:70]) as $first
        | "\($id)  \(.[0].ts) → \(.[-1].ts)  \(length) events  \($first)"
      ' 2>/dev/null || echo "$(basename "$f" .jsonl)  (unreadable)"
    done
    exit 0
    ;;
esac

target=$1
if [ -f "$target" ]; then
  file=$target
else
  case "$target" in *[!A-Za-z0-9_-]*) echo "runlog-show: not a session id: $target" >&2; exit 1 ;; esac
  key=$(cat "$root/sessions/$target" 2>/dev/null) || { echo "runlog-show: no session $target" >&2; exit 1; }
  file="$root/repos/$key/$target.jsonl"
fi

# Lines that fail to parse are skipped and counted rather than aborting the read.
bad=$(jq -c . "$file" 2>&1 >/dev/null | grep -c 'parse error' || true)
jq -R 'fromjson? // empty' "$file" | jq -rs '
  def one_line: tostring | gsub("\\s+"; " ") | .[0:100];
  def summary:
    .payload as $p
    | ($p.tool_input // {}) as $in
    | if .event == "UserPromptSubmit" then ($p.prompt // $p.user_prompt // "") | one_line
      elif .event == "SubagentStart" then ($p.agent_prompt // "") | one_line
      elif (.event == "Stop" or .event == "SubagentStop") then ($p.last_assistant_message // "") | one_line
      elif .event == "PostToolUseFailure" then ($p.error // "") | one_line
      elif $in.command then $in.command | one_line
      elif $in.file_path then $in.file_path
      elif $in.pattern then $in.pattern
      elif $in.prompt then $in.prompt | one_line
      elif $in.description then $in.description | one_line
      else ""
      end;
  (map(select(.event == "PostToolUse" or .event == "PostToolUseFailure") | .tool_use_id) | unique) as $resolved
  | sort_by(.ts_ms)[]
  | . as $e
  | ($e.payload.agent_type // (if $e.agent_id then "subagent" else "main" end)) as $who
  | [ ($e.ts | .[11:19]),
      $who,
      $e.event,
      ($e.payload.tool_name // ""),
      summary,
      (if $e.event == "PreToolUse" and ($e.tool_use_id as $id | $resolved | any(.[]; . == $id) | not)
         then "(no result recorded)" else "" end)
    ]
  | map(select(. != "")) | join("  ")
'
[ "$bad" -eq 0 ] || echo "($bad unparseable lines skipped)" >&2
