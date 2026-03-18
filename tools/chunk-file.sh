#!/usr/bin/env bash
# chunk-file.sh
#
# Split a file into context-window-friendly chunks for use with local or
# small-context AI models.
#
# Usage:
#   chunk-file.sh [options] <file>
#
# Options:
#   -s, --size <tokens>     Target chunk size in tokens (default: 1500)
#   -o, --overlap <tokens>  Overlap between chunks in tokens (default: 100)
#   -m, --mode <mode>       Chunking mode: lines|functions|sections|auto (default: auto)
#   -d, --output-dir <dir>  Output directory (default: same dir as input file)
#   -p, --prefix <str>      Output filename prefix (default: input filename stem)
#   -e, --ext <str>         Output file extension (default: same as input)
#       --dry-run           Show chunk plan without writing files
#       --stats             Show token estimates for the input file and exit
#   -q, --quiet             Suppress informational output
#   -h, --help              Show this help message
#
# Modes:
#   auto       Detect the best mode from file extension and content
#   lines      Split by line count (most universal)
#   functions  Split at function/class boundaries (code files)
#   sections   Split at markdown heading boundaries (docs, specs, notes)
#
# Token estimation:
#   This script estimates tokens using character count divided by 4, which is
#   a reasonable approximation for mixed code and prose. Actual token counts
#   vary by model tokenizer. When in doubt, use a smaller --size value.
#
# Examples:
#   chunk-file.sh src/utils.ts
#   chunk-file.sh --size 1000 --overlap 50 src/large-module.ts
#   chunk-file.sh --mode sections docs/architecture.md
#   chunk-file.sh --dry-run --stats src/utils.ts
#   chunk-file.sh --output-dir /tmp/chunks src/utils.ts

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
DEFAULT_CHUNK_TOKENS=1500
DEFAULT_OVERLAP_TOKENS=100
DEFAULT_MODE="auto"
CHARS_PER_TOKEN=4   # conservative approximation

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; CYAN=''; BOLD=''; RESET=''
fi

info()  { [[ "${QUIET:-0}" == "1" ]] || echo -e "${CYAN}${*}${RESET}" >&2; }
warn()  { echo -e "${YELLOW}warning: ${*}${RESET}" >&2; }
error() { echo -e "${RED}error: ${*}${RESET}" >&2; exit 1; }
ok()    { [[ "${QUIET:-0}" == "1" ]] || echo -e "${GREEN}${*}${RESET}" >&2; }

usage() {
  sed -n '/^# Usage:/,/^[^#]/{ /^#/{ s/^# \{0,1\}//; p }; /^[^#]/q }' "$0"
  exit 0
}

# ---------------------------------------------------------------------------
# Token estimation helpers
# ---------------------------------------------------------------------------
chars_to_tokens() { echo $(( ${1} / CHARS_PER_TOKEN )); }
tokens_to_chars() { echo $(( ${1} * CHARS_PER_TOKEN )); }
file_tokens()     { chars_to_tokens "$(wc -c < "$1")"; }
line_tokens()     { chars_to_tokens "$(echo "$1" | wc -c)"; }

# ---------------------------------------------------------------------------
# Detect chunking mode from file extension
# ---------------------------------------------------------------------------
detect_mode() {
  local file="$1"
  local ext="${file##*.}"
  case "$ext" in
    ts|tsx|js|jsx|mjs|cjs|py|rb|go|rs|java|c|cpp|h|cs|swift|kt|php)
      echo "functions" ;;
    md|mdx|rst|txt|adoc)
      echo "sections" ;;
    *)
      echo "lines" ;;
  esac
}

