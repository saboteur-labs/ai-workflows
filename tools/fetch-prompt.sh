#!/usr/bin/env bash
# fetch-prompt.sh
#
# Fetch a prompt or skill from the ai-workflows knowledge base.
#
# Usage:
#   fetch-prompt.sh <category/name>              Print prompt text to stdout
#   fetch-prompt.sh --skill <category/name>      Print skill SKILL.md to stdout
#   fetch-prompt.sh --raw <category/name>        Print full file including frontmatter
#   fetch-prompt.sh --list [category]            List available prompts (or skills)
#   fetch-prompt.sh --list --skill [category]    List available skills
#   fetch-prompt.sh --copy <category/name>       Copy prompt text to clipboard
#   fetch-prompt.sh --install-skill <cat/name>   Copy skill dir to .agents/skills/
#
# Options:
#   -h, --help        Show this help message
#   -q, --quiet       Suppress informational output (stdout only)
#   --strip           Strip frontmatter (default for prompts, off for --raw)
#   --no-strip        Keep frontmatter in output
#   --base <path>     Override the repo base path (default: auto-detected)
#   --remote <url>    Fetch from a remote repo URL instead of local
#
# Examples:
#   fetch-prompt.sh code/generate-unit-tests
#   fetch-prompt.sh --skill coding/implement-feature
#   fetch-prompt.sh --copy planning/write-feature-spec
#   fetch-prompt.sh --install-skill coding/implement-feature
#   fetch-prompt.sh --list code
#   fetch-prompt.sh --remote https://raw.githubusercontent.com/saboteur-labs/ai-workflows/main \
#     code/generate-unit-tests

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BASE="$(cd "$SCRIPT_DIR/.." && pwd)"
PROMPTS_DIR="prompts"
SKILLS_DIR="skills"
AGENTS_SKILLS_DIR=".agents/skills"
FRONTMATTER_DELIM="---"

# ---------------------------------------------------------------------------
# Colours (disabled if not a terminal or NO_COLOR is set)
# ---------------------------------------------------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; CYAN=''; BOLD=''; RESET=''
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()  { [[ "${QUIET:-0}" == "1" ]] || echo -e "${CYAN}${*}${RESET}" >&2; }
warn()  { echo -e "${YELLOW}warning: ${*}${RESET}" >&2; }
error() { echo -e "${RED}error: ${*}${RESET}" >&2; exit 1; }
ok()    { [[ "${QUIET:-0}" == "1" ]] || echo -e "${GREEN}${*}${RESET}" >&2; }

usage() {
  sed -n '/^# Usage:/,/^[^#]/{ /^#/{ s/^# \{0,1\}//; p }; /^[^#]/q }' "$0"
  exit 0
}

# Strip YAML frontmatter (everything between the first pair of --- lines)
strip_frontmatter() {
  awk '
    BEGIN { in_fm=0; done=0 }
    /^---$/ && !done {
      if (!in_fm) { in_fm=1; next }
      else        { in_fm=0; done=1; next }
    }
    !in_fm && done { print }
  '
}

# Extract a single frontmatter field value
frontmatter_field() {
  local file="$1" field="$2"
  awk -v field="$field" '
    /^---$/ { fm++; next }
    fm==1 && $0 ~ "^"field":" {
      sub("^"field": *", ""); print; exit
    }
  ' "$file"
}

# Check if clipboard tool is available
clipboard_tool() {
  if command -v pbcopy &>/dev/null;  then echo "pbcopy"
  elif command -v xclip &>/dev/null; then echo "xclip -selection clipboard"
  elif command -v xsel &>/dev/null;  then echo "xsel --clipboard --input"
  elif command -v clip &>/dev/null;  then echo "clip"
  else echo ""
  fi
}

# Resolve the repo base directory from script location or --base override
resolve_base() {
  local base="${BASE_OVERRIDE:-$DEFAULT_BASE}"
  [[ -d "$base" ]] || error "Repo base not found: $base\nUse --base <path> to specify it."
  echo "$base"
}

# ---------------------------------------------------------------------------
# Fetch from remote URL
# ---------------------------------------------------------------------------
fetch_remote() {
  local base_url="$1" target_path="$2"
  local url="${base_url%/}/${target_path}"
  info "Fetching: $url"

  if command -v curl &>/dev/null; then
    curl -fsSL "$url" || error "Failed to fetch: $url"
  elif command -v wget &>/dev/null; then
    wget -qO- "$url" || error "Failed to fetch: $url"
  else
    error "Neither curl nor wget found. Install one to use --remote."
  fi
}

