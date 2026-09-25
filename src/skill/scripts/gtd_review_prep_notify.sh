#!/usr/bin/env bash
# gtd_review_prep_notify.sh — run the read-only weekly review prep and notify locally.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/gtd_env.sh"
VAULT_ROOT="$GTD_WORKSPACE_ROOT"
REPORT="$VAULT_ROOT/memory/gtd-review-prep-latest.md"
LOG="$VAULT_ROOT/memory/gtd-review-prep-launchd.log"

{
  echo "# GTD Weekly Review Prep"
  echo ""
  echo "- Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "- Boundary: read-only scan; does not modify memory/gtd/, write to the calendar, send messages, or delete or move list items."
  echo ""
  "$SCRIPT_DIR/gtd_review_prep.sh"
} > "$REPORT"

{
  echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] wrote $REPORT"
} >> "$LOG"

if command -v osascript >/dev/null 2>&1; then
  osascript -e 'display notification "Review prep pack ready: memory/gtd-review-prep-latest.md" with title "GTD Weekly Review"' >/dev/null 2>&1 || true
fi
