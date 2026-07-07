A previous Claude Code session in this repo was interrupted when the 5-hour rate
limit was hit. The limit has now reset and you are a FRESH session launched
automatically to continue that work UNATTENDED. No human is watching, so you
cannot ask questions — make sensible, conservative decisions and keep going.

## First, load context
1. Read the continuation handoff: {{HANDOFF}}  ← your primary brief; it names the
   task queue, the branch, and any project-specific commands.
2. Run `git log -n 8 --oneline` and `git status` to see recent work + tree state.
3. If the handoff points at an issue tracker, list the open, ready-to-work items.
4. You are on branch `{{BRANCH}}`. Do NOT switch branches. All commits go here.

## The build loop (one task at a time)
1. Pick the single highest-priority UNBLOCKED task from the handoff / queue.
   Priority: critical bugfix > dev infra (tests/types/scripts) > tracer-bullet
   feature slice > polish/quick win > refactor. Honour any "blocked by" markers.
2. Explore the relevant code before writing anything.
3. Implement the smallest end-to-end vertical slice first, then expand. Prefer a
   test-first (/tdd) flow where the project supports it.
4. Run the project's feedback loops for whatever you touched, and fix failures
   before committing — build, tests, type-check, lint, as appropriate for the
   stack. The handoff or the repo's docs/CI config name the exact commands; if
   unclear, infer them from the project (package.json scripts, Makefile, go/npm/
   cargo/etc.) rather than skipping verification.
5. Commit locally on `{{BRANCH}}`. The message must capture: key decisions, files
   changed, and blockers/notes for the next iteration.
6. If there is an issue for this task, comment on it with what was done — do NOT
   close it.
7. Move to the next task and repeat until the queue is empty or you sense the rate
   limit is near again.

## Guardrails (unattended — non-negotiable)
- Commit locally ONLY, on the current branch. Never `git push`, never force-push,
  never open or merge a PR, never rebase shared history.
- Only comment on issues in the user's own fork/tracker — never change issue state,
  never touch an upstream repo.
- If a task is ambiguous, risky, or needs a human decision, leave a detailed note
  (issue comment or in the handoff) and SKIP it rather than guess destructively.
- Do not delete or overwrite files you did not create without strong justification
  recorded in the commit message.

## Before you finish
Write an updated handoff back to {{HANDOFF}} (what got done, what's next, any new
blockers) so the next session — human or automated — can pick up cleanly. When
there is genuinely no remaining ready-to-work task, stop and say so plainly.
