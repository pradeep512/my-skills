#!/usr/bin/env python3
"""Merge {"attribution": {"commit": "", "pr": ""}} into a Claude Code settings.json
without clobbering any other keys already in the file."""
import json
import sys
from pathlib import Path


def main():
    if len(sys.argv) != 2:
        print("usage: set_attribution.py <path-to-settings.json>", file=sys.stderr)
        sys.exit(1)

    path = Path(sys.argv[1]).expanduser()
    if path.exists():
        text = path.read_text().strip()
        data = json.loads(text) if text else {}
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        data = {}

    data.setdefault("attribution", {})
    data["attribution"]["commit"] = ""
    data["attribution"]["pr"] = ""

    path.write_text(json.dumps(data, indent=2) + "\n")
    print(f"Updated {path}")


if __name__ == "__main__":
    main()