# ---------------------------------------------------------------------------
# Show stats and exit
# ---------------------------------------------------------------------------
cmd_stats() {
  local file="$1"
  local chars lines tokens mode
  chars="$(wc -c < "$file")"
  lines="$(wc -l < "$file")"
  tokens="$(chars_to_tokens "$chars")"
  mode="$(detect_mode "$file")"

  echo -e "${BOLD}File:${RESET}   $file"
  echo -e "${BOLD}Lines:${RESET}  $lines"
  echo -e "${BOLD}Chars:${RESET}  $chars"
  echo -e "${BOLD}Tokens:${RESET} ~${tokens} (estimated)"
  echo -e "${BOLD}Mode:${RESET}   $mode (auto-detected)"

  local chunk_tokens="${CHUNK_TOKENS:-$DEFAULT_CHUNK_TOKENS}"
  local n_chunks=$(( (tokens + chunk_tokens - 1) / chunk_tokens ))
  echo -e "${BOLD}Chunks:${RESET} ~${n_chunks} at ${chunk_tokens} tokens each"
}

# ---------------------------------------------------------------------------
# Write a chunk to a file or stdout (dry-run)
# ---------------------------------------------------------------------------
write_chunk() {
  local content="$1" outfile="$2" chunk_num="$3" total="$4"
  local tokens
  tokens="$(chars_to_tokens "$(echo -n "$content" | wc -c)")"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    info "  Chunk ${chunk_num}/${total}: ~${tokens} tokens → ${outfile}"
  else
    mkdir -p "$(dirname "$outfile")"
    printf '%s' "$content" > "$outfile"
    ok "  Wrote chunk ${chunk_num}/${total}: ~${tokens} tokens → ${outfile}"
  fi
}

