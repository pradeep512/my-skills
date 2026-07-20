---
name: git-attribution-fix
description: Fix already-made commits or branches whose author email doesn't match a verified GitHub email, or which carry a Claude Code Co-Authored-By trailer, so GitHub attributes them solely to the real user. Use when existing commits show unattributed (author_login null) or wrong-author on GitHub, a PR shows Claude as co-author, or the user asks to rewrite commit authorship, strip Claude trailers, or fix attribution on a branch/PR.
disable-model-invocation: true
---

# Git Attribution Fix (existing commits)

Fixes two independent problems on commits that already exist:

1. Wrong or unverified author email (git metadata doesn't match a verified GitHub email → unattributed commit).
2. `Co-Authored-By: Claude ...` / `Claude-Session: ...` trailers left in commit messages (Claude Code's footer, from before `git-attribution-setup` was run) — these survive a plain `--amend` and persist through squash merges even after the author field is fixed.

For preventing this on *future* commits, use the `git-attribution-setup` skill instead — run that too so the problem doesn't recur.

## Before touching anything

1. **Check remotes and PR state**:
   ```bash
   git remote -v
   gh pr list --repo <owner>/<repo> --head <branch> --state all
   ```
2. **Critical rule: if a PR is open, never close it before fixing.** Fix and force-push while it's still OPEN — GitHub live-updates that same PR (same number, same comments/review threads) on every push to the tracked branch. Closing first and force-pushing after **permanently locks** it (`state cannot be changed. The branch was force-pushed or recreated.` on reopen). The only recovery from a locked PR is a brand-new PR from the same branch, losing the old number and thread continuity. See [REFERENCE.md](REFERENCE.md) for the validated case.
3. **Confirm the correct verified email** the same way `git-attribution-setup` does:
   ```bash
   gh api user/emails --jq '.[] | select(.verified==true)'
   ```
   Confirm with the user which email + display name to use — don't guess.
4. **Working tree must be clean** before rebasing: `git status`. Untracked files are fine; stash or commit any uncommitted tracked changes first.

## Fix procedure

**Single commit, tip of branch:**
```bash
git commit --amend --no-edit --author="<Name> <verified-email>"
git push --force-with-lease origin <branch>
```

**Multiple commits** — rewrite author AND strip Claude trailers on every commit ahead of the base branch:
```bash
git rebase <base-branch> --exec "/Users/nilupul/.claude/skills/git-attribution-fix/scripts/fix-commit.sh '<Name> <verified-email>'"
```
(`--exec` rejects multi-line inline shell strings, which is why this is a script file rather than an inline command.)

**Verify before pushing** — every author line should show the verified email, and no Claude trailers should remain:
```bash
git log <base-branch>..HEAD --format='%h %ae'
git log <base-branch>..HEAD --format=%B | grep -E "^(Co-Authored-By: Claude|Claude-Session:)" || echo clean
```

**Push:**
```bash
git push --force-with-lease origin <branch>
```

**Confirm it actually landed** via the API (author_login/committer_login should be the user's GitHub login, never null):
```bash
for sha in $(git rev-list <base-branch>..<branch>); do
  gh api repos/<owner>/<repo>/commits/$sha --jq '"\(.sha[0:8])  author_login=\(.author.login)  committer_login=\(.committer.login)"'
done
```

## Things that bite

Squash-merge trailer concatenation, cross-fork PR specifics, and the closed-PR lockout evidence: see [REFERENCE.md](REFERENCE.md). Also covers when rewriting an already-merged default branch (e.g. `main`) is too high blast radius to do by default.
