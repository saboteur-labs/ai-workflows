#!/usr/bin/env bash
# lib/check_frontmatter.sh
#
# Validates frontmatter in prompt and skill files.
# Called by validate.sh and by .github/workflows/validate-frontmatter.yml.
#
# Exit codes: 0 = pass, 1 = fail (blocking), 2 = warn only

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; RESET=''
fi

CHANGED_ONLY=0
[[ "${1:-}" == "--changed-only" ]] && CHANGED_ONLY=1

failed=0

# ── Helper: extract a frontmatter field value ─────────────────────────────────
frontmatter_field() {
  local file="$1" field="$2"
  awk -v f="$field" '
    /^---$/ { fm++; next }
    fm==1 && $0 ~ "^"f":" { sub("^"f":[ ]*",""); print; exit }
  ' "$file"
}

# ── Build file list ────────────────────────────────────────────────────────────
prompt_files=()
skill_files=()
if [[ "$CHANGED_ONLY" -eq 1 ]]; then
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && prompt_files+=("$_line")
  done < <(
    { git diff --name-only HEAD; git diff --name-only --cached; } 2>/dev/null \
    | grep -E '^prompts/[^/]+/[^/]+\.md$' | grep -v 'README\.md' | sort -u || true
  )
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && skill_files+=("$_line")
  done < <(
    { git diff --name-only HEAD; git diff --name-only --cached; } 2>/dev/null \
    | grep -E '^skills/.*/SKILL\.md$' | sort -u || true
  )
else
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && prompt_files+=("$_line")
  done < <(find prompts -name "*.md" ! -name "README.md" -print 2>/dev/null | sort)
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && skill_files+=("$_line")
  done < <(find skills -name "SKILL.md" -print 2>/dev/null | sort)
fi

# ── Check prompt files ─────────────────────────────────────────────────────────
for file in "${prompt_files[@]:-}"; do
  [[ -z "$file" || ! -f "$file" ]] && continue

  file_failed=0

  for field in title category context_budget interfaces; do
    if ! grep -q "^${field}:" "$file" 2>/dev/null; then
      echo -e "${RED}FAIL${RESET} Missing '${field}' in $file"
      file_failed=1
    fi
  done

  budget=$(frontmatter_field "$file" "context_budget")
  case "$budget" in
    low|medium|high) ;;
    "")
      echo -e "${RED}FAIL${RESET} Missing context_budget value in $file"
      file_failed=1 ;;
    *)
      echo -e "${RED}FAIL${RESET} Invalid context_budget '${budget}' in $file (must be low, medium, or high)"
      file_failed=1 ;;
  esac

  [[ "$file_failed" -eq 1 ]] && failed=1
done

# ── Check skill files ──────────────────────────────────────────────────────────
for file in "${skill_files[@]:-}"; do
  [[ -z "$file" || ! -f "$file" ]] && continue

  file_failed=0
  skill_dir="$(dirname "$file")"
  skill_name="$(basename "$skill_dir")"

  for field in name description; do
    if ! grep -q "^${field}:" "$file" 2>/dev/null; then
      echo -e "${RED}FAIL${RESET} Missing '${field}' in $file"
      file_failed=1
    fi
  done

  name_val=$(frontmatter_field "$file" "name")
  if [[ -n "$name_val" && "$name_val" != "$skill_name" ]]; then
    echo -e "${RED}FAIL${RESET} name '${name_val}' does not match directory '${skill_name}' in $file"
    file_failed=1
  fi

  # Validate name format: lowercase, hyphens, no leading/trailing/consecutive hyphens
  if [[ -n "$name_val" ]]; then
    if ! echo "$name_val" | grep -qE '^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$'; then
      echo -e "${RED}FAIL${RESET} name '${name_val}' contains invalid characters in $file"
      file_failed=1
    fi
    if echo "$name_val" | grep -q '\-\-'; then
      echo -e "${RED}FAIL${RESET} name '${name_val}' contains consecutive hyphens in $file"
      file_failed=1
    fi
    if [[ ${#name_val} -gt 64 ]]; then
      echo -e "${RED}FAIL${RESET} name '${name_val}' exceeds 64 characters in $file"
      file_failed=1
    fi
  fi

  # Check description length (strip YAML block scalar indicators)
  desc_len=$(awk '
    /^description:/ { in_desc=1; sub(/^description:[ >|]*/, ""); if ($0) print; next }
    in_desc && /^[a-z]/ { exit }
    in_desc { print }
  ' "$file" | tr -d '\n' | wc -c)
  if [[ "$desc_len" -gt 1024 ]]; then
    echo -e "${RED}FAIL${RESET} description exceeds 1024 chars ($desc_len) in $file"
    file_failed=1
  fi

  [[ "$file_failed" -eq 1 ]] && failed=1
done

if [[ "$failed" -eq 0 ]]; then
  echo -e "${GREEN}PASS${RESET}  Frontmatter valid in all checked files."
  exit 0
else
  exit 1
fi