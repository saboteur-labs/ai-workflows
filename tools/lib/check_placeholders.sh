#!/usr/bin/env bash
# lib/check_placeholders.sh
#
# Checks for unfilled {{PLACEHOLDER}} tokens outside code fences in content
# files, and for unexpected stub markers in non-reference files.
#
# Exit codes: 0 = pass, 1 = fail (blocking), 2 = warn only

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; RESET='\033[0m'
else
  RED=''; GREEN=''; RESET=''
fi

CHANGED_ONLY=0
[[ "${1:-}" == "--changed-only" ]] && CHANGED_ONLY=1

# ── Build file list ────────────────────────────────────────────────────────────
files=()
if [[ "$CHANGED_ONLY" -eq 1 ]]; then
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && files+=("$_line")
  done < <(
    { git diff --name-only HEAD; git diff --name-only --cached; } 2>/dev/null \
    | grep -E '^(prompts|skills|guides|examples)/.*\.md$' | sort -u || true
  )
else
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && files+=("$_line")
  done < <(
    find prompts skills guides examples -name "*.md" -print 2>/dev/null | sort
  )
fi

failed=0

# ── Strip code fences and check for placeholders ──────────────────────────────
for file in "${files[@]:-}"; do
  [[ -z "$file" || ! -f "$file" ]] && continue

  # Per-project reference stubs are legitimately incomplete
  if echo "$file" | grep -qE '/(references|assets)/'; then continue; fi
  if echo "$file" | grep -q 'tools/lib/'; then continue; fi

  # Strip code fences and inline backtick spans before checking.
  #
  # Fences: any run of 3+ identical characters (` or ~) opens a fence.
  # The fence closes on a line that starts with the same character repeated
  # at least the same number of times, with nothing else on the line.
  # This handles ```, ~~~, ```` (VSCode auto-conversion), ~~~~~, etc.
  #
  # Inline backtick spans (`...` and ``...``) are stripped within each
  # non-fenced line so that prose like "fill in `{{PLACEHOLDER}}`" does
  # not trigger a false positive.
  stripped=$(awk '
    BEGIN { in_fence = 0; fence_char = ""; fence_len = 0 }
    function detect_fence(line,    c, n, i) {
      # Returns 1 and sets fence_char/fence_len if line opens a fence
      c = substr(line, 1, 1)
      if (c != "`" && c != "~") return 0
      n = 0
      for (i = 1; i <= length(line); i++) {
        if (substr(line, i, 1) == c) n++
        else break
      }
      if (n >= 3) { fence_char = c; fence_len = n; return 1 }
      return 0
    }
    function is_close(line,    c, n, i, rest) {
      # Returns 1 if line closes the current fence
      c = substr(line, 1, 1)
      if (c != fence_char) return 0
      n = 0
      for (i = 1; i <= length(line); i++) {
        if (substr(line, i, 1) == c) n++
        else break
      }
      # Remainder must be only spaces
      rest = substr(line, n + 1)
      gsub(/[[:space:]]/, "", rest)
      return (n >= fence_len && rest == "")
    }
    {
      if (in_fence) {
        if (is_close($0)) { in_fence = 0; fence_char = ""; fence_len = 0 }
        next
      }
      if (detect_fence($0)) { in_fence = 1; next }
      # Strip inline backtick spans: ``...`` then `...`
      gsub(/``[^`]*``/, "")
      gsub(/`[^`]*`/, "")
      print
    }
  ' "$file")

  # Check for {{PLACEHOLDER}} pattern (uppercase letters and underscores only)
  matches=$(echo "$stripped" | grep -oE '\{\{[A-Z][A-Z0-9_]*\}\}' | sort -u || true)
  if [[ -n "$matches" ]]; then
    echo -e "${RED}FAIL${RESET}  Unfilled placeholders in $file:"
    echo "$matches" | while read -r m; do echo "         $m"; done
    failed=1
  fi

  # Check for stub markers (🔲 **Stub**) outside reference files
  if grep -q "🔲 \*\*Stub\*\*" "$file" 2>/dev/null; then
    echo -e "${RED}FAIL${RESET}  Stub marker found in $file"
    echo "         Complete the content or remove the stub marker before merging."
    failed=1
  fi
done

if [[ "$failed" -eq 0 ]]; then
  echo -e "${GREEN}PASS${RESET}  No unfilled placeholders or unexpected stub markers found."
  exit 0
else
  echo ""
  echo "  Note: {{PLACEHOLDERS}} inside code fences (~~~ or \`\`\`) are intentional"
  echo "  and are excluded from this check."
  exit 1
fi