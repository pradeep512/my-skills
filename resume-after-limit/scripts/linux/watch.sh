#!/usr/bin/env bash
set -uo pipefail
# Linux — fired by the systemd timer / at job. Fresh unattended Claude, Codex
# fallback, then cleans up its own transient unit. Args: <project_dir> <handoff> [model]
# NOTE: written but not yet verified on a live Linux box.
HERE="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.claude/resume-after-limit"
PROMPT_TMPL="$HERE/../continue-prompt.md"
UNIT="claude-resume-after-limit"
mkdir -p "$STATE_DIR"

project_dir="${1:?}"; handoff="${2:?}"; model="${3:-claude-opus-4-8}"
ts=$(date +%Y%m%d-%H%M%S); log="$STATE_DIR/run-$ts.log"
exec > >(tee -a "$log") 2>&1

echo "=== resume-after-limit fired $(date) ==="
cd "$project_dir" || { echo "FATAL: cannot cd $project_dir"; exit 1; }
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)
prompt=$(sed -e "s|{{HANDOFF}}|$handoff|g" -e "s|{{BRANCH}}|$branch|g" "$PROMPT_TMPL")
is_limited() { grep -qiE 'rate.?limit|usage limit|exceeded your|Overloaded|\b429\b' "$1" 2>/dev/null; }

# keep-awake wrapper if available (no-op otherwise)
awake() { if command -v systemd-inhibit >/dev/null 2>&1; then
  systemd-inhibit --what=sleep:idle --why="claude resume" "$@"; else "$@"; fi; }

success=0; engine=none
for attempt in 1 2 3 4 5 6; do
  echo "--- claude attempt $attempt ($(date)) ---"
  err="$STATE_DIR/claude-err-$ts-$attempt.log"
  awake claude -p --dangerously-skip-permissions --model "$model" "$prompt" 2> "$err"
  rc=$?; cat "$err" >&2 || true
  if [ $rc -eq 0 ]; then success=1; engine=claude; break; fi
  if is_limited "$err"; then echo "still limited (rc=$rc); back off 5m"; sleep 300; continue; fi
  echo "claude failed rc=$rc (not a limit); go to fallback"; break
done

if [ $success -eq 0 ] && command -v codex >/dev/null 2>&1; then
  echo "--- codex fallback ($(date)) ---"
  awake codex exec --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check "$prompt" \
    && { success=1; engine=codex; } || echo "codex fallback failed rc=$?"
fi

printf '{"finished_at":%s,"success":%s,"engine":"%s","branch":"%s","log":"%s"}\n' \
  "$(date +%s)" "$success" "$engine" "$branch" "$log" > "$STATE_DIR/last-run.json"
command -v notify-send >/dev/null 2>&1 && \
  notify-send "Claude resume-after-limit" "finished — success=${success}, engine=${engine}" 2>/dev/null || true

echo "=== done (success=$success, engine=$engine); cleaning up unit ==="
# Transient on-calendar units are GC'd after firing; reset-failed to be tidy.
# `at` jobs are consumed on run, nothing to remove.
systemctl --user reset-failed "${UNIT}"* 2>/dev/null || true
