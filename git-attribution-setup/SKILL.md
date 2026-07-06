---
name: git-attribution-setup
description: Configure git and Claude Code on this machine so future commits, pushes, and PRs (including ones Claude creates) attribute correctly to the user's own GitHub account, with no Claude co-author trailer. Use when setting up a new machine, onboarding a new contributor, when commits show as unattributed or wrong-author on GitHub, or the user asks to set up git/GitHub attribution, stop Claude showing as co-author going forward, or configure their email for GitHub.
---

# Git Attribution Setup

Two independent things break attribution, and both must be fixed:

1. Git's `user.email` not matching a **verified** email on the user's GitHub account → commit shows unattributed (no avatar, no profile link, `author_login: null` via API).
2. Claude Code's default `Co-Authored-By: Claude ...` trailer + `🤖 Generated with Claude Code` footer → even a correctly-attributed commit visually reads as co-authored by Claude.

This is per-machine, per-account config — nothing here syncs automatically. Run it again on every new machine, or whenever a different person is going to be committing.

## Steps

1. **Confirm GitHub CLI auth**: `gh auth status`. If not logged in, tell the user to run `gh auth login` themselves (interactive — don't do it for them).

2. **List verified emails and identity**:
   ```bash
   gh api user/emails --jq '.[] | select(.verified==true) | "\(.email)  primary=\(.primary)"'
   gh api user --jq '"login=\(.login)  name=\(.name)"'
   ```

3. **Confirm with the user** which verified email to use (usually the `primary=true` one) and what name to attach. Always confirm even if there's only one candidate — never assume, and never silently reuse a previous user's email if multiple people share this machine.

4. **Set git config.** Ask whether this should be global (all repos on this machine) or local (this repo only):
   ```bash
   git config --global user.email "<confirmed-email>"
   git config --global user.name  "<confirmed-name-or-login>"
   # use --local instead of --global to scope to one repo
   ```

5. **Zero out Claude Code's attribution footer**, merging into existing settings so other keys survive:
   ```bash
   python3 /Users/nilupul/.claude/skills/git-attribution-setup/scripts/set_attribution.py ~/.claude/settings.json
   ```
   To scope to one project instead of globally, target that repo's `.claude/settings.json` in the same command.

6. **Check for local overrides.** A repo's own `.claude/settings.json` or `.claude/settings.local.json` can override the global attribution setting — if this setup is prompted by problems in one specific repo, check there too and fix it the same way.

7. **Verify**:
   ```bash
   git config user.email
   grep -A3 '"attribution"' ~/.claude/settings.json
   ```

## Notes

- This only affects **future** commits/PRs. For commits that already exist with the wrong author or a Claude trailer, use the separate `git-attribution-fix` skill instead.
- Don't guess the email from context (e.g. a company domain) — always pull it from `gh api user/emails` and confirm, since an unverified guess won't fix attribution at all.
