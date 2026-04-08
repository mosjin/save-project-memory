#!/usr/bin/env python3
"""
One-command installer for save-project-memory Claude Code skill.
Auto-patches ~/.claude/settings.json and installs the skill directly
to ~/.claude/skills/ for reliable loading in all Claude Code versions.

  python install.py           # install
  python install.py --remove  # uninstall
"""
import json, os, sys, shutil
from pathlib import Path

MARKETPLACE_KEY = "save-project-memory"
PLUGIN_KEY      = "save-project-memory@save-project-memory"
SKILL_NAME      = "save-project-memory"
SOURCE          = {"source": {"source": "github", "repo": "mosjin/save-project-memory"}}


def find_settings():
    p = Path.home() / ".claude/settings.json"
    if not p.exists():
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text("{}\n")
    return p


def install_skill_file():
    """Copy SKILL.md to ~/.claude/skills/<name>/ for guaranteed loading."""
    # install.py lives next to .claude/skills/ in the repo/plugin directory
    here = Path(__file__).parent
    skill_src = here / ".claude" / "skills" / SKILL_NAME / "SKILL.md"
    skill_dst_dir = Path.home() / ".claude" / "skills" / SKILL_NAME
    skill_dst = skill_dst_dir / "SKILL.md"

    if not skill_src.exists():
        print(f"⚠ SKILL.md not found at {skill_src}, skipping skill file install")
        return False

    skill_dst_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(skill_src, skill_dst)
    print(f"✓ Skill installed: {skill_dst}")
    return True


def remove_skill_file():
    skill_dst_dir = Path.home() / ".claude" / "skills" / SKILL_NAME
    if skill_dst_dir.exists():
        shutil.rmtree(skill_dst_dir)
        print(f"✓ Skill removed: {skill_dst_dir}")


def install():
    path = find_settings()
    shutil.copy2(path, path.with_suffix(".json.bak"))
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"❌ settings.json parse error: {e}")
        print(f"   Backup saved to: {path.with_suffix('.json.bak')}")
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

    install_skill_file()
    print("\nDone! Run /reload-plugins inside Claude Code, then say: save to mempalace")


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
        print(f"✓ settings.json updated: removed {', '.join(removed)}")
    remove_skill_file()
    print("Done. Run /reload-plugins.")


if __name__ == "__main__":
    remove() if "--remove" in sys.argv else install()
