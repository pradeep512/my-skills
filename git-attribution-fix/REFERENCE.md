# Reference: attribution-fix caveats and evidence

## Why both author AND trailers must be fixed

- **Squash merge**: GitHub builds the squash commit's message by concatenating every
  constituent commit's body, including their `Co-authored-by` trailers. Fixing only
  the author field and leaving trailers in the messages still results in Claude
  listed as co-author on the squash commit.
- **Merge commit / rebase-and-merge**: every original commit lands individually in
  the target branch's history, so every one of their author fields matters, not
  just the tip's.

## Cross-fork PRs (fork branch → upstream PR)

- Only push access to your own fork's branch is needed — never touch upstream
  directly. An existing upstream PR auto-tracks whatever's on the fork branch it
  was opened from.
- Works the same regardless of whether upstream is public or private, and
  regardless of whether you also happen to have push rights on upstream itself.
- Force-pushing changes commit SHAs, so **inline** review comments anchored to a
  specific line/commit may show as "outdated" in the diff view — the comment text
  itself is preserved, just the pinned-line anchor doesn't follow the rewrite.

## The closed-PR lockout (validated, not theoretical)

Confirmed by direct test: closing a PR and then force-pushing its branch
permanently locks it — `state cannot be changed. The branch was force-pushed or
recreated.` The Reopen button/API call fails from then on. The only recovery is
opening a brand-new PR from the same (now-fixed) branch, which loses the old PR
number and comment-thread continuity (the old closed PR's comment text is still
viewable, just no longer attached to a live PR).

Correct order: fix + force-push **while the PR is still OPEN**. GitHub tracks a PR
by (head repo, head branch) + (base repo, base branch) and live-updates it on
every push — same PR number, same comments/review threads, no close/reopen step
needed at all. This holds identically for same-repo PRs and fork→upstream
cross-repo PRs.

## Deciding whether to rewrite a default/main branch

Rewriting an already-merged default branch (e.g. `main`) is much higher blast
radius than an unpushed or PR-only feature branch: it can orphan other people's
local clones, break already-closed/merged PR history, and provides low value if
the commits are already reviewed/graded/shipped. Treat that as a judgment call to
discuss with the user rather than doing by default — this skill's procedure is
meant for branches that are unpushed, or pushed only to a personal fork with an
open (or no) PR.
