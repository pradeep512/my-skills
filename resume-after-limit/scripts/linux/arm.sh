#!/usr/bin/env bash
set -euo pipefail
# Linux — arm a one-shot job to resume after the 5h limit resets.
# Prefers a transient systemd --user timer; falls back to `at`.
# Usage: arm.sh <project_dir> <handoff> [model] [fire_epoch]
# NOTE: written but not yet verified on a live Linux box — sanity-check first run.
HERE="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.claude/resume-after-limit"
CACHE="$HOME/.claude/rate-limit-cache.json"
UNIT="claude-resume-after-limit"
BUFFER=${RESUME_BUFFER_SECONDS:-150}

project_dir="${1:?usage: arm.sh <project_dir> <handoff> [model] [fire_epoch]}"
handoff="${2:?usage: arm.sh <project_dir> <handoff> [model] [fire_epoch]}"
model="${3:-claude-opus-4-8}"
fire_arg="${4:-}"

project_dir="$(cd "$project_dir" && pwd)"
[ -f "$handoff" ] || { echo "handoff not found: $handoff" >&2; exit 1; }
handoff="$(cd "$(dirname "$handoff")" && pwd)/$(basename "$handoff")"
mkdir -p "$STATE_DIR"

now=$(date +%s)
if [ -n "$fire_arg" ]; then
  fire="$fire_arg"
elif [ -f "$CACHE" ] && command -v jq >/dev/null 2>&1; then
  r=$(jq -r '.five_hour.resets_at // empty' "$CACHE")
  [ -n "$r" ] && [ "$r" != null ] || { echo "cache has no five_hour.resets_at; pass fire_epoch (4th arg)." >&2; exit 1; }
  fire=$(( r + BUFFER ))
else
  echo "No reset time: no cache at $CACHE and no fire_epoch arg. Pass epoch seconds as the 4th arg." >&2; exit 1
fi
[ "$fire" -le "$now" ] && fire=$(( now + 60 ))
cal=$(date -d "@$fire" "+%Y-%m-%d %H:%M:%S")

if command -v systemd-run >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user stop "${UNIT}.timer" 2>/dev/null || true
  systemctl --user reset-failed "${UNIT}"* 2>/dev/null || true
  systemd-run --user --unit="$UNIT" --on-calendar="$cal" --timer-property=AccuracySec=2s \
    --setenv=PATH="$PATH" \
    /bin/bash "$HERE/watch.sh" "$project_dir" "$handoff" "$model"
  method="systemd-run"
elif command -v at >/dev/null 2>&1; then
  printf "/bin/bash %q %q %q %q\n" "$HERE/watch.sh" "$project_dir" "$handoff" "$model" \
    | at -t "$(date -d "@$fire" +%Y%m%d%H%M.%S)"
  method="at"
else
  echo "Need systemd-run (user session) or 'at' on PATH." >&2; exit 1
fi

printf '{"os":"linux","method":"%s","armed_at":%s,"fire_at":%s,"fire_human":"%s","project_dir":"%s","handoff":"%s","model":"%s"}\n' \
  "$method" "$now" "$fire" "$cal" "$project_dir" "$handoff" "$model" > "$STATE_DIR/armed.json"
echo "Armed (Linux/$method). Fires: $cal  (epoch $fire)"
echo "  project=$project_dir  handoff=$handoff  model=$model"
echo "Disarm: bash ${HERE}/disarm.sh"