# ---------------------------------------------------------------------------
# Chunking: lines mode
# ---------------------------------------------------------------------------
chunk_by_lines() {
  local file="$1" out_dir="$2" prefix="$3" ext="$4"
  local chunk_chars overlap_chars
  chunk_chars="$(tokens_to_chars "$CHUNK_TOKENS")"
  overlap_chars="$(tokens_to_chars "$OVERLAP_TOKENS")"

  local chunk_num=1
  local buffer="" overlap_buffer=""
  local buffer_chars=0

  # Read file into array of lines
  mapfile -t lines < "$file"
  local total_lines="${#lines[@]}"

  # First pass: count how many chunks we'll produce
  local total_chunks=1 running=0
  for line in "${lines[@]}"; do
    running=$(( running + ${#line} + 1 ))
    if (( running >= chunk_chars )); then
      (( total_chunks++ )) || true
      running=0
    fi
  done

  # Second pass: write chunks
  local i=0
  while (( i < total_lines )); do
    local line="${lines[$i]}"
    buffer+="${overlap_buffer}${line}"$'\n'
    buffer_chars=$(( buffer_chars + ${#overlap_buffer} + ${#line} + 1 ))
    overlap_buffer=""

    if (( buffer_chars >= chunk_chars )); then
      local outfile="${out_dir}/${prefix}.part-$(printf '%03d' $chunk_num)${ext}"
      write_chunk "$buffer" "$outfile" "$chunk_num" "$total_chunks"

      # Build overlap: last N chars of current buffer
      if (( overlap_chars > 0 )); then
        overlap_buffer="${buffer: -$overlap_chars}"
      fi

      buffer=""
      buffer_chars=0
      (( chunk_num++ )) || true
    fi
    (( i++ )) || true
  done

  # Write remaining content
  if [[ -n "$buffer" ]]; then
    local outfile="${out_dir}/${prefix}.part-$(printf '%03d' $chunk_num)${ext}"
    write_chunk "$buffer" "$outfile" "$chunk_num" "$total_chunks"
  fi

  echo "$chunk_num"
}

# ---------------------------------------------------------------------------
# Chunking: sections mode (markdown headings)
# ---------------------------------------------------------------------------
chunk_by_sections() {
  local file="$1" out_dir="$2" prefix="$3" ext="$4"
  local chunk_chars
  chunk_chars="$(tokens_to_chars "$CHUNK_TOKENS")"

  mapfile -t lines < "$file"
  local total_lines="${#lines[@]}"

  # Split at heading lines (# or ## etc.), accumulate into chunks
  local chunk_num=1 buffer="" buffer_chars=0 section_buffer=""

  flush_chunk() {
    if [[ -n "$buffer" ]]; then
      local outfile="${out_dir}/${prefix}.part-$(printf '%03d' $chunk_num)${ext}"
      local total_chars
      total_chars="$(echo -n "$buffer" | wc -c)"
      write_chunk "$buffer" "$outfile" "$chunk_num" "?"
      (( chunk_num++ )) || true
      buffer="" buffer_chars=0
    fi
  }

  local i=0
  while (( i < total_lines )); do
    local line="${lines[$i]}"
    local is_heading=0
    [[ "$line" =~ ^#{1,6}\  ]] && is_heading=1

    # If this line starts a new heading and current buffer is big enough, flush
    if (( is_heading && buffer_chars > 0 && buffer_chars + ${#line} >= chunk_chars )); then
      flush_chunk
    fi

    buffer+="${line}"$'\n'
    buffer_chars=$(( buffer_chars + ${#line} + 1 ))

    # Also flush if we've exceeded chunk size even within a section
    if (( buffer_chars >= chunk_chars * 2 )); then
      flush_chunk
    fi

    (( i++ )) || true
  done

  flush_chunk
  echo $(( chunk_num - 1 ))
}

# ---------------------------------------------------------------------------
# Chunking: functions mode (language-aware boundary detection)
# ---------------------------------------------------------------------------
chunk_by_functions() {
  local file="$1" out_dir="$2" prefix="$3" ext="$4"
  local chunk_chars
  chunk_chars="$(tokens_to_chars "$CHUNK_TOKENS")"

  # Detect function/class start patterns by extension
  local file_ext="${file##*.}"
  local boundary_pattern
  case "$file_ext" in
    ts|tsx|js|jsx|mjs|cjs)
      boundary_pattern='^(export |async )?(function |class |const [a-zA-Z].*=.*=>|const [a-zA-Z].*= function)' ;;
    py)
      boundary_pattern='^(def |class |async def )' ;;
    go)
      boundary_pattern='^func ' ;;
    rb)
      boundary_pattern='^(def |class |module )' ;;
    rs)
      boundary_pattern='^(pub |async )?(fn |struct |impl |enum |trait )' ;;
    java|cs|kotlin|kt)
      boundary_pattern='^\s*(public|private|protected|static|override).*\{$' ;;
    *)
      # Fall back to lines mode for unknown types
      warn "No function boundary pattern for .${file_ext} — falling back to lines mode"
      chunk_by_lines "$file" "$out_dir" "$prefix" "$ext"
      return
      ;;
  esac

  mapfile -t lines < "$file"
  local total_lines="${#lines[@]}"
  local chunk_num=1 buffer="" buffer_chars=0

  local i=0
  while (( i < total_lines )); do
    local line="${lines[$i]}"
    local is_boundary=0
    [[ "$line" =~ $boundary_pattern ]] && is_boundary=1

    # Flush if we hit a boundary and buffer is large enough
    if (( is_boundary && buffer_chars >= chunk_chars )); then
      local outfile="${out_dir}/${prefix}.part-$(printf '%03d' $chunk_num)${ext}"
      write_chunk "$buffer" "$outfile" "$chunk_num" "?"
      (( chunk_num++ )) || true
      buffer="" buffer_chars=0
    fi

    buffer+="${line}"$'\n'
    buffer_chars=$(( buffer_chars + ${#line} + 1 ))
    (( i++ )) || true
  done

  # Write remainder
  if [[ -n "$buffer" ]]; then
    local outfile="${out_dir}/${prefix}.part-$(printf '%03d' $chunk_num)${ext}"
    write_chunk "$buffer" "$outfile" "$chunk_num" "$chunk_num"
  fi

  echo $(( chunk_num ))
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
CHUNK_TOKENS="$DEFAULT_CHUNK_TOKENS"
OVERLAP_TOKENS="$DEFAULT_OVERLAP_TOKENS"
MODE="$DEFAULT_MODE"
OUTPUT_DIR=""
OUTPUT_PREFIX=""
OUTPUT_EXT=""
DRY_RUN=0
STATS_ONLY=0
QUIET=0
FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)         usage ;;
    -s|--size)         CHUNK_TOKENS="$2"; shift 2 ;;
    -o|--overlap)      OVERLAP_TOKENS="$2"; shift 2 ;;
    -m|--mode)         MODE="$2"; shift 2 ;;
    -d|--output-dir)   OUTPUT_DIR="$2"; shift 2 ;;
    -p|--prefix)       OUTPUT_PREFIX="$2"; shift 2 ;;
    -e|--ext)          OUTPUT_EXT="$2"; shift 2 ;;
    --dry-run)         DRY_RUN=1; shift ;;
    --stats)           STATS_ONLY=1; shift ;;
    -q|--quiet)        QUIET=1; shift ;;
    --*)               error "Unknown option: $1" ;;
    *)                 FILE="$1"; shift ;;
  esac
