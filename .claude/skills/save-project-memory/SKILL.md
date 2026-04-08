---
name: save-project-memory
description: Use when the user says "save memory", "save to mempalace", "保存记忆", "保存项目记忆", "project memory", or asks to persist project knowledge for future AI recall. Also use when mempalace is not yet installed or configured for the current project.
---

# 保存项目记忆

## 概述

全自动处理：如未安装则自动安装 mempalace，配置存储路径，再将项目文档系统性保存为可搜索的记忆。完全幂等——可随时重复执行。

## 适用场景

- 用户说"保存记忆"/"保存项目记忆"/"save memory"/"save to mempalace"
- 首次为某个项目配置 mempalace
- 完成重要里程碑后持久化项目知识

## 不适用场景

- 查询/搜索记忆 → 直接调用 mempalace search 工具
- 手动添加单条笔记 → 直接调用 `tool_add_drawer`
- 仅查看已保存内容 → 调用 `tool_list_wings`

---

## 存储路径

路径由以下优先级自动决定，**无需手动配置**：

| 优先级 | 来源 | 示例路径 |
|--------|------|----------|
| 1（最高） | 环境变量 `MEMPALACE_BASE_DIR` | `$MEMPALACE_BASE_DIR/<项目名>/palace` |
| 2 | Windows：第一个可用的非系统盘 | `D:/mempalace/<项目名>/palace` |
| 2 | macOS / Linux：用户主目录 | `~/mempalace/<项目名>/palace` |
| 3（兜底） | 项目本地 | `<项目目录>/.mempalace/palace` |

项目名取自 `Path.cwd().name`（当前路径最后一级目录名）。

**如需自定义，提前设置环境变量即可（一次，永久生效）：**

```bash
# macOS / Linux — 加入 ~/.bashrc 或 ~/.zshrc
export MEMPALACE_BASE_DIR="$HOME/mempalace"

# Windows PowerShell
[Environment]::SetEnvironmentVariable("MEMPALACE_BASE_DIR", "D:\mempalace", "User")
```

---

## 第一阶段 — 配置（每次运行，幂等）

### 步骤 1 — 自动安装 mempalace

使用 Python 检测并安装（跨平台，适用于 Windows/macOS/Linux）：

```python
import importlib.util, subprocess, sys

if importlib.util.find_spec("mempalace") is not None:
    print("✅ mempalace 已就绪")
else:
    print("📦 正在安装 mempalace...")
    result = subprocess.run(
        [sys.executable, "-m", "pip", "install", "mempalace"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"❌ mempalace 安装失败:\n{result.stderr}")
        sys.exit(1)
    print("✅ mempalace 安装完成")
```

> 使用 `sys.executable` 确保与当前 Python 环境一致，避免 `python` vs `python3` 歧义，Windows/macOS/Linux 均适用。

### 步骤 2 — 注册 MCP Server（每项目仅需一次）

使用 Python 检测是否已注册，再决定是否执行：

```python
import subprocess, sys

result = subprocess.run(
    ["claude", "mcp", "list"],
    capture_output=True, text=True
)
if "mempalace" in result.stdout.lower():
    print("✅ mempalace MCP 已注册，跳过")
else:
    reg = subprocess.run(
        ["claude", "mcp", "add", "mempalace", "--",
         sys.executable, "-m", "mempalace.mcp_server"],
        capture_output=True, text=True
    )
    # "already exists" 类错误属正常现象，不影响后续步骤
    if reg.returncode != 0 and "already" not in reg.stderr.lower():
        print(f"❌ MCP 注册失败:\n{reg.stderr}")
        sys.exit(1)
    print("✅ mempalace MCP 注册完成")
```

> 使用 `sys.executable` 注册 MCP Server，确保 MCP Server 与安装 mempalace 的 Python 环境一致。

### 步骤 3 — 配置存储路径

运行以下 Python 脚本，将 `MEMPALACE_PALACE_PATH` 写入 `.claude.json`：

