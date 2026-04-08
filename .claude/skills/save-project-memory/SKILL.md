---
name: save-project-memory
description: Use when the user says "save memory", "save to mempalace", "保存记忆", "保存项目记忆", "project memory", or asks to persist project knowledge for future AI recall. Also use when mempalace is not yet installed or configured for the current project.
user-invocable: true
effort: high
allowed-tools:
  - Bash
  - mcp__mempalace__mempalace_list_wings
  - mcp__mempalace__mempalace_check_duplicate
  - mcp__mempalace__mempalace_add_drawer
  - mcp__mempalace__mempalace_kg_add
  - mcp__mempalace__mempalace_status
---

# save-project-memory

This skill is a **pure wrapper** of the [mempalace](https://github.com/milla-jovovich/mempalace) MCP.
It installs and configures mempalace if not already set up, then saves project content into the palace using mempalace's native conventions — verbatim, no summarization, no custom taxonomy.

---

## Phase 1 — Setup (idempotent, runs every time)

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

Skip this step if Step 3 printed `PALACE_TYPE=external`.

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

> **Claude action**: call `tool_list_wings()` (read-only, safe to call any time).

- **Returns any result (including empty list)** → MCP is active. Proceed to Phase 2.
- **Tool not found / "no palace" error** → MCP was not loaded in this session. Tell the user:

> **Setup complete. Please restart Claude Code, then say "save memory" again.**
>
> Storage path: `<palace_path from Step 3>`

Do not proceed to Phase 2 before the restart.

---

## Phase 2 — Save project content

### Mempalace conventions

Follow mempalace's native conventions exactly:

**Wing** = current project directory name (`Path.cwd().name`).

**Hall** = memory type (5 fixed values, same in every wing):

| Hall | What belongs here |
|------|-------------------|
| `hall_facts` | Decisions made, architectural choices, things definitively true about this project |
| `hall_events` | Things that happened: releases, milestones, debugging sessions, what changed |
| `hall_discoveries` | Breakthroughs, insights, "aha" moments, new understanding |
| `hall_preferences` | Conventions, coding rules, habits, what the team prefers or avoids |
| `hall_advice` | Recommendations, solutions, guidance recorded for future reference |

**Room** = topic slug (free-form, hyphenated, describes the subject — e.g. `auth`, `api-design`, `deployment`, `ci-pipeline`, `architecture`). Do NOT use file names as room names.

**Content** = verbatim. Never summarize. Exact words from the source.

### What to save

Scan the project directory for any readable content worth preserving as project knowledge. This includes but is not limited to: README, CHANGELOG, CLAUDE.md, architecture docs, convention docs, idea files, technical logs, version files, system prompts, product specs, project state files. Use judgment — save anything that captures knowledge about this project.

For each piece of content:
1. Determine the appropriate hall based on content type (see table above)
2. Determine a topic-based room slug from the content subject
3. If content > 3000 characters, split on `## ` headings — save each section as a separate drawer
4. Call `tool_check_duplicate(content=<text>)` — skip if duplicate
5. Call `tool_add_drawer(wing=<project_name>, room=<room>, content=<text>, source_file=<relative_path>, added_by="save-project-memory")`

### Knowledge graph (optional)

After saving drawers, record key project facts you can determine with certainty:

- Language: check `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, etc.
- Branch: `git rev-parse --abbrev-ref HEAD`
- Version: `VERSION.yaml`, `package.json` version field, etc.

Only call `tool_kg_add` for facts you can confirm. Skip any you cannot.

```
tool_kg_add(subject=<project_name>, predicate="language", object=<language>)
tool_kg_add(subject=<project_name>, predicate="current_branch", object=<branch>)
tool_kg_add(subject=<project_name>, predicate="active_version", object=<version>)
```

### Completion report

```
✅ Saved: <N> drawers (<M> skipped as duplicates)
📁 Storage: <palace_path>
🔍 Query: use mempalace search tools with natural language
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Step 5: mempalace tools not found | Restart Claude Code — MCP loads at session start |
| Step 3: project not found in .claude.json | Open this directory in Claude Code first |
| Step 3: mempalace MCP config not in .claude.json | Re-run Step 2 |
| Step 3: WinError 32 / PermissionError | Close Claude Code → run Step 3 script standalone → reopen Claude Code |
| pip install mempalace fails | Check Python/pip are on PATH; try `python -m pip install mempalace` |
