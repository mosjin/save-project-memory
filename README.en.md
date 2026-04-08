# save-project-memory

> Claude Code Skill — Automatically save project documentation to [mempalace](https://github.com/milla-jovovich/mempalace) vector memory

[中文](./README.md) | English

---

## What This Skill Does

When you say "save memory" or "保存记忆", Claude automatically:

1. **Installs mempalace** (if missing — one command, zero manual steps)
2. **Registers the MCP Server** (if not configured)
3. **Determines storage path automatically** (env var > non-system drive > project-local)
4. **Scans and saves** project docs to a searchable vector memory store

Supported document types: CHANGELOG, TECH_LOG, IDEAS, README, CLAUDE.md, product specs, system prompts, project state files, and more.

---

## Quick Start

### Option A: Plugin Marketplace (Recommended — 2 commands)

Inside Claude Code:

```
/plugin marketplace add mosjin/save-project-memory
```

```
/plugin install save-project-memory
```

Run `/reload-plugins` if the skill doesn't activate automatically.

---

### Option B: Install Script (git clone)

**macOS / Linux:**

```bash
git clone https://github.com/mosjin/save-project-memory.git
cd save-project-memory
bash install.sh                              # default: ~/mempalace/<project-name>/palace
bash install.sh --base-dir /data/mempalace   # custom memory root
```

**Windows (PowerShell):**

```powershell
git clone https://github.com/mosjin/save-project-memory.git
cd save-project-memory
.\install.ps1                                # auto-selects first non-system drive
.\install.ps1 -BaseDir "D:\mempalace"       # specify memory root
```

The scripts copy `SKILL.md` to `~/.claude/skills/save-project-memory/` and optionally write the `MEMPALACE_BASE_DIR` environment variable. **mempalace installs automatically on first use (~30–60 s, one time only).**

### Step 2: Use It

Open any project and tell Claude:

```
save memory
```

Claude guides you through the full setup (first use requires one Claude Code restart) and reports how many memories were saved.

---

## Storage Path

The path is determined automatically by priority:

| Priority | Source | Example path |
|----------|--------|--------------|
| 1 (highest) | `MEMPALACE_BASE_DIR` env var | `$MEMPALACE_BASE_DIR/<project-name>/palace` |
| 2 | Windows: first available non-system drive | `D:/mempalace/<project-name>/palace` |
| 2 | macOS / Linux | `~/mempalace/<project-name>/palace` |
| 3 (fallback) | Project-local | `<project_dir>/.mempalace/palace` |

---

## Memory Structure (Wing / Room)

Saved memories are organized for precise recall. Each project gets its own **wing** (named after the project directory), so memories from different projects never mix:

```
<your-project-name>/       ← wing = project directory name
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

**Q: Why can't Claude find mempalace tools after setup?**
A: The MCP Server loads at session start. After first-time setup, restart Claude Code once.

**Q: Will re-running save duplicate memories?**
A: No. The Skill calls `tool_check_duplicate` before each save; content with ≥ 90% similarity is skipped automatically.

**Q: Does this work on macOS / Linux?**
A: Yes. Uses `~/mempalace/<project-name>/palace` by default, or reads `MEMPALACE_BASE_DIR` if set.

**Q: I use Fish shell. How do I set the env var?**
A: Add to `~/.config/fish/config.fish`: `set -x MEMPALACE_BASE_DIR "/your/path"`

---

## License

MIT