```python
import json, os, sys, tempfile
from pathlib import Path

claude_json = Path.home() / ".claude.json"
project_name = Path.cwd().name

# ── 存储路径解析（优先级：环境变量 > 平台默认 > 项目本地）──────
base_dir = os.environ.get("MEMPALACE_BASE_DIR", "").strip()

if base_dir:
    # 转为绝对路径，避免相对路径写入 .claude.json 后因工作目录不同而失效
    palace_path = str(Path(base_dir).resolve() / project_name / "palace")
    print(f"ℹ️  使用环境变量 MEMPALACE_BASE_DIR: {base_dir}")
elif sys.platform == "win32":
    system_drive = os.environ.get("SystemDrive", "C:").rstrip("\\/").upper()
    alt_drive = next(
        (f"{d}:" for d in "DEFGHIJKLMNOPQRSTUVWXYZ"
         if f"{d}:" != system_drive and Path(f"{d}:/").exists()),
        None
    )
    if alt_drive:
        palace_path = str(Path(f"{alt_drive}/mempalace") / project_name / "palace")
        print(f"ℹ️  Windows：使用非系统盘 {alt_drive}")
    else:
        palace_path = str(Path.cwd() / ".mempalace" / "palace")
        print("ℹ️  Windows：未找到非系统盘，改用项目本地存储")
else:
    palace_path = str(Path.home() / "mempalace" / project_name / "palace")
    print(f"ℹ️  macOS/Linux：~/mempalace/{project_name}/palace")
# ────────────────────────────────────────────────────────────

try:
    Path(palace_path).mkdir(parents=True, exist_ok=True)
    print(f"✅ 存储目录已创建: {palace_path}")
except OSError as e:
    print(f"❌ 无法创建存储目录 {palace_path}: {e}")
    sys.exit(1)

# ── 读取 .claude.json ────────────────────────────────────────
try:
    with open(claude_json, "r", encoding="utf-8") as f:
        d = json.load(f)
except FileNotFoundError:
    print("❌ ~/.claude.json 不存在。请先在 Claude Code 中打开此项目，再运行此步骤。")
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"❌ ~/.claude.json 解析失败（文件可能已损坏）: {e}")
    sys.exit(1)

# ── 查找当前项目的 key（大小写不敏感，兼容 Windows 路径格式）──
cwd_norm = os.path.normcase(os.path.normpath(str(Path.cwd())))

proj_key = next(
    (k for k in d.get("projects", {})
     if os.path.normcase(os.path.normpath(k)) == cwd_norm),
    None
)

if proj_key is None:
    print("❌ .claude.json 中未找到此项目记录。")
    print("   请确保已在 Claude Code 中打开过此目录，再重新运行此步骤。")
    sys.exit(1)

# ── 检查 mempalace MCP 注册位置（项目级 或 全局）──────────────
project_mcp = d["projects"][proj_key].get("mcpServers", {})
global_mcp  = d.get("mcpServers", {})

if "mempalace" not in project_mcp and "mempalace" not in global_mcp:
    print("⚠️  项目已注册，但 mempalace MCP 配置尚未写入 .claude.json。")
    print("   请确认步骤 2 已成功执行后，重新运行步骤 3。")
    sys.exit(1)

# ── 写入 MEMPALACE_PALACE_PATH（合并而非覆盖，保留已有 env 变量）
if "mempalace" in project_mcp:
    target = project_mcp["mempalace"]
else:
    target = global_mcp["mempalace"]

env = target.setdefault("env", {})
env["MEMPALACE_PALACE_PATH"] = palace_path

# ── 写入（原子替换，防止 Ctrl+C 损坏文件）───────────────────
tmp_path = claude_json.with_suffix(".json.tmp")
try:
    with open(tmp_path, "w", encoding="utf-8") as f:
        json.dump(d, f, indent=2, ensure_ascii=False)
    tmp_path.replace(claude_json)
    print(f"✅ 存储路径已写入 .claude.json → {palace_path}")
except Exception as e:
    tmp_path.unlink(missing_ok=True)
    print(f"❌ 写入 .claude.json 失败: {e}")
    sys.exit(1)
```

