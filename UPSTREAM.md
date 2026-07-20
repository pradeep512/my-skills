# Upstream provenance

Most skills in this repo were vendored (copied, not submoduled or symlinked) from
[mattpocock/skills](https://github.com/mattpocock/skills). This repo is the source of truth —
edit skills here freely.

## Last sync

- **Date:** 2026-07-20
- **Upstream commit:** `9603c1c` — "Merge pull request #586 from mattpocock/batch-grill-me-granular-facts"
- **Vendored:** all of `skills/engineering/*`, all of `skills/productivity/*`, and `skills/in-progress/batch-grill-me`

## Re-syncing later

Because these are copies, upstream fixes do not arrive via `git pull`. To pick them up:

```sh
git clone https://github.com/mattpocock/skills.git /tmp/upstream-skills
diff -ru <this-repo>/tdd /tmp/upstream-skills/skills/engineering/tdd   # etc.
```

Diff before copying — local edits will be overwritten by a blind `cp -R`. Update the commit SHA
above after each sync.

## Local divergences from upstream

Deliberate edits to vendored skills. **Re-apply these after any upstream sync** — a blind
`cp -R` reverts them.

### `handoff/SKILL.md` — repo-local storage (2026-07-20)

Upstream saves handoffs to the OS temp directory. Replaced with:

- save into `local-docs/handoff/`, explicitly not `mktemp`/`/tmp`
- reuse an existing folder found via `find . -type d -path '*local-docs/handoff' | head -1`,
  else create one at the repo root
- filename `handoff-YYYY-MM-DD_HHMM-<short-descriptive-kebab-name>.md`

**Why:** handoffs need to persist in the repo and sort chronologically; temp-dir handoffs are
lost on reboot and unnamed. Upstream's redaction and `disable-model-invocation` additions were
kept — this diverges only on storage.

### `to-spec/SKILL.md` — test-scope confirmation (2026-07-20)

Restored one sentence to step 2, carried over from the deprecated `to-prd`:

> Check with the user which modules they want tests written for.

**Why:** upstream asks only whether the seams match expectations, and infers test scope from
there. The old skill asked explicitly. Keeping the question makes test scope a decision the user
makes rather than one the agent assumes. Upstream's seams framing was otherwise kept as-is.

### `to-tickets/SKILL.md` — HITL/AFK classification (2026-07-20)

Restored the HITL/AFK split from the deprecated `to-issues`, in four places:

- step 3 — the definition, plus "prefer AFK where possible"
- step 4 — a **Type: HITL / AFK** field in the presentation
- step 4 — the quiz question "Are the correct tickets marked HITL and AFK?"
- step 5 + local template — label follows type: `ready-for-agent` for AFK, `ready-for-human` for HITL

**Why:** upstream applies `ready-for-agent` to every ticket on the grounds that they are
"agent-grabbable by construction", and never emits `ready-for-human`. So a ticket needing an
architectural decision looks identical to one an agent can take unattended, unless the user
separately runs `/triage`. The triage label vocabulary already defines both labels; this makes
`to-tickets` actually use them. Deliberately reuses the existing `ready-for-*` labels rather than
introducing a parallel vocabulary.

**Not restored:** the "User stories covered" field, also dropped upstream. Its replacement
("What it delivers") is better at the job, and per-ticket story IDs never caught coverage gaps
anyway — spotting a gap requires inverting the mapping across every ticket.

## Locally owned (never came from upstream)

- `git-attribution-fix`
- `git-attribution-setup`
- `resume-after-limit`
- `epic-board-550` (lives in `~/.claude/skills`, not this repo)

## Deprecated/

Previous personal versions of these skills, retained for comparison against the vendored
replacements. Not linked into `~/.claude/skills` — `install.sh` only links top-level directories
containing a `SKILL.md`, so nested skills there stay inactive.

Renamed upstream rather than replaced in place:

| Deprecated       | Upstream successor    |
| ---------------- | --------------------- |
| `diagnose`       | `diagnosing-bugs`     |
| `to-prd`         | `to-spec`             |
| `to-issues`      | `to-tickets`          |
| `write-a-skill`  | `writing-great-skills`|