# ---------------------------------------------------------------------------
# List available prompts or skills
# ---------------------------------------------------------------------------
cmd_list() {
  local base skill_mode="${1:-0}" category="${2:-}"
  base="$(resolve_base)"
  local dir
  dir="${base}/$([ "$skill_mode" == "1" ] && echo "$SKILLS_DIR" || echo "$PROMPTS_DIR")"

  [[ -d "$dir" ]] || error "Directory not found: $dir"

  echo -e "${BOLD}$([ "$skill_mode" == "1" ] && echo "Skills" || echo "Prompts")${RESET}" >&2

  if [[ -n "$category" ]]; then
    local cat_dir="${dir}/${category}"
    [[ -d "$cat_dir" ]] || error "Category not found: $category"
    if [[ "$skill_mode" == "1" ]]; then
      # Skills are directories containing SKILL.md
      find "$cat_dir" -maxdepth 1 -mindepth 1 -type d | sort | while read -r d; do
        local name budget
        name="$(basename "$d")"
        budget="$(frontmatter_field "$d/SKILL.md" "context-budget" 2>/dev/null || echo "?")"
        printf "  %-40s  [%s]\n" "${category}/${name}" "${budget:-?}"
      done
    else
      find "$cat_dir" -maxdepth 1 -name "*.md" ! -name "README.md" | sort | while read -r f; do
        local name budget
        name="$(basename "$f" .md)"
        budget="$(frontmatter_field "$f" "context_budget" 2>/dev/null || echo "?")"
        printf "  %-40s  [%s]\n" "${category}/${name}" "${budget:-?}"
      done
    fi
  else
    # List all categories and items
    find "$dir" -mindepth 1 -maxdepth 1 -type d | sort | while read -r cat_dir; do
      local cat
      cat="$(basename "$cat_dir")"
      echo -e "\n  ${BOLD}${cat}/${RESET}" >&2
      if [[ "$skill_mode" == "1" ]]; then
        find "$cat_dir" -maxdepth 1 -mindepth 1 -type d | sort | while read -r d; do
          local name budget
          name="$(basename "$d")"
          budget="$(frontmatter_field "$d/SKILL.md" "context-budget" 2>/dev/null || echo "?")"
          printf "    %-38s  [%s]\n" "${cat}/${name}" "${budget:-?}"
        done
      else
        find "$cat_dir" -maxdepth 1 -name "*.md" ! -name "README.md" | sort | while read -r f; do
          local name budget
          name="$(basename "$f" .md)"
          budget="$(frontmatter_field "$f" "context_budget" 2>/dev/null || echo "?")"
          printf "    %-38s  [%s]\n" "${cat}/${name}" "${budget:-?}"
        done
      fi
    done
  fi
}

# ---------------------------------------------------------------------------
# Fetch a prompt
# ---------------------------------------------------------------------------
cmd_prompt() {
  local target="$1" raw="${RAW:-0}" base
  base="$(resolve_base)"

  local file="${base}/${PROMPTS_DIR}/${target}.md"
  [[ -f "$file" ]] || error "Prompt not found: ${target}\nLooked in: $file"

  local budget interfaces
  budget="$(frontmatter_field "$file" "context_budget")"
  interfaces="$(frontmatter_field "$file" "interfaces")"

  info "Prompt:    ${BOLD}${target}${RESET}"
  [[ -n "$budget" ]]     && info "Budget:    ${budget}"
  [[ -n "$interfaces" ]] && info "Interfaces: ${interfaces}"

  if [[ "$raw" == "1" ]]; then
    cat "$file"
  else
    strip_frontmatter < "$file"
  fi
}

# ---------------------------------------------------------------------------
# Fetch a skill
# ---------------------------------------------------------------------------
cmd_skill() {
  local target="$1" raw="${RAW:-0}" base
  base="$(resolve_base)"

  local skill_dir="${base}/${SKILLS_DIR}/${target}"
  local file="${skill_dir}/SKILL.md"
  [[ -f "$file" ]] || error "Skill not found: ${target}\nLooked in: $file"

  local budget interfaces
  budget="$(frontmatter_field "$file" "context-budget")"
  interfaces="$(frontmatter_field "$file" "interfaces")"

  info "Skill:     ${BOLD}${target}${RESET}"
  [[ -n "$budget" ]]     && info "Budget:    ${budget}"
  [[ -n "$interfaces" ]] && info "Interfaces: ${interfaces}"

  if [[ "$raw" == "1" ]]; then
    cat "$file"
  else
    strip_frontmatter < "$file"
  fi
}