### 步骤 4 — 更新 .gitignore（仅项目本地存储时需要）

若步骤 3 使用了项目本地路径（含 `/.mempalace/`），用 Python 更新 `.gitignore`（跨平台，避免 PowerShell `>>` 输出 UTF-16 的问题）：

```python
from pathlib import Path

gi = Path(".gitignore")
content = gi.read_text(encoding="utf-8") if gi.exists() else ""
if ".mempalace/" not in content:
    gi.write_text(content.rstrip("\n") + "\n.mempalace/\n", encoding="utf-8")
    print("✅ 已将 .mempalace/ 添加到 .gitignore")
else:
    print("✅ .gitignore 已包含 .mempalace/，跳过")
```

若使用外部路径（环境变量或非系统盘），跳过此步骤。

### 步骤 5 — 验证 MCP 是否已激活

> **Claude 操作**：调用 `tool_list_wings()`（无副作用，可安全用于验证）

- **调用成功，返回 wings 列表（空列表也表示成功，代表 palace 尚无数据）** → 进入第二阶段
- **工具不存在 / 返回"no palace"错误** → MCP 在本次 session 启动前未加载，告知用户：

> **配置完成。请重启 Claude Code，重启后重新执行此 skill 以保存记忆。**
>
> 存储路径：`<步骤 3 输出的 palace_path>`

**重启完成前，不要进入第二阶段。**

---

## 第二阶段 — 收集并保存记忆

### 首先验证 API 可用性

在保存任何内容之前，调用一次无副作用的工具确认 mempalace API 正常：

> **Claude 操作**：调用 `tool_list_wings()`，查看返回结构。

若返回格式为 `{"wings": {...}}` 或 `{"wings": {}}` → API 正常，继续。  
若返回错误或格式异常 → 停止，提示用户检查 mempalace 版本：`python3 -m pip show mempalace`

### 翼/房间分类表（Wing / Room Taxonomy）

> **重要**：`wing` = 当前项目名称（`Path.cwd().name`），`room` = 内容类型。
> 每个项目的所有记忆都保存在以项目名命名的 wing 下，多项目互不干扰。

| 房间 (Room)     | 来源文件 |
|----------------|----------|
| `changelog`    | CHANGELOG.md |
| `tech-log`     | TECH_LOG.md、EXPERIENCE.md |
| `version`      | VERSION.yaml、package.json 版本块 |
| `architecture` | 架构文档、流水线说明 |
| `project-state`| memory/project_state.md、STATUS.md |
| `lessons`      | TECH_LOG 中的规则/经验章节 |
| `ideas`        | IDEAS.md、my_ideas.md |
| `product-spec` | 产品说明书（最新版）、product manual |
| `prompts`      | 当前系统提示词 |
| `readme`       | README.md |
| `conventions`  | CLAUDE.md、编码规范文档 |

示例调用：
```
# project_name = Path.cwd().name，例如 "my-app"
tool_add_drawer(wing="my-app", room="changelog", content=..., source_file="CHANGELOG.md", added_by="save-project-memory")
```

### 文件发现顺序

按优先级扫描。**若同一文件在 `docs/` 和根目录均存在，两份都保存**（用不同的 `source_file` 区分），由 `tool_check_duplicate` 自动判断内容是否重复：

```
docs/CHANGELOG.md  →  CHANGELOG.md  →  CHANGELOG
docs/TECH_LOG.md   →  TECH_LOG.md
docs/IDEAS.md      →  IDEAS.md
docs/my_ideas.md   →  my_ideas.md
docs/VERSION.yaml  →  VERSION.yaml
docs/manuals/      →  最新的 *产品说明书*.md 或 *manual*.md
docs/prompts/      →  当前系统提示词（从 VERSION.yaml 获取文件名）
memory/project_state.md  →  .claude/projects/*/memory/project_state.md
README.md
CLAUDE.md
```

