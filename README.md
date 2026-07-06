# my-skills

Personal [Claude Code](https://claude.com/claude-code) skills, version-controlled so they
follow me across machines instead of living only in `~/.claude/skills`.

## Layout

Each top-level directory is one skill, matching the structure Claude Code expects:

```
skill-name/
├── SKILL.md       # required — name, description, instructions
├── REFERENCE.md   # optional — details split out to keep SKILL.md short
└── scripts/       # optional — helper scripts the skill shells out to
```

## Setup on a new machine

```bash
git clone https://github.com/pradeep512/my-skills.git ~/GitHub/my-skills
~/GitHub/my-skills/install.sh
```

`install.sh` symlinks every skill directory in this repo into `~/.claude/skills/`,
so Claude Code picks them up immediately, and any edit made through Claude Code (or
by hand) lands directly in this git repo — no separate copy/sync step.

## Adding a new skill

1. Create `new-skill-name/SKILL.md` in this repo (see `write-a-skill` skill in here
   for the format).
2. Re-run `./install.sh` (safe to re-run — it only (re)links what's missing or stale).
3. Commit and push.

## Removing a skill

Delete its directory from this repo, then remove the now-dangling symlink from
`~/.claude/skills/<name>` on each machine (or just re-run `install.sh`'s companion
cleanup: `find ~/.claude/skills -maxdepth 1 -type l ! -exec test -e {} \; -delete`).
