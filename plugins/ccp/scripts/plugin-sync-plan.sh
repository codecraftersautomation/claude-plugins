#!/usr/bin/env bash
# plugin-sync-plan.sh
#
# Compare what each profile has and produce a *reviewable* plan plus two
# generated install scripts — one per profile. Nothing is executed here. The
# generated scripts are made executable for convenience but are designed to be
# read first; high-risk installs are commented out by default so applying the
# script blindly can't silently pull in hooks/MCP/LSP/shell behavior.
#
# Inputs:
#   .claude/ccp/plugins/team-plugins.txt
#   .claude/ccp/plugins/max-plugins.txt
#   .claude/ccp/plugins/PLUGINS.lock.json   (optional, enriches risk/marketplace)
# Outputs:
#   .claude/ccp/plugins/PLUGIN_SYNC_PLAN.md
#   .claude/ccp/plugins/install-missing-team.sh
#   .claude/ccp/plugins/install-missing-max.sh
#
# A timestamp is required for the generated headers but this environment may not
# allow `date`; we degrade gracefully to "unknown" rather than failing.

set -uo pipefail

OUT_DIR=".claude/ccp/plugins"
TEAM_RAW="$OUT_DIR/team-plugins.txt"
MAX_RAW="$OUT_DIR/max-plugins.txt"
LOCK="$OUT_DIR/PLUGINS.lock.json"
PLAN="$OUT_DIR/PLUGIN_SYNC_PLAN.md"
TEAM_SCRIPT="$OUT_DIR/install-missing-team.sh"
MAX_SCRIPT="$OUT_DIR/install-missing-max.sh"

mkdir -p "$OUT_DIR"

if [[ ! -f "$TEAM_RAW" && ! -f "$MAX_RAW" ]]; then
  echo "No inventory files found. Run /ccp:plugin-inventory first." >&2
  exit 1
fi

GEN_DATE="$(date '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || echo 'unknown')"

extract_names() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  grep -Ev '^\s*#' "$f" | grep -Ev '^\s*$' \
    | sed -E 's/^[[:space:]]*[-*•][[:space:]]+//' \
    | awk '{print $1}' \
    | grep -Ev '^(No|Plugins?|NAME|Name|Available|Installed|----|===)' \
    | sed -E 's/[:,]+$//' | sort -u
}

TEAM_NAMES="$(extract_names "$TEAM_RAW")"
MAX_NAMES="$(extract_names "$MAX_RAW")"

# Plugins present in the OTHER profile but missing here = install candidates.
missing_in_team="$(comm -13 <(printf '%s\n' "$TEAM_NAMES") <(printf '%s\n' "$MAX_NAMES") 2>/dev/null | sed '/^$/d')"
missing_in_max="$(comm -23 <(printf '%s\n' "$TEAM_NAMES") <(printf '%s\n' "$MAX_NAMES") 2>/dev/null | sed '/^$/d')"

