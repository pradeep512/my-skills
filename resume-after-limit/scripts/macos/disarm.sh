#!/usr/bin/env bash
set -uo pipefail
# macOS — cancel a pending resume-after-limit run.
PLIST="$HOME/Library/LaunchAgents/com.claude.resume-after-limit.plist"
STATE_DIR="$HOME/.claude/resume-after-limit"
rm -f "$PLIST"
launchctl remove com.claude.resume-after-limit 2>/dev/null || true
rm -f "$STATE_DIR/armed.json" 2>/dev/null || true
echo "Disarmed (macOS)."
