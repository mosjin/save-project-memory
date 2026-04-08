# save-project-memory

> Claude Code Skill — Automatically save project documentation to [mempalace](https://github.com/milla-jovovich/mempalace) vector memory

[中文](./README.md) | English

---

## What This Skill Does

Say "save memory" in any project, and Claude automatically:

1. **Installs mempalace** (first run ~30–60 s, skipped afterwards)
2. **Registers the MCP Server** (once per machine)
3. **Determines storage path automatically** (env var → non-system drive → project-local)
4. **Scans and saves** project docs to a searchable vector memory store

Supported: CHANGELOG, TECH_LOG, IDEAS, README, CLAUDE.md, architecture docs, system prompts, project state files, and more.

---

## Installation

### ⭐ Recommended: Plugin Marketplace (2 commands, no git clone needed)

Inside Claude Code, run in order:

**Step 1 — Add the plugin source:**

```
/plugin marketplace add mosjin/save-project-memory
```

**Step 2 — Install the plugin:**

```
/plugin install save-project-memory
```

If the skill doesn't activate immediately, run `/reload-plugins` and try again.

---

### Alternative B: Python One-Liner

```bash
git clone https://github.com/mosjin/save-project-memory.git
cd save-project-memory
python install.py
```

Then run `/reload-plugins` inside Claude Code. To uninstall: `python install.py --remove`

---

### Alternative C: Shell Script (with custom storage path)

<details>
<summary>macOS / Linux</summary>

```bash
git clone https://github.com/mosjin/save-project-memory.git
cd save-project-memory
bash install.sh                              # default: ~/mempalace/<project-name>/palace
bash install.sh --base-dir /data/mempalace   # custom storage root
```

</details>

<details>
<summary>Windows (PowerShell)</summary>

```powershell
git clone https://github.com/mosjin/save-project-memory.git
cd save-project-memory
.\install.ps1                             # auto-selects first non-system drive
.\install.ps1 -BaseDir "D:\mempalace"    # specify storage root
```

If you see "cannot be loaded" errors, run first: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

</details>

---

## Usage

After installation, open any project and tell Claude:

```
save memory
```

### First-Time Flow

```
1. Claude runs the Skill, installs mempalace (~30–60 s)
2. Registers the MCP Server and writes the storage path config
3. ⚠️  Prompts you to restart Claude Code (MCP loads at session start — one restart required)
4. After restart, say "save memory" again to start scanning and saving docs
5. Done — Claude reports how many memories were saved
```

### Subsequent Runs

After the one-time restart, each "save memory" completes in under 30 seconds. Fully idempotent — safe to run anytime.

---

## Storage Path

Determined automatically — no manual configuration needed:

| Priority | Source | Example path |
|----------|--------|--------------|
| 1 (highest) | `MEMPALACE_BASE_DIR` env var | `$MEMPALACE_BASE_DIR/<project-name>/palace` |
| 2 | Windows: first available non-system drive | `D:/mempalace/<project-name>/palace` |
| 2 | macOS / Linux | `~/mempalace/<project-name>/palace` |
| 3 (fallback) | Project-local | `<project_dir>/.mempalace/palace` |

To pin a specific path:

```bash
# macOS / Linux (add to ~/.bashrc or ~/.zshrc)
export MEMPALACE_BASE_DIR="$HOME/mempalace"

# Windows PowerShell (permanent)
[Environment]::SetEnvironmentVariable("MEMPALACE_BASE_DIR", "D:\mempalace", "User")
```

---

## Memory Structure (Wing / Room)

Each project gets its own **wing** named after the project directory — memories from different projects never mix:

```
<your-project-name>/       ← wing = current project directory name
  changelog                ← CHANGELOG.md
  tech-log                 ← TECH_LOG.md, engineering lessons
  version                  ← VERSION.yaml, version config
  architecture             ← Architecture docs
  project-state            ← Current project state
  lessons                  ← Rules and lessons learned
  ideas                    ← IDEAS.md, future plans
  product-spec             ← Product manuals
  prompts                  ← Active system prompts
  readme                   ← README.md
  conventions              ← CLAUDE.md, coding conventions
```

---

## Requirements

- **Claude Code** CLI
- **Python 3.8+** (pip on PATH)
- **mempalace** — auto-installed by the Skill on first use, no manual step needed

---

## FAQ

**Q: Claude can't find mempalace tools after setup?**
A: The MCP Server loads at session start. After first-time setup you must restart Claude Code once — it works normally after that.

**Q: Will re-running save duplicate memories?**
A: No. The Skill calls `tool_check_duplicate` before each save. Content with ≥ 90% similarity is skipped (75% for frequently-updated docs like CHANGELOG).

**Q: Does this work on macOS / Linux?**
A: Yes. Uses `~/mempalace/<project-name>/palace` by default, or reads `MEMPALACE_BASE_DIR` if set.

**Q: I use Fish shell. How do I set the env var?**
A: Add to `~/.config/fish/config.fish`: `set -x MEMPALACE_BASE_DIR "/your/path"`

**Q: Why does the first run take so long?**
A: mempalace is downloaded and installed from PyPI (~30–60 s). This step is automatically skipped on every subsequent run.

---

## License

MIT
