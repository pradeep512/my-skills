---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work.

Save it into a `local-docs/handoff/` folder (do NOT use `mktemp`/`/tmp`). Locate an existing one with `find . -type d -path '*local-docs/handoff' | head -1`; if none exists, create `local-docs/handoff/` at the repo root.

Name the file `handoff-YYYY-MM-DD_HHMM-<short-descriptive-kebab-name>.md`, where the timestamp is the current local time from `date '+%Y-%m-%d_%H%M'` and the name is a concise summary of the state + the next step.

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
