---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work.

Save it into a `local-docs/handoff/` folder (do NOT use `mktemp`/`/tmp`). Locate an existing one with `find . -type d -path '*local-docs/handoff' | head -1`; if none exists, create `local-docs/handoff/` at the repo root.

Name the file `handoff-YYYY-MM-DD_HHMM-<short-descriptive-kebab-name>.md`, where the timestamp is the current local time from `date '+%Y-%m-%d_%H%M'` and the name is a concise summary of the state + the next step.

Suggest the skills to be used, if any, by the next session.

Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
