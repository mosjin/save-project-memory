---
name: save-project-memory
description: Use when the user says "save to mempalace", "mempalace save", "保存到mempalace", "保存项目记忆到mempalace", or asks to install/configure mempalace for the current project.
---

# save-project-memory

A thin setup wrapper for [mempalace](https://github.com/milla-jovovich/mempalace).

- **Phase 1** — installs mempalace and registers its MCP Server (one-time, idempotent)
- **Phase 2** — runs `mempalace mine .` to save the project (mempalace's own logic, unchanged)

---

## Phase 1 — Setup (idempotent)

### Step 0 — Self-install skill (first run only)

The plugin system may not auto-load this skill. Check and fix silently:

```python
import shutil
from pathlib import Path

skill_dst = Path.home() / ".claude/skills/save-project-memory/SKILL.md"
if not skill_dst.exists():
    # Search plugin cache for this SKILL.md
    candidates = list(Path.home().glob(
        ".claude/plugins/**/save-project-memory/SKILL.md"
    ))
    if candidates:
        skill_dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(candidates[0], skill_dst)
        print("✅ Skill self-installed to ~/.claude/skills/")
        print("⚠️  Please run /reload-plugins, then say 'save to mempalace' again.")
        import sys; sys.exit(0)
    else:
        print("⚠️  Could not find SKILL.md in plugin cache. Try: python install.py")
else:
    print("✅ Skill already installed")
```

### Step 1 — Install mempalace

```python
import importlib.util, subprocess, sys

if importlib.util.find_spec("mempalace") is not None:
    print("✅ mempalace ready")
else:
    print("📦 Installing mempalace...")
    result = subprocess.run(
        [sys.executable, "-m", "pip", "install", "mempalace"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"❌ Install failed:\n{result.stderr}")
        sys.exit(1)
    print("✅ mempalace installed")
```

### Step 2 — Register MCP Server

```python
import subprocess, sys

try:
    result = subprocess.run(["claude", "mcp", "list"], capture_output=True, text=True)
except FileNotFoundError:
    print("⚠️  claude CLI not found. Register manually:")
    print("   claude mcp add mempalace -- python -m mempalace.mcp_server")
    sys.exit(1)

if "mempalace" in result.stdout.lower():
    print("✅ mempalace MCP already registered")
else:
    reg = subprocess.run(
        ["claude", "mcp", "add", "mempalace", "--", sys.executable, "-m", "mempalace.mcp_server"],
        capture_output=True, text=True
    )
    if reg.returncode != 0 and "already" not in reg.stderr.lower():
        print(f"❌ MCP registration failed:\n{reg.stderr}")
        sys.exit(1)
    print("✅ mempalace MCP registered")
```

### Step 3 — Configure storage path

Write `MEMPALACE_PALACE_PATH` into `.claude.json` for this project.

Path priority: `MEMPALACE_BASE_DIR` env var → non-system drive (Windows) → `~/mempalace` (macOS/Linux) → project-local fallback.

```python
import json, os, sys, time
from pathlib import Path

claude_json = Path.home() / ".claude.json"
project_name = Path.cwd().name

base_dir = os.environ.get("MEMPALACE_BASE_DIR", "").strip()
if base_dir:
    palace_path = str(Path(base_dir).resolve() / project_name / "palace")
    print(f"ℹ️  Using MEMPALACE_BASE_DIR: {base_dir}")
elif sys.platform == "win32":
    system_drive = os.environ.get("SystemDrive", "C:").rstrip("\\/").upper()
    alt_drive = next(
        (f"{d}:" for d in "DEFGHIJKLMNOPQRSTUVWXYZ"
         if f"{d}:" != system_drive and Path(f"{d}:/").exists()),
        None
    )
    if alt_drive:
        palace_path = str(Path(f"{alt_drive}/mempalace") / project_name / "palace")
        print(f"ℹ️  Windows: using non-system drive {alt_drive}")
    else:
        palace_path = str(Path.cwd() / ".mempalace" / "palace")
        print("ℹ️  Windows: no non-system drive found, using project-local storage")
else:
    palace_path = str(Path.home() / "mempalace" / project_name / "palace")
    print(f"ℹ️  macOS/Linux: ~/mempalace/{project_name}/palace")

try:
    Path(palace_path).mkdir(parents=True, exist_ok=True)
    print(f"✅ Storage directory ready: {palace_path}")
except OSError as e:
    print(f"❌ Cannot create storage directory {palace_path}: {e}")
    sys.exit(1)

try:
    with open(claude_json, "r", encoding="utf-8") as f:
        d = json.load(f)
except FileNotFoundError:
    print("❌ ~/.claude.json not found. Open this project in Claude Code first, then retry.")
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"❌ ~/.claude.json parse error: {e}")
    sys.exit(1)

cwd_norm = os.path.normcase(os.path.normpath(str(Path.cwd())))
proj_key = next(
    (k for k in d.get("projects", {})
     if os.path.normcase(os.path.normpath(k)) == cwd_norm),
    None
)

if proj_key is None:
    print("❌ Project not found in .claude.json. Open this directory in Claude Code first.")
    sys.exit(1)

project_mcp = d["projects"][proj_key].get("mcpServers", {})
global_mcp  = d.get("mcpServers", {})

if "mempalace" not in project_mcp and "mempalace" not in global_mcp:
    print("⚠️  mempalace MCP config not in .claude.json. Re-run Step 2 first.")
    sys.exit(1)

target = project_mcp.get("mempalace") or global_mcp.get("mempalace")
target.setdefault("env", {})["MEMPALACE_PALACE_PATH"] = palace_path

tmp_path = claude_json.with_suffix(".json.tmp")
try:
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(d, f, indent=2, ensure_ascii=False)
    for attempt in range(3):
        try:
            tmp_path.replace(claude_json)
            break
        except PermissionError:
            if attempt == 2:
                raise
            time.sleep(0.5)
    palace_type = "local" if ".mempalace" in palace_path else "external"
    print(f"✅ MEMPALACE_PALACE_PATH written to .claude.json → {palace_path}")
    print(f"PALACE_TYPE={palace_type}")
except Exception as e:
    tmp_path.unlink(missing_ok=True)
    print(f"❌ Failed to write .claude.json: {e}")
    if "WinError 32" in str(e) or "PermissionError" in type(e).__name__:
        print("   Windows: Claude Code may be holding the file. Close Claude Code, run this script standalone, then reopen.")
    sys.exit(1)
```

### Step 4 — Update .gitignore (only when PALACE_TYPE=local)

Skip if Step 3 printed `PALACE_TYPE=external`.

```python
from pathlib import Path

gi = Path(".gitignore")
content = gi.read_text(encoding="utf-8") if gi.exists() else ""
if ".mempalace/" not in content:
    gi.write_text(content.rstrip("\n") + "\n.mempalace/\n", encoding="utf-8")
    print("✅ Added .mempalace/ to .gitignore")
else:
    print("✅ .gitignore already contains .mempalace/")
```

### Step 5 — Verify MCP is active

> **Claude action**: call `tool_list_wings()` (read-only).

- **Returns any result** → MCP is active. Proceed to Phase 2.
- **Tool not found / error** → MCP was not loaded in this session. Tell the user:

> **Setup complete. Please restart Claude Code, then say "save memory" again.**
>
> Storage path: `<palace_path from Step 3>`

Do not proceed to Phase 2 before the restart.

---

## Phase 2 — Save

Run mempalace's own mine command against the current project directory:

```python
import subprocess, sys

result = subprocess.run(
    [sys.executable, "-m", "mempalace", "mine", "."],
    text=True
)
if result.returncode != 0:
    print(f"❌ mempalace mine failed. Try running manually: mempalace mine .")
```

Report the output to the user as-is.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Step 5: mempalace tools not found | Restart Claude Code — MCP loads at session start |
| Step 3: project not found in .claude.json | Open this directory in Claude Code first |
| Step 3: mempalace MCP config not in .claude.json | Re-run Step 2 |
| Step 3: WinError 32 / PermissionError | Close Claude Code → run Step 3 script standalone → reopen Claude Code |
| pip install mempalace fails | Check Python/pip are on PATH; try `python -m pip install mempalace` |
| mempalace mine fails | Run `mempalace mine .` manually in terminal to see full error |
