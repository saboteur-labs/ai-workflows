#!/usr/bin/env bash
# runlog-record.sh — append one Claude Code hook event to the runlog.
#
# Registered for SessionStart, UserPromptSubmit, PreToolUse, PostToolUse,
# PostToolUseFailure, SubagentStart, SubagentStop, and Stop. Each event becomes
# one JSON line in:
#
#   $RUNLOG_ROOT/repos/<repo-key>/<session_id>.jsonl
#
# A session is filed under the repo it was first seen in, and stays there even
# when it later works in another repo or a worktree. The mapping is written once
# to $RUNLOG_ROOT/sessions/<session_id>; first writer wins.
#
# The line records facts only: the hook payload as received, with long strings
# truncated and common secret shapes redacted. Nothing here interprets an event.
#
# This runs on every tool call in every session. It must never change what the
# agent does, so it fails open at every step and always exits 0 — exit 2 would
# block a tool call.
#
# Usage:
#   runlog-record.sh                 Read a hook payload on stdin and record it
#   runlog-record.sh --repo-key DIR  Print the repo key for DIR
#   runlog-record.sh --root          Print the runlog root
set -u
umask 077

root="${RUNLOG_ROOT:-$HOME/.claude/runlogs}"
max_string="${RUNLOG_MAX_STRING:-2000}"

# Key a directory by the repository it belongs to, not by the directory itself,
# so every worktree of a repo shares one key. The origin remote is preferred so
# that moving a clone does not split its logs; a repo without one is keyed by
# its main worktree path. Anything outside git goes to "_no-repo".
repo_key() {
  local dir=$1 common main remote slug hash
  common=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || {
    printf '_no-repo'
    return
  }
  main=${common%/.git}
  remote=$(git -C "$dir" remote get-url origin 2>/dev/null)
  if [ -n "$remote" ]; then
    slug=${remote%.git}
    slug=${slug#*://}
    slug=${slug#*@}
    slug=${slug/://}
    printf '%s' "$slug" | tr -c 'A-Za-z0-9._-' '_'
  else
    hash=$(printf '%s' "$main" | shasum | cut -c1-8)
    printf '%s-%s' "$(printf '%s' "${main##*/}" | tr -c 'A-Za-z0-9._-' '_')" "$hash"
  fi
}

case "${1:-}" in
  --repo-key) repo_key "${2:-$PWD}"; echo; exit 0 ;;
  --root)     printf '%s\n' "$root"; exit 0 ;;
esac

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat) || exit 0

# session_id becomes a filename, so anything but a plain id is refused.
fields=$(printf '%s' "$input" | jq -r '[.session_id // "", .cwd // ""] | @tsv' 2>/dev/null) || exit 0
session_id=${fields%%$'\t'*}
cwd=${fields#*$'\t'}
case "$session_id" in
  ''|*[!A-Za-z0-9_-]*) exit 0 ;;
esac
[ -n "$cwd" ] || cwd="${CLAUDE_PROJECT_DIR:-$PWD}"

mkdir -p "$root/sessions" 2>/dev/null || exit 0
map="$root/sessions/$session_id"
if [ ! -s "$map" ]; then
  key=$(repo_key "$cwd")
  # noclobber makes the create atomic: concurrent first events race, one wins,
  # and every event then reads the winner's key back.
  (set -o noclobber; printf '%s\n' "$key" > "$map") 2>/dev/null
fi
key=$(cat "$map" 2>/dev/null) || exit 0
[ -n "$key" ] || exit 0

dir="$root/repos/$key"
mkdir -p "$dir" 2>/dev/null || exit 0

line=$(printf '%s' "$input" | jq -c --arg key "$key" --argjson max "$max_string" '
  def redact:
    gsub("(?<k>(?i)(api[_-]?key|secret|token|password|passwd)[\"'"'"']?\\s*[:=]\\s*[\"'"'"']?)[^\\s\"'"'"'&,;]+"; "\(.k)[REDACTED]")
    | gsub("(?<k>(?i)bearer\\s+)[A-Za-z0-9._~+/=-]+"; "\(.k)[REDACTED]")
    | gsub("(sk-[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16})"; "[REDACTED]");
  def clip:
    if length > $max then .[0:$max] + "…[truncated \(length - $max) chars]" else . end;
  {
    v: 1,
    ts: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
    ts_ms: (now * 1000 | floor),
    repo: $key,
    event: (.hook_event_name // null),
    session_id: .session_id,
    agent_id: (.agent_id // null),
    tool_use_id: (.tool_use_id // null),
    payload: (walk(if type == "string" then (redact | clip) else . end))
  }' 2>/dev/null) || exit 0
[ -n "$line" ] || exit 0

# A plain >> is not safe here: parallel tool calls and subagents append to the
# same session file at once, and lines of a few KB interleave. Measured: 200
# concurrent ~12KB appends left line 23 corrupt. flock serialises the write and
# the kernel releases it if the process dies. perl is the lock because it ships
# on macOS and most Linux, where flock(1) and lockf(1) each exist on only one.
log="$dir/$session_id.jsonl"
if command -v perl >/dev/null 2>&1; then
  printf '%s\n' "$line" | perl -MFcntl=:flock -e '
    open(my $fh, ">>", $ARGV[0]) or exit 0;
    flock($fh, LOCK_EX) or exit 0;
    local $/; my $data = <STDIN>;
    syswrite($fh, $data);
  ' "$log" 2>/dev/null
else
  printf '%s\n' "$line" >> "$log" 2>/dev/null
fi
exit 0
