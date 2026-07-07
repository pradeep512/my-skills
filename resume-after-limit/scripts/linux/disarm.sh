#!/usr/bin/env bash
set -uo pipefail
# Linux — cancel a pending resume-after-limit run (systemd timer or at job).
UNIT="claude-resume-after-limit"
STATE_DIR="$HOME/.claude/resume-after-limit"
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user stop "${UNIT}.timer" "${UNIT}.service" 2>/dev/null || true
  systemctl --user reset-failed "${UNIT}"* 2>/dev/null || true
fi
# Best-effort remove any queued `at` job that runs our watch.sh
if command -v atq >/dev/null 2>&1; then
  for j in $(atq | awk '{print $1}'); do
    at -c "$j" 2>/dev/null | grep -q "resume-after-limit/scripts/linux/watch.sh" && atrm "$j" 2>/dev/null || true
  done
fi
rm -f "$STATE_DIR/armed.json" 2>/dev/null || true
echo "Disarmed (Linux)."
