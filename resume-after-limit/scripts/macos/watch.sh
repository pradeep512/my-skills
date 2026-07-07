#!/usr/bin/env bash
set -uo pipefail
# macOS — fired by launchd at the reset. Boots a fresh unattended Claude,
# Codex fallback, then removes its own LaunchAgent (one-shot).
# Args: <project_dir> <handoff> [model]
HERE="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$HOME/.claude/resume-after-limit"
PLIST="$HOME/Library/LaunchAgents/com.claude.resume-after-limit.plist"
PROMPT_TMPL="$HERE/../continue-prompt.md"
mkdir -p "$STATE_DIR"

project_dir="${1:?}"; handoff="${2:?}"; model="${3:-claude-opus-4-8}"
ts=$(date +%Y%m%d-%H%M%S); log="$STATE_DIR/run-$ts.log"
exec > >(tee -a "$log") 2>&1

echo "=== resume-after-limit fired $(date) ==="
cd "$project_dir" || { echo "FATAL: cannot cd $project_dir"; exit 1; }
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)
prompt=$(sed -e "s|{{HANDOFF}}|$handoff|g" -e "s|{{BRANCH}}|$branch|g" "$PROMPT_TMPL")
is_limited() { grep -qiE 'rate.?limit|usage limit|exceeded your|Overloaded|\b429\b' "$1" 2>/dev/null; }

success=0; engine=none
for attempt in 1 2 3 4 5 6; do
  echo "--- claude attempt $attempt ($(date)) ---"
  err="$STATE_DIR/claude-err-$ts-$attempt.log"
  caffeinate -i claude -p --dangerously-skip-permissions --model "$model" "$prompt" 2> "$err"
  rc=$?; cat "$err" >&2 || true
  if [ $rc -eq 0 ]; then success=1; engine=claude; break; fi
  if is_limited "$err"; then echo "still limited (rc=$rc); back off 5m"; sleep 300; continue; fi
  echo "claude failed rc=$rc (not a limit); go to fallback"; break
done

if [ $success -eq 0 ] && command -v codex >/dev/null 2>&1; then
  echo "--- codex fallback ($(date)) ---"
  caffeinate -i codex exec --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check "$prompt" \
    && { success=1; engine=codex; } || echo "codex fallback failed rc=$?"
fi

printf '{"finished_at":%s,"success":%s,"engine":"%s","branch":"%s","log":"%s"}\n' \
  "$(date +%s)" "$success" "$engine" "$branch" "$log" > "$STATE_DIR/last-run.json"
osascript -e "display notification \"resume finished — success=${success}, engine=${engine}\" with title \"Claude resume-after-limit\"" 2>/dev/null || true

# One-shot teardown — ORDER MATTERS. `launchctl remove` unloads THIS running job
# and can SIGTERM us mid-line, so echo + rm the plist FIRST, then unload by label
# (unload-by-path fails once the file is gone).
echo "=== done (success=$success, engine=$engine); removing LaunchAgent ==="
rm -f "$PLIST"
launchctl remove com.claude.resume-after-limit 2>/dev/null || true
