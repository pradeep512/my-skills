#!/bin/sh
# Symlinks every skill directory in this repo into ~/.claude/skills/.
# Safe to re-run: skips anything already correctly linked, warns instead of
# clobbering a real (non-symlink) directory that happens to share the name.
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.claude/skills"

mkdir -p "$TARGET_DIR"

for skill_path in "$REPO_DIR"/*/; do
  skill_path="${skill_path%/}"
  name="$(basename "$skill_path")"
  [ -f "$skill_path/SKILL.md" ] || continue

  link="$TARGET_DIR/$name"

  if [ -L "$link" ]; then
    current_target="$(python3 -c "import os; print(os.path.realpath('$link'))")"
    if [ "$current_target" = "$skill_path" ]; then
      : # already correct, nothing to do
    else
      rm "$link"
      ln -s "$skill_path" "$link"
      echo "relinked: $name"
    fi
  elif [ -e "$link" ]; then
    echo "skipped (real directory already exists, not a symlink): $name" >&2
  else
    ln -s "$skill_path" "$link"
    echo "linked: $name"
  fi
done
