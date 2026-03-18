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
if [[ "$CHANGED_ONLY" -eq 1 ]]; then
  mapfile -t files < <(
    { git diff --name-only HEAD; git diff --name-only --cached; } 2>/dev/null \
    | grep -E '^(prompts|skills|guides|examples)/.*\.md$' | sort -u || true
  )
else
  mapfile -t files < <(
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

  # Strip code fences (``` and ~~~) before checking
  # Placeholders inside fences are intentional (template examples)
  stripped=$(awk '
    /^(```|~~~)/ { in_fence = !in_fence; next }
    !in_fence    { print }
  ' "$file")

  # Check for {{PLACEHOLDER}} pattern (uppercase letters and underscores only)
  matches=$(echo "$stripped" | grep -oP '\{\{[A-Z][A-Z0-9_]*\}\}' | sort -u || true)
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