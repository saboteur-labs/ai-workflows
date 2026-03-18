#!/usr/bin/env bash
# lib/check_links.sh
#
# Checks that all internal markdown links resolve to existing files.
# Skips links inside code fences (``` or ~~~) — those are examples,
# not real references.
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
    | grep '\.md$' | sort -u || true
  )
else
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && files+=("$_line")
  done < <(
    find . -name "*.md" \
      -not -path "./.git/*" \
      -not -path "./node_modules/*" \
      -print | sort
  )
fi

# ── Extract links outside code fences using Python ────────────────────────────
# Python handles fence tracking and link extraction more reliably than sed.
# Falls back to sed-based extraction (with fence stripping) if Python unavailable.
extract_links_python() {
  local file="$1"
  python3 - "$file" << 'PYEOF'
import re, sys

fence_re = re.compile(r'^(```|~~~)')
link_re  = re.compile(r'\[(?:[^\]]*)\]\(([^)]+)\)')

in_fence = False
for line in open(sys.argv[1], encoding='utf-8', errors='replace'):
    stripped = line.rstrip('\n')
    if fence_re.match(stripped):
        in_fence = not in_fence
        continue
    if not in_fence:
        for m in link_re.finditer(stripped):
            print(m.group(1))
PYEOF
}

extract_links_sed() {
  local file="$1"
  # Strip code fences first, then extract links
  awk '/^(```|~~~)/{fence=!fence; next} !fence{print}' "$file" \
    | sed -n 's/.*\](\([^)]*\)).*/\1/p'
}

# ── Resolve a link target relative to its source file ─────────────────────────
resolve_link() {
  local target="$1" file_dir="$2"
  local resolved

  if [[ "$target" == /* ]]; then
    resolved=".${target}"
  else
    resolved="${file_dir}/${target}"
  fi

  # Normalise path (remove ./ and ../ components)
  if command -v python3 &>/dev/null; then
    python3 -c "import os; print(os.path.normpath('${resolved}'))" 2>/dev/null \
      || echo "$resolved"
  else
    # Pure bash normalisation — handles simple ../ cases
    echo "$resolved" | sed 's|/\./|/|g; s|/[^/]*/\.\./|/|g; s|^\./||'
  fi
}

# ── Skip patterns: links that are intentionally not real paths ─────────────────
# These appear in template files as illustrative examples.
is_placeholder_link() {
  local target="$1"
  # Contains {{PLACEHOLDER}} tokens
  [[ "$target" == *"{{"* ]] && return 0
  # Generic example paths used in templates and style guides
  case "$target" in
    path/to/*|./path/to/*) return 0 ;;
    */path/to/*)           return 0 ;;
  esac
  return 1
}

# ── Main loop ─────────────────────────────────────────────────────────────────
failed=0
total_broken=0

for md_file in "${files[@]:-}"; do
  [[ -z "$md_file" || ! -f "$md_file" ]] && continue
  file_dir=$(dirname "$md_file")

  # Choose extraction method
  if command -v python3 &>/dev/null; then
    extract_fn=extract_links_python
  else
    extract_fn=extract_links_sed
  fi

  while IFS= read -r link; do
    [[ -z "$link" ]] && continue

    # Skip external URLs and mailto
    [[ "$link" =~ ^https?:// ]] && continue
    [[ "$link" =~ ^mailto: ]]   && continue
    # Skip anchor-only links
    [[ "$link" =~ ^# ]] && continue

    # Strip anchor fragment
    target="${link%%#*}"
    [[ -z "$target" ]] && continue

    # Skip placeholder/example links from template files
    is_placeholder_link "$target" && continue

    resolved=$(resolve_link "$target" "$file_dir")

    if [[ ! -f "$resolved" && ! -d "$resolved" ]]; then
      echo -e "${RED}FAIL${RESET}  Broken link in $md_file"
      echo "       Link target : $link"
      echo "       Resolved to : $resolved"
      (( total_broken++ )) || true
      failed=1
    fi
  done < <($extract_fn "$md_file" 2>/dev/null || true)
done

if [[ "$failed" -eq 0 ]]; then
  echo -e "${GREEN}PASS${RESET}  All internal links resolve."
  exit 0
else
  echo ""
  echo "  ${total_broken} broken link(s) found."
  echo ""
  echo "  If a link points to a file you are about to add in this same PR,"
  echo "  add and stage that file before running this check."
  echo "  To find all files linking to a specific file:"
  echo "    grep -r 'filename' . --include='*.md' -l"
  exit 1
fi