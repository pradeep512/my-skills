#!/usr/bin/env bash
set -euo pipefail
# macOS — arm a one-shot launchd job to resume after the 5h limit resets.
# Usage: arm.sh <project_dir> <handoff> [model] [fire_epoch]
HERE="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.claude/resume-after-limit"
LA_DIR="$HOME/Library/LaunchAgents"
PLIST="$LA_DIR/com.claude.resume-after-limit.plist"
CACHE="$HOME/.claude/rate-limit-cache.json"
LABEL="com.claude.resume-after-limit"
BUFFER=${RESUME_BUFFER_SECONDS:-150}

project_dir="${1:?usage: arm.sh <project_dir> <handoff> [model] [fire_epoch]}"
handoff="${2:?usage: arm.sh <project_dir> <handoff> [model] [fire_epoch]}"
model="${3:-claude-opus-4-8}"
fire_arg="${4:-}"

project_dir="$(cd "$project_dir" && pwd)"
[ -f "$handoff" ] || { echo "handoff not found: $handoff" >&2; exit 1; }
handoff="$(cd "$(dirname "$handoff")" && pwd)/$(basename "$handoff")"
mkdir -p "$STATE_DIR" "$LA_DIR"

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

MON=$((10#$(date -r "$fire" +%m))); DAY=$((10#$(date -r "$fire" +%d)))
HOUR=$((10#$(date -r "$fire" +%H))); MIN=$((10#$(date -r "$fire" +%M)))
fire_human=$(date -r "$fire" "+%a %b %d %I:%M %p")

cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string><string>${HERE}/watch.sh</string>
    <string>${project_dir}</string><string>${handoff}</string><string>${model}</string>
  </array>
  <key>WorkingDirectory</key><string>${project_dir}</string>
  <key>RunAtLoad</key><false/>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Month</key><integer>${MON}</integer><key>Day</key><integer>${DAY}</integer>
    <key>Hour</key><integer>${HOUR}</integer><key>Minute</key><integer>${MIN}</integer>
  </dict>
  <key>EnvironmentVariables</key>
  <dict><key>PATH</key><string>${PATH}</string><key>HOME</key><string>${HOME}</string></dict>
  <key>StandardOutPath</key><string>${STATE_DIR}/launchd.out.log</string>
  <key>StandardErrorPath</key><string>${STATE_DIR}/launchd.err.log</string>
</dict>
</plist>
PL

launchctl unload "$PLIST" 2>/dev/null || true
launchctl load -w "$PLIST"
printf '{"os":"macos","armed_at":%s,"fire_at":%s,"fire_human":"%s","project_dir":"%s","handoff":"%s","model":"%s","plist":"%s"}\n' \
  "$now" "$fire" "$fire_human" "$project_dir" "$handoff" "$model" "$PLIST" > "$STATE_DIR/armed.json"
echo "Armed (macOS/launchd). Fires: ${fire_human}  (epoch ${fire})"
echo "  project=$project_dir  handoff=$handoff  model=$model"
echo "Disarm: bash ${HERE}/disarm.sh"