# ---------------------------------------------------------------------------
# Copy prompt or skill to clipboard
# ---------------------------------------------------------------------------
cmd_copy() {
  local target="$1" mode="${2:-prompt}"
  local tool
  tool="$(clipboard_tool)"
  [[ -n "$tool" ]] || error "No clipboard tool found (tried pbcopy, xclip, xsel, clip)."

  local content
  if [[ "$mode" == "skill" ]]; then
    content="$(RAW=0 cmd_skill "$target" 2>/dev/null)"
  else
    content="$(RAW=0 cmd_prompt "$target" 2>/dev/null)"
  fi

  echo "$content" | eval "$tool"
  ok "Copied to clipboard: ${target}"
}

# ---------------------------------------------------------------------------
# Install a skill directory into .agents/skills/
# ---------------------------------------------------------------------------
cmd_install_skill() {
  local target="$1" base dest_dir skill_name
  base="$(resolve_base)"
  skill_name="$(basename "$target")"

  local skill_dir="${base}/${SKILLS_DIR}/${target}"
  [[ -d "$skill_dir" ]] || error "Skill directory not found: ${target}\nLooked in: $skill_dir"

  # Find the project root (where .git lives) or use cwd
  local project_root="$PWD"
  while [[ "$project_root" != "/" && ! -d "$project_root/.git" ]]; do
    project_root="$(dirname "$project_root")"
  done
  [[ -d "$project_root/.git" ]] || project_root="$PWD"

  dest_dir="${project_root}/${AGENTS_SKILLS_DIR}"
  mkdir -p "$dest_dir"

  local dest="${dest_dir}/${skill_name}"
  if [[ -d "$dest" ]]; then
    warn "Skill already exists at: $dest"
    read -r -p "Overwrite? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }
    rm -rf "$dest"
  fi

  cp -r "$skill_dir" "$dest"
  ok "Installed: ${dest}"
  info "Location: ${dest}/SKILL.md"
  info "Fill in references/patterns.md and references/conventions.md for your project."
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
MODE="prompt"
RAW=0
QUIET=0
COPY=0
LIST=0
INSTALL=0
BASE_OVERRIDE=""
REMOTE_URL=""
ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)        usage ;;
    -q|--quiet)       QUIET=1; shift ;;
    --raw)            RAW=1; shift ;;
    --no-strip)       RAW=1; shift ;;
    --strip)          RAW=0; shift ;;
    --skill)          MODE="skill"; shift ;;
    --copy)           COPY=1; shift ;;
    --list)           LIST=1; shift ;;
    --install-skill)  INSTALL=1; MODE="skill"; shift ;;
    --base)           BASE_OVERRIDE="$2"; shift 2 ;;
    --remote)         REMOTE_URL="$2"; shift 2 ;;
    --*)              error "Unknown option: $1" ;;
    *)                ARGS+=("$1"); shift ;;
  esac
done

export QUIET RAW BASE_OVERRIDE

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
if [[ "$LIST" == "1" ]]; then
  skill_mode=0; [[ "$MODE" == "skill" ]] && skill_mode=1
  cmd_list "$skill_mode" "${ARGS[0]:-}"
  exit 0
fi

[[ ${#ARGS[@]} -gt 0 ]] || { usage; }
TARGET="${ARGS[0]}"

# Remote fetch — outputs raw file content and exits
if [[ -n "$REMOTE_URL" ]]; then
  if [[ "$MODE" == "skill" ]]; then
    fetch_remote "$REMOTE_URL" "${SKILLS_DIR}/${TARGET}/SKILL.md"
  else
    fetch_remote "$REMOTE_URL" "${PROMPTS_DIR}/${TARGET}.md"
  fi
  exit 0
fi

if [[ "$INSTALL" == "1" ]]; then
  cmd_install_skill "$TARGET"
elif [[ "$COPY" == "1" ]]; then
  cmd_copy "$TARGET" "$MODE"
elif [[ "$MODE" == "skill" ]]; then
  cmd_skill "$TARGET"
else
  cmd_prompt "$TARGET"
fi