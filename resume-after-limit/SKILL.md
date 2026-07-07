---
name: resume-after-limit
description: Continue interrupted work automatically after the Claude 5-hour rate limit resets, on macOS, Linux, or Windows, applying a proven unattended build-loop pattern. Use when the user hits or expects to hit the 5h usage limit, wants work to resume on its own after the reset, mentions "auto-resume", "continue after the limit", or "AFK after rate limit".
---

# resume-after-limit

Schedules a **one-shot job** that, once the 5-hour rate-limit window resets, boots
a **fresh unattended `claude` session** which reads a handoff and continues the
work using a proven build loop. Falls back to **Codex** if Claude is still limited
on wake. Cross-platform: a per-OS scheduler wraps one shared continuation prompt.

## Design (fixed decisions)

- **Fresh session + handoff** — not resume/fork. The watcher starts a clean
  `claude -p` in the project dir, pointed at a handoff you write first.
- **Commit-local-only, current branch** — runs builds/tests and commits where the
  repo is checked out; never pushes, never switches branch. Fenced by
  `scripts/continue-prompt.md`, not by the harness.
- **OS-native one-shot scheduler** that survives sleep (and, where possible, reboot):
  macOS `launchd`, Linux `systemd-run`/`at`, Windows Task Scheduler. Self-removes.
- **Claude → Codex fallback** with rate-limit back-off retries.

## Reset-time source

The job needs to know *when* to fire. Two ways:
1. **From the statusline cache** `~/.claude/rate-limit-cache.json` (key
   `.five_hour.resets_at`) if you tee it there — see [REFERENCE.md](REFERENCE.md#reset-time).
2. **Explicitly**, by passing a fire time to the arm script (epoch seconds on
   Unix, `-AtEpoch`/`-InSeconds` on Windows). Use this when the cache isn't set up.

## Arming (agent steps)

1. **Write a self-sufficient continuation handoff** capturing current task state:
   what was being built, the next unblocked task(s), the branch, blockers, and
   where the work queue lives. This is the ONLY context the fresh session gets.
2. **Detect the OS and run the matching arm script** from this skill's `scripts/`:

   - **macOS** — `bash scripts/macos/arm.sh <project_dir> <handoff> [model] [fire_epoch]`
   - **Linux** — `bash scripts/linux/arm.sh <project_dir> <handoff> [model] [fire_epoch]`
   - **Windows** — `pwsh scripts/windows/arm.ps1 -ProjectDir <..> -Handoff <..> [-Model <..>] [-AtEpoch <..>|-InSeconds <..>]`

   Omit the fire time to read it from the cache; pass it to override. Each script
   prints the exact fire time — confirm it back to the user.

## At fire time (automatic)

The per-OS `watch` script: `cd`s to the project, builds the prompt from
`scripts/continue-prompt.md` (injecting handoff path + branch), retries Claude with
back-off on rate-limit errors, falls back to Codex, writes `last-run.json` + a
desktop notification, then removes its own scheduled job (one-shot).

## Disarm / status

- macOS/Linux: `bash scripts/<os>/disarm.sh`
- Windows: `pwsh scripts/windows/disarm.ps1`
- State + logs: `~/.claude/resume-after-limit/` (`armed.json`, `last-run.json`, `run-*.log`)

## Notes

Unattended runs use `--dangerously-skip-permissions`. Platform support status
(macOS tested; Linux/Windows written but unverified), scheduler internals per OS,
the reset-time cache, and failure modes are in [REFERENCE.md](REFERENCE.md). The
build loop itself is [scripts/continue-prompt.md](scripts/continue-prompt.md) —
edit it to tune task priority or the feedback-loop commands for your project.