对列表外的文档，参照分类表选择最近的 room。

### 分块策略

- ≤ 3 000 字符 → 整体存为一个抽屉
- > 3 000 字符 → 按 `## ` 标题切分：
  - **第一个 `## ` 之前的内容（preamble）**：若非空，作为独立抽屉保存，title 用文件名（如 `"CHANGELOG.md — 文件头"`）
  - 每个 `## ` 节存为独立抽屉
- 始终设置 `source_file`（相对路径）和 `added_by`（`"save-project-memory"`）

### 重复检测阈值

根据内容类型使用不同阈值（避免对频繁更新的文档误判为重复）：

| 房间 (Room) | 阈值 | 原因 |
|------------|------|------|
| `changelog`, `project-state`, `lessons`, `tech-log` | 0.75 | 活文档，频繁增量更新 |
| `readme`, `conventions`, `architecture`, `version`, `ideas`, `product-spec`, `prompts` | 0.90 | 相对稳定的文档 |

### 保存循环

初始化计数器：`saved_count = 0`，`skipped_count = 0`，`failed_chunks = []`

对每个分块，使用对应 room 的阈值：

1. 调用 `tool_check_duplicate(content=<文本>, threshold=<该room对应阈值>)`
   - 若 `is_duplicate: true` → `skipped_count += 1`，跳过
2. 调用 `tool_add_drawer(wing=<项目名>, room=<房间>, content=<文本>, source_file=<相对路径>, added_by="save-project-memory")`
   - 成功 → `saved_count += 1`
   - 失败 → `failed_chunks.append(source_file + ":" + chunk_title)`，继续下一个（不中断整体流程）

### 知识图谱（可选）

抽屉保存完成后，记录关键项目事实。**将以下占位符替换为实际值**（`project_name` 已在步骤 3 中确定为 `Path.cwd().name`）：

```
# project_name 已在步骤 3 确定为 Path.cwd().name，用实际值替换尖括号占位符
tool_kg_add(subject=project_name, predicate="language",       object=<从 package.json/pyproject.toml/go.mod 等推断>)
tool_kg_add(subject=project_name, predicate="current_branch", object=<git rev-parse --abbrev-ref HEAD 的输出>)
tool_kg_add(subject=project_name, predicate="active_version", object=<从 VERSION.yaml 或 package.json version 字段读取>)
```

若某字段无法确定，跳过该行，不要写入占位符文字。

### 完成报告

```
✅ 记忆已保存：<saved_count> 个新抽屉（<skipped_count> 个内容未变已跳过）
📁 存储路径：<palace_path>
🗂  已写入房间：<列出本次实际使用的 room，如: changelog, readme, project-state>
<如有失败> ⚠️  以下分块保存失败，请检查：<failed_chunks>
🔍 查询方式：使用 mempalace search 工具输入自然语言查询
```

---

## 常见问题

| 现象 | 解决方法 |
|------|----------|
| 步骤 5 找不到 mempalace 工具 | 重启 Claude Code — MCP 仅在 session 启动时加载 |
| 存储落到了意外路径 | 检查 `MEMPALACE_PALACE_PATH` 是否已写入 `.claude.json`；重新执行步骤 3 |
| 步骤 3 报"未找到此项目记录" | 在 Claude Code 中打开此目录后重试；检查路径是否一致 |
| 步骤 3 报"mempalace MCP 配置尚未写入" | 步骤 2 可能未成功；重新执行步骤 2 |
| 每个抽屉都返回 `is_duplicate` | 内容已存在，存储是最新的，skipped_count 会体现在完成报告中 |
| 大文件存成一个不可搜索的块 | 按 `## ` 标题分块（见分块策略） |
| 安装 mempalace 失败 | 确认 Python/pip 在 PATH 中；尝试 `python3 -m pip install mempalace` |
| 更新 CHANGELOG 后记忆未更新 | changelog/project-state 等活文档使用 0.75 阈值；若仍被跳过，旧抽屉内容可能高度相似，可手动删除后重新保存 |
