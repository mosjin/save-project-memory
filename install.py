#!/usr/bin/env python3
"""
One-command installer for save-project-memory Claude Code skill.
Auto-patches ~/.claude/settings.json — no JSON editing needed.

  python install.py           # install
  python install.py --remove  # uninstall
"""
import json, os, sys, shutil
from pathlib import Path

MARKETPLACE_KEY = "save-project-memory"
PLUGIN_KEY      = "save-project-memory@save-project-memory"
SOURCE          = {"source": {"source": "github", "repo": "mosjin/save-project-memory"}}


def find_settings():
    # Claude Code CLI 在所有平台上都使用 ~/.claude/settings.json
    p = Path.home() / ".claude/settings.json"
    if not p.exists():
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("{}\n")
    return p


def install():
    path = find_settings()
    shutil.copy2(path, path.with_suffix(".json.bak"))
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"❌ settings.json 解析失败（文件可能已损坏）: {e}")
        print(f"   备份已保存至: {path.with_suffix('.json.bak')}")
        sys.exit(1)

    changed = False
    if MARKETPLACE_KEY not in data.setdefault("extraKnownMarketplaces", {}):
        data["extraKnownMarketplaces"][MARKETPLACE_KEY] = SOURCE
        print(f"✓ Marketplace registered: {MARKETPLACE_KEY}")
        changed = True
    if not data.setdefault("enabledPlugins", {}).get(PLUGIN_KEY):
        data["enabledPlugins"][PLUGIN_KEY] = True
        print(f"✓ Plugin enabled: {PLUGIN_KEY}")
        changed = True

    if changed:
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print("\nDone! Run  /reload-plugins  inside Claude Code, then use  save memory")
    else:
        print("Already installed. Run /reload-plugins if the skill is not showing.")


def remove():
    path = find_settings()
    data = json.loads(path.read_text(encoding="utf-8"))
    removed = []
    if MARKETPLACE_KEY in data.get("extraKnownMarketplaces", {}):
        del data["extraKnownMarketplaces"][MARKETPLACE_KEY]
        removed.append("marketplace")
    if PLUGIN_KEY in data.get("enabledPlugins", {}):
        del data["enabledPlugins"][PLUGIN_KEY]
        removed.append("plugin")
    if removed:
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"Removed: {', '.join(removed)}. Run /reload-plugins.")
    else:
        print("Nothing to remove.")


if __name__ == "__main__":
    remove() if "--remove" in sys.argv else install()
