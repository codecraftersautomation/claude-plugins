#!/usr/bin/env bash
# plugin-apply.sh
#
# Apply a previously generated install script for ONE profile — but only when
# the user explicitly opts in with --yes. Without --yes it is a dry run: it
# prints exactly what would execute and stops. This is the "apply-second" half
# of CCP's review-first, apply-second model.
#
# Usage:
#   plugin-apply.sh team           # dry run: show team install script
#   plugin-apply.sh max            # dry run: show max install script
#   plugin-apply.sh team --yes     # actually run install-missing-team.sh
#   plugin-apply.sh max  --yes     # actually run install-missing-max.sh
#
# It never targets "both" itself — coordinate two separate runs so each profile
# is an explicit, reviewed decision.

set -uo pipefail

OUT_DIR=".claude/ccp/plugins"

usage() {
  echo "Usage: plugin-apply.sh <team|max> [--yes]" >&2
  exit 2
}

TARGET="${1:-}"
CONFIRM="${2:-}"

case "$TARGET" in
  team) SCRIPT="$OUT_DIR/install-missing-team.sh"; LABEL="Team (claude-team)" ;;
  max)  SCRIPT="$OUT_DIR/install-missing-max.sh";  LABEL="Max (claude-max)" ;;
  *)    usage ;;
esac

if [[ ! -f "$SCRIPT" ]]; then
  echo "Install script not found: $SCRIPT" >&2
  echo "Run /ccp:plugin-sync-plan first to generate it." >&2
  exit 1
fi

echo "=============================================================="
echo "CCP plugin-apply — target: $LABEL"
echo "Script: $SCRIPT"
echo "=============================================================="
echo
echo "The exact commands that would run are below. Lines starting with '#'"
echo "are comments (skipped / high-risk / review-required) and will NOT run:"
echo
echo "--------------------------------------------------------------"
cat "$SCRIPT"
echo "--------------------------------------------------------------"
echo

if [[ "$CONFIRM" != "--yes" ]]; then
  echo "DRY RUN ONLY. Nothing was executed."
  echo "Re-run with --yes to apply:"
  echo "    plugin-apply.sh $TARGET --yes"
  exit 0
fi

echo "Applying $LABEL install script..."
echo
bash "$SCRIPT"
status=$?
echo
if [[ "$status" -eq 0 ]]; then
  echo "Apply finished successfully."
  echo "Now open Claude Code and run /reload-plugins"
else
  echo "Install script exited with status $status. Review the output above." >&2
fi
exit "$status"