done

export QUIET DRY_RUN CHUNK_TOKENS OVERLAP_TOKENS

[[ -n "$FILE" ]] || error "No input file specified. Usage: chunk-file.sh [options] <file>"
[[ -f "$FILE" ]] || error "File not found: $FILE"

# Derive output defaults from input file
FILE_DIR="$(dirname "$FILE")"
FILE_BASE="$(basename "$FILE")"
FILE_STEM="${FILE_BASE%.*}"
FILE_EXT_DETECTED=".${FILE_BASE##*.}"
[[ "$FILE_BASE" == "$FILE_STEM" ]] && FILE_EXT_DETECTED=""  # no extension

OUT_DIR="${OUTPUT_DIR:-$FILE_DIR}"
PREFIX="${OUTPUT_PREFIX:-$FILE_STEM}"
EXT="${OUTPUT_EXT:-$FILE_EXT_DETECTED}"

# Resolve auto mode
[[ "$MODE" == "auto" ]] && MODE="$(detect_mode "$FILE")"

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
if [[ "$STATS_ONLY" == "1" ]]; then
  cmd_stats "$FILE"
  exit 0
fi

TOTAL_TOKENS="$(file_tokens "$FILE")"
info "File:   ${BOLD}${FILE}${RESET}"
info "Tokens: ~${TOTAL_TOKENS} (estimated)"
info "Mode:   ${MODE}"
info "Chunks: ~${CHUNK_TOKENS} tokens each, ${OVERLAP_TOKENS} overlap"
[[ "$DRY_RUN" == "1" ]] && info "${YELLOW}Dry run — no files will be written${RESET}"
echo >&2

if (( TOTAL_TOKENS <= CHUNK_TOKENS )); then
  warn "File is already within the chunk size limit (~${TOTAL_TOKENS} tokens ≤ ${CHUNK_TOKENS})."
  warn "No chunking needed. Use as-is."
  exit 0
fi

case "$MODE" in
  lines)     N="$(chunk_by_lines     "$FILE" "$OUT_DIR" "$PREFIX" "$EXT")" ;;
  sections)  N="$(chunk_by_sections  "$FILE" "$OUT_DIR" "$PREFIX" "$EXT")" ;;
  functions) N="$(chunk_by_functions "$FILE" "$OUT_DIR" "$PREFIX" "$EXT")" ;;
  *)         error "Unknown mode: $MODE. Use: lines, functions, sections, auto" ;;
esac

echo >&2
if [[ "$DRY_RUN" == "1" ]]; then
  info "Dry run complete. ${N} chunks would be written."
else
  ok "Done. ${N} chunks written to: ${OUT_DIR}/"
  info "Process each chunk with a prompt, then reassemble."
  info "See: prompts/agent-orchestration/summarize-for-handoff.md"
fi