#!/usr/bin/env bash
# lib/check_links.sh
#
# Checks that all internal markdown links resolve to existing files.
# Locally scans all .md files. With --changed-only, scans only changed files.
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
    | grep '\.md$' | sort -u || true
  )
else
  mapfile -t files < <(
    find . -name "*.md" \
      -not -path "./.git/*" \
      -not -path "./node_modules/*" \
      -print | sort
  )
fi

failed=0
total_broken=0

for md_file in "${files[@]:-}"; do
  [[ -z "$md_file" || ! -f "$md_file" ]] && continue
  file_dir=$(dirname "$md_file")

  # Extract all markdown link targets: [text](target)
  while IFS= read -r link; do
    [[ -z "$link" ]] && continue
    # Skip external URLs
    [[ "$link" =~ ^https?:// ]] && continue
    [[ "$link" =~ ^mailto: ]]   && continue
    # Skip anchor-only links
    [[ "$link" =~ ^# ]] && continue

    # Strip anchor fragment
    target="${link%%#*}"
    [[ -z "$target" ]] && continue

    # Resolve path relative to the file's directory
    if [[ "$target" == /* ]]; then
      resolved=".${target}"
    else
      resolved="${file_dir}/${target}"
    fi

    # Normalise (remove ./ and ../ components)
    # Use Python if available for reliable path normalisation; fall back to bash
    if command -v python3 &>/dev/null; then
      resolved=$(python3 -c "
import os, sys
p = os.path.normpath('$resolved')
print(p)
" 2>/dev/null || echo "$resolved")
    fi

    if [[ ! -f "$resolved" && ! -d "$resolved" ]]; then
      echo -e "${RED}FAIL${RESET}  Broken link in $md_file"
      echo "       Link target: $link"
      echo "       Resolved to: $resolved"
      (( total_broken++ )) || true
      failed=1
    fi
  done < <(grep -oP '(?<=\]\()([^)]+)(?=\))' "$md_file" 2>/dev/null || true)
done

if [[ "$failed" -eq 0 ]]; then
  echo -e "${GREEN}PASS${RESET}  All internal links resolve."
  exit 0
else
  echo ""
  echo "  ${total_broken} broken link(s) found."
  echo "  To find all files linking to a specific file:"
  echo "    grep -r 'filename' . --include='*.md' -l"
  exit 1
fi