# save-project-memory

> Claude Code Skill — 将项目文档自动保存到 [mempalace](https://github.com/milla-jovovich/mempalace) 向量记忆库

[English](./README.en.md) | 中文

---

## 这个 Skill 做什么

当你说"保存记忆"或"save memory"时，Claude 会自动完成以下全部操作：

1. **安装 mempalace**（如未安装，一条命令搞定，无需手动操作）
2. **注册 MCP Server**（如未配置）
3. **自动确定存储路径**（环境变量 > 非系统盘 > 项目本地，无需手动选择）
4. **扫描并保存**项目文档到可搜索的向量记忆库

支持的文档类型：CHANGELOG、TECH_LOG、IDEAS、README、CLAUDE.md、产品说明书、系统提示词、项目状态文件等。

---

## 快速开始

### 第一步：安装 Skill

**macOS / Linux：**

```bash
git clone https://github.com/mosjin/save-project-memory.git
cd save-project-memory
bash install.sh                           # 默认：~/mempalace/<项目名>/palace
bash install.sh --base-dir /data/mempalace  # 自定义记忆根目录
```

**Windows（PowerShell）：**

```powershell
git clone https://github.com/mosjin/save-project-memory.git
cd save-project-memory
.\install.ps1                             # 自动选择第一个非系统盘
.\install.ps1 -BaseDir "D:\mempalace"   # 指定记忆根目录
```

安装脚本仅将 `SKILL.md` 复制到 `~/.claude/skills/save-project-memory/`，并可选写入 `MEMPALACE_BASE_DIR` 环境变量。**mempalace 本身由 Skill 在首次使用时自动安装。**

### 第二步：使用

打开任意项目，对 Claude 说：

```
保存记忆
```

或：

```
save memory
```

Claude 会引导你完成所有配置（首次使用需重启一次 Claude Code），并报告保存了多少条记忆。

---

## 存储路径

路径由以下优先级自动决定：

| 优先级 | 来源 | 示例路径 |
|--------|------|----------|
| 1（最高） | 环境变量 `MEMPALACE_BASE_DIR` | `$MEMPALACE_BASE_DIR/<项目名>/palace` |
| 2 | Windows：第一个可用的非系统盘 | `D:/mempalace/<项目名>/palace` |
| 2 | macOS / Linux | `~/mempalace/<项目名>/palace` |
| 3（兜底） | 项目本地 | `<项目目录>/.mempalace/palace` |

---

## 记忆分类（Wing / Room）

保存的记忆按以下结构组织，便于后续精准查询：

```
technical/
  changelog     ← CHANGELOG.md
  tech-log      ← TECH_LOG.md、工程经验文档
  version       ← VERSION.yaml、版本配置
  architecture  ← 架构文档

memory/
  project-state ← 项目当前状态
  lessons       ← 规则与教训

creative/
  ideas         ← IDEAS.md、未来计划
  product-spec  ← 产品说明书
  prompts       ← 系统提示词

identity/
  readme        ← README.md
  conventions   ← CLAUDE.md、编码规范
```

---

## 依赖

- **Claude Code** CLI
- **Python 3.8+**（pip 在 PATH 中）
- **mempalace** — 由 Skill 自动安装，无需手动操作

---

## 常见问题

**Q: 为什么执行后 Claude 找不到 mempalace 工具？**
A: MCP Server 在 session 启动时加载，首次配置后需重启 Claude Code。

**Q: 重复执行会存重复记忆吗？**
A: 不会。Skill 在保存前调用 `tool_check_duplicate`，相似度 ≥ 90% 的内容自动跳过。

**Q: 可以在 macOS / Linux 上用吗？**
A: 完全支持。自动使用 `~/mempalace/<项目名>/palace` 路径，或读取 `MEMPALACE_BASE_DIR` 环境变量。

**Q: 我用 Fish shell，环境变量怎么设置？**
A: 在 `~/.config/fish/config.fish` 中加入：`set -x MEMPALACE_BASE_DIR "/your/path"`

---

## 许可证

MIT
