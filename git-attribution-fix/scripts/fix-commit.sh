#!/bin/sh
# Used mid-rebase via:
#   git rebase <base> --exec "/path/to/fix-commit.sh '<Name> <verified-email>'"
# Amends HEAD (the commit currently being replayed) to fix the author and
# strip any Claude Code co-author trailers from the message body.
set -e

if [ -z "$1" ]; then
  echo "usage: fix-commit.sh '<Name> <verified-email>'" >&2
  exit 1
fi

git commit --amend --no-edit --author="$1"
msg=$(git log -1 --format=%B | sed -e "/^Co-Authored-By: Claude/d" -e "/^Claude-Session:/d")
git commit --amend -m "$msg"
