#!/usr/bin/env bash
# plugin-export.sh
#
# Turn the captured plugin inventory into a repo-local lock file that describes
# the *desired* plugin set: .claude/ccp/plugins/PLUGINS.lock.json
#
# Parsing `plugin list` output is best-effort because the format varies by
# Claude Code version. The rule of this script: never guess. If a field can't
# be determined confidently, emit "unknown" (or false-ish) and preserve the
# original line under "raw" so a human or the /ccp:plugin-export skill can
# refine it. We never fabricate marketplace names and never write secrets.
#
# Inputs (must exist; run /ccp:plugin-inventory first):
#   .claude/ccp/plugins/team-plugins.txt
#   .claude/ccp/plugins/max-plugins.txt
# Output:
#   .claude/ccp/plugins/PLUGINS.lock.json

set -uo pipefail

OUT_DIR=".claude/ccp/plugins"
TEAM_RAW="$OUT_DIR/team-plugins.txt"
MAX_RAW="$OUT_DIR/max-plugins.txt"
LOCK="$OUT_DIR/PLUGINS.lock.json"

mkdir -p "$OUT_DIR"

if [[ ! -f "$TEAM_RAW" && ! -f "$MAX_RAW" ]]; then
  echo "No inventory files found. Run /ccp:plugin-inventory first." >&2
  exit 1
fi

# JSON string escaper (handles backslash, quote, tab, newline).
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

# Heuristic risk classification from a raw line. We flag anything that hints at
# hooks, MCP servers, LSP servers, or shell execution as elevated risk so the
# downstream sync plan defaults it to review-required.
classify_risk() {
  local line="$1"
  local low="$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')"
  if echo "$low" | grep -Eq 'hook|mcp|lsp|server|shell|exec|command'; then
    echo "high"
  else
    echo "low"
  fi
}

# Best-effort name + marketplace extraction. Recognizes the common
# "name@marketplace" form; otherwise marketplace is "unknown".
parse_name() { printf '%s' "$1" | sed -E 's/@.*$//'; }
parse_marketplace() {
  local tok="$1"
  if echo "$tok" | grep -q '@'; then
    printf '%s' "$tok" | sed -E 's/^[^@]*@//'
  else
    printf 'unknown'
  fi
}

# Emit one JSON record object for a given raw line and source profile.
emit_record() {
  local raw_line="$1"
  local source_profile="$2"
  local token name marketplace risk
  token="$(printf '%s' "$raw_line" \
            | sed -E 's/^[[:space:]]*[-*•][[:space:]]+//' \
            | awk '{print $1}' | sed -E 's/[:,]+$//')"
  [[ -z "$token" ]] && return 1
  # Skip obvious header/noise lines.
  echo "$token" | grep -Eq '^(No|Plugins?|NAME|Name|Available|Installed|----|===|#)' && return 1

  name="$(parse_name "$token")"
  marketplace="$(parse_marketplace "$token")"
  risk="$(classify_risk "$raw_line")"

  printf '    {\n'
  printf '      "name": "%s",\n' "$(json_escape "$name")"
  printf '      "marketplace": "%s",\n' "$(json_escape "$marketplace")"
  printf '      "version": "unknown",\n'
  printf '      "scope": "unknown",\n'
  printf '      "enabled": "unknown",\n'
  printf '      "source_profile": "%s",\n' "$source_profile"
  printf '      "components": {\n'
  printf '        "skills": "unknown",\n'
  printf '        "agents": "unknown",\n'
  printf '        "hooks": "unknown",\n'
  printf '        "mcp_servers": "unknown",\n'
  printf '        "lsp_servers": "unknown"\n'
  printf '      },\n'
  printf '      "risk": "%s",\n' "$risk"
  printf '      "raw": "%s"\n' "$(json_escape "$raw_line")"
  printf '    }'
}

# Collect candidate lines per profile.
collect_lines() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  grep -Ev '^\s*#' "$f" | grep -Ev '^\s*$'
}

# Build the records array. We dedupe by name+profile to avoid double entries.
records=()
seen=""

add_from_profile() {
  local file="$1" profile="$2"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local rec
    rec="$(emit_record "$line" "$profile")" || continue
    local key
    key="$(printf '%s' "$line" | awk '{print $1}')@$profile"
    case "$seen" in
      *"|$key|"*) continue ;;
    esac
    seen="$seen|$key|"
    records+=("$rec")
  done < <(collect_lines "$file")
}

add_from_profile "$TEAM_RAW" "team"
add_from_profile "$MAX_RAW" "max"

{
  printf '{\n'
  printf '  "ccp_lock_version": 1,\n'
  printf '  "note": "Desired plugin set for this repo. Best-effort; verify before applying. Contains no secrets.",\n'
  printf '  "plugins": [\n'
  for i in "${!records[@]}"; do
    printf '%s' "${records[$i]}"
    if [[ "$i" -lt $(( ${#records[@]} - 1 )) ]]; then printf ',\n'; else printf '\n'; fi
  done
  printf '  ]\n'
  printf '}\n'
} > "$LOCK"

echo "Wrote lock file: $LOCK (${#records[@]} record(s))"
echo "Review it, then run /ccp:plugin-sync-plan."
