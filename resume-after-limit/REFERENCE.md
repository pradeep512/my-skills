# resume-after-limit — reference

## Platform support status
| OS | Scheduler | Keep-awake | Notify | Status |
|----|-----------|-----------|--------|--------|
| macOS   | launchd (LaunchAgent, `StartCalendarInterval`) | `caffeinate -i` | `osascript` | **tested end-to-end** |
| Linux   | `systemd-run --user --on-calendar` (fallback `at`) | `systemd-inhibit` | `notify-send` | written, **unverified** |
| Windows | Task Scheduler (`Register-ScheduledTask`, one-time trigger) | `-WakeToRun` | `msg` | written, **unverified** |

Verify the Linux/Windows path on first real use. The shared, OS-agnostic parts
(SKILL.md, `scripts/continue-prompt.md`, the reset-time cache) work everywhere.

## Reset time
The job needs to know when the 5h window reopens. `.rate_limits.five_hour.resets_at`
is handed to Claude Code's **statusline command on stdin** and exposed nowhere else,
so persist it yourself. Add this near the top of your statusline script (after it
parses stdin into `$input`) to tee it to `~/.claude/rate-limit-cache.json`:

```bash
five_hour_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
five_hour_pct=$(echo    "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$five_hour_resets" ]; then
  printf '{"updated_at":%s,"five_hour":{"used_percentage":%s,"resets_at":%s}}\n' \
    "$(date +%s)" "${five_hour_pct:-null}" "$five_hour_resets" \
    > "$HOME/.claude/rate-limit-cache.json.tmp" && \
    mv -f "$HOME/.claude/rate-limit-cache.json.tmp" "$HOME/.claude/rate-limit-cache.json"
fi
```

If you don't set that up, pass the fire time explicitly instead: a Unix epoch as
the 4th arg to `arm.sh`, or `-AtEpoch`/`-InSeconds` to `arm.ps1`. `scripts/checklimit.sh`
(and `checklimit.ps1`) read the cache and print when each window resets.

## Why an OS-native scheduler (not a sleep loop)
A `sleep`-until-reset process pauses during system sleep and dies on reboot. Each
OS scheduler here fires at a wall-clock time and catches a firing missed during
sleep on the next wake — so a closed lid delays, it doesn't cancel:
- **launchd**: coalesces a missed `StartCalendarInterval` on wake; the plist
  survives reboot (removed after firing).
- **systemd `--on-calendar`**: realtime timer fires on resume if the moment
  elapsed during suspend. Transient units are in-memory, so they do **not** survive
  a full reboot — resume windows are <5h so this is rarely an issue; use the `at`
  fallback if you need reboot survival.
- **Task Scheduler**: `-StartWhenAvailable` runs a missed trigger on next wake;
  `-WakeToRun` can wake the machine. Survives reboot.

## Rate-limit re-check on wake
The cache is only fresh while a live statusline renders, so at fire time it is
stale. The watcher does **not** trust it — it just attempts the real Claude run and
treats a rate-limit error (stderr matching `rate limit | usage limit | exceeded
your | Overloaded | 429`) as "still capped", backing off 5 min and retrying up to
6× (~30 min slack for an early/estimated reset or a lingering longer-window cap),
then falls back to Codex.

## macOS teardown gotcha (fixed; keep it this way)
A launchd job must `rm` its own plist **before** `launchctl remove <label>` —
unloading the running job SIGTERMs it mid-line, so unload-then-rm leaves the plist
on disk to reload at next login. `macos/watch.sh` does echo → `rm` → `remove`
(by label, since the file is already gone). This was caught by a live dry run.

## PATH / auth in the scheduled environment
Schedulers run with a minimal environment. macOS/Linux arm scripts bake the current
`$PATH` (and `$HOME`) into the job so `claude`, `codex`, `git`, `jq`, `node` resolve;
Windows relies on the user PATH (prepend your npm-global dir in `watch.ps1` if
`claude` isn't found). Auth works because Claude Code, `gh`, and codex read
credentials under the home dir. Re-arm if you move those binaries.

## Security / trust model
Unattended runs use `--dangerously-skip-permissions` (Claude) /
`--dangerously-bypass-approvals-and-sandbox` (Codex) — a headless job cannot answer
permission prompts. The blast radius is fenced by `continue-prompt.md`, not the
harness: commit-local-only, current branch, no push, no PR, issue-comments only,
skip-on-ambiguity. If you don't trust a fully unattended run, don't arm it — drive
the continuation by hand from the handoff instead.

## State & files (all OSes)
`~/.claude/resume-after-limit/`: `armed.json` (what's scheduled), `last-run.json`
(last result), `run-<ts>.log` (transcript). macOS also writes `launchd.{out,err}.log`.

## Failure modes
- **"No reset time"** — no cache and no explicit fire arg. Set up the tee above, or
  pass the fire time.
- **Fires but Claude is still limited 6×** — reset estimate was off or a longer
  window is the real cap; it then tries Codex. Check `run-<ts>.log`.
- **Job never fires** — macOS: `launchctl list | grep resume`; Linux:
  `systemctl --user list-timers | grep resume`; Windows:
  `Get-ScheduledTask ClaudeResumeAfterLimit`. Check the clock/timezone.
- **Wrong branch on wake** — the watcher never switches branches; leave the repo on
  the intended branch before arming.