# Look up marketplace + risk for a plugin name from the lock file (best-effort,
# grep-based so we don't depend on jq). Sets globals MP and RISK.
lookup() {
  local name="$1"
  MP="unknown"; RISK="unknown"
  [[ -f "$LOCK" ]] || return 0
  # Find the record block for this name and read its marketplace/risk.
  local block
  block="$(awk -v n="\"name\": \"$name\"" '
    $0 ~ n {found=1}
    found {print}
    found && /}/ {exit}
  ' "$LOCK" 2>/dev/null)"
  [[ -z "$block" ]] && return 0
  MP="$(printf '%s' "$block" | grep -E '"marketplace"' | head -1 | sed -E 's/.*"marketplace": "([^"]*)".*/\1/')"
  RISK="$(printf '%s' "$block" | grep -E '"risk"' | head -1 | sed -E 's/.*"risk": "([^"]*)".*/\1/')"
  [[ -z "$MP" ]] && MP="unknown"
  [[ -z "$RISK" ]] && RISK="unknown"
}

# Generate one install script for a target profile.
#   $1 = launcher (claude-team|claude-max)
#   $2 = profile label (team|max)
#   $3 = newline-separated plugin names to install
#   $4 = output path
generate_script() {
  local launcher="$1" label="$2" names="$3" path="$4"
  {
    echo '#!/usr/bin/env bash'
    echo '# CCP generated install script — REVIEW BEFORE RUNNING.'
    echo '#'
    echo "# Target profile : $label ($launcher)"
    echo "# Generated date : $GEN_DATE"
    echo "# Source lock    : $LOCK"
    echo '#'
    echo '# This script is NOT auto-executed. High-risk plugins (hooks, MCP servers,'
    echo '# LSP servers, shell-executing, local-path, or unknown source) are commented'
    echo '# out and require manual review. Plugins with an unknown marketplace are'
    echo '# skipped entirely — CCP will not guess a marketplace name.'
    echo '#'
    echo '# Scope guidance:'
    echo '#   --scope project  : repo-specific tooling (preferred for this repo)'
    echo '#   --scope user     : generic personal tools'
    echo '#   --scope local    : personal + repo-only'
    echo '# Adjust the --scope flags below to taste before running.'
    echo
    echo 'set -euo pipefail'
    echo
    if [[ -z "$names" ]]; then
      echo "echo 'Nothing to install for $label — profiles already aligned (per inventory).'"
      echo "exit 0"
    else
      while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        lookup "$name"
        echo "# --- plugin: $name ---"
        if [[ "$MP" == "unknown" || -z "$MP" ]]; then
          echo "# SKIPPED: marketplace unknown for '$name'. Install manually once you know its source:"
          echo "#   $launcher plugin install $name@<marketplace> --scope project"
          echo
          continue
        fi
        if [[ "$RISK" == "high" ]]; then
          echo "# REVIEW REQUIRED: '$name' appears to ship hooks / MCP / LSP / shell behavior."
          echo "# Inspect what it does, then uncomment to install:"
          echo "#   $launcher plugin install $name@$MP --scope project"
        else
          echo "# Low-risk install. Adjust scope if this is a generic personal tool (--scope user)."
          echo "$launcher plugin install $name@$MP --scope project"
        fi
        echo
      done <<< "$names"
      echo "echo 'Done. Now open Claude Code and run /reload-plugins.'"
    fi
  } > "$path"
  chmod +x "$path"
}

generate_script "claude-team" "team" "$missing_in_team" "$TEAM_SCRIPT"
generate_script "claude-max"  "max"  "$missing_in_max"  "$MAX_SCRIPT"

count() { printf '%s' "$1" | sed '/^$/d' | grep -c . || true; }

{
  echo "# PLUGIN SYNC PLAN"
  echo
  echo "_Generated by CCP. Review this and the two install scripts before applying anything._"
  echo
  echo "- Generated date: $GEN_DATE"
  echo "- Source lock file: \`$LOCK\` $( [[ -f "$LOCK" ]] && echo '(present)' || echo '(absent — risk/marketplace will be \"unknown\")' )"
  echo
  echo "## Plugins to add to Team (present in Max, missing in Team)"
  echo
  if [[ -n "$missing_in_team" ]]; then printf '%s\n' "$missing_in_team" | sed 's/^/- /'; else echo "- (none)"; fi
  echo
  echo "## Plugins to add to Max (present in Team, missing in Max)"
  echo
  if [[ -n "$missing_in_max" ]]; then printf '%s\n' "$missing_in_max" | sed 's/^/- /'; else echo "- (none)"; fi
  echo
  echo "## Generated install scripts"
  echo
  echo "- \`install-missing-team.sh\` — $(count "$missing_in_team") candidate(s) for Team"
  echo "- \`install-missing-max.sh\`  — $(count "$missing_in_max") candidate(s) for Max"
  echo
  echo "Both scripts:"
  echo "- start with \`set -euo pipefail\`"
  echo "- are executable but are **not** run automatically"
  echo "- skip plugins with unknown marketplace (no guessing)"
  echo "- comment out high-risk plugins (hooks / MCP / LSP / shell / local / unknown source)"
  echo
  echo "## Scope recommendations"
  echo
  echo "- **Project scope** for repo-specific plugins: \`claude plugin install <plugin>@<marketplace> --scope project\`"
  echo "- **User scope** for generic personal tools."
  echo "- **Local scope** for personal, repo-only tools."
  echo "- **Managed scope** is controlled by your organization and cannot be changed by CCP."
  echo
  echo "## Next step"
  echo
  echo "Review the scripts, then run \`/ccp:plugin-apply\` and choose a target profile."
  echo
  echo "---"
  echo "_No plugins were installed. CCP is review-first, apply-second._"
} > "$PLAN"

echo "Wrote sync plan and install scripts to $OUT_DIR/"
echo "  - PLUGIN_SYNC_PLAN.md"
echo "  - install-missing-team.sh"
echo "  - install-missing-max.sh"
