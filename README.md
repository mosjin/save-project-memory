# save-project-memory

> Claude Code Skill — 将项目文档自动保存到 [mempalace](https://github.com/milla-jovovich/mempalace) 向量记忆库

[English](./README.en.md) | 中文

---

## 这个 Skill 做什么

在任意项目里说一句"保存记忆"，Claude 自动完成：

1. **安装 mempalace**（首次约 30–60 秒，之后跳过）
2. **注册 MCP Server**（每台机器仅需一次）
3. **自动确定存储路径**（环境变量 → 非系统盘 → 项目本地）
4. **扫描并保存**项目文档到可搜索的向量记忆库

支持：CHANGELOG、TECH_LOG、IDEAS、README、CLAUDE.md、架构文档、系统提示词、项目状态文件等。

---

## 安装

### ⭐ 推荐：Plugin Marketplace（两条命令，无需 git clone）

在 Claude Code 中依次执行：

**第一步 — 添加插件源：**

```
/plugin marketplace add mosjin/save-project-memory
```

**第二步 — 安装插件：**

```
/plugin install save-project-memory
```

若 Skill 未立即生效，执行 `/reload-plugins` 后重试。

---

### 备用：脚本安装（git clone）

<details>
<summary>macOS / Linux</summary>

```bash
git clone https://github.com/mosjin/save-project-memory.git
cd save-project-memory
bash install.sh                              # 默认：~/mempalace/<项目名>/palace
bash install.sh --base-dir /data/mempalace   # 自定义存储根目录
```

</details>

<details>
<summary>Windows（PowerShell）</summary>

```powershell
git clone https://github.com/mosjin/save-project-memory.git
cd save-project-memory
.\install.ps1                             # 自动选择第一个非系统盘
.\install.ps1 -BaseDir "D:\mempalace"    # 指定存储根目录
```

如遇"无法加载文件"报错，请先运行：`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

</details>

---

## 使用

安装完成后，打开任意项目，对 Claude 说：

```
保存记忆
```

或英文：

```
save memory
```

### 首次使用流程

```
1. Claude 运行 Skill，安装 mempalace（~30–60 秒）
2. 注册 MCP Server，写入存储路径配置
3. ⚠️  提示重启 Claude Code（MCP 在启动时加载，首次必须重启一次）
4. 重启后再说"保存记忆"，开始正式扫描保存文档
5. 完成，报告保存了多少条记忆
```

### 后续使用

重启后每次说"保存记忆"，整个流程 < 30 秒，完全幂等，随时可重复执行。

---

## 存储路径

路径优先级自动决定，无需手动配置：

| 优先级 | 来源 | 示例路径 |
|--------|------|----------|
| 1（最高） | 环境变量 `MEMPALACE_BASE_DIR` | `$MEMPALACE_BASE_DIR/<项目名>/palace` |
| 2 | Windows：第一个可用的非系统盘 | `D:/mempalace/<项目名>/palace` |
| 2 | macOS / Linux | `~/mempalace/<项目名>/palace` |
| 3（兜底） | 项目本地 | `<项目目录>/.mempalace/palace` |

如需固定路径：

```bash
# macOS / Linux（加入 ~/.bashrc 或 ~/.zshrc）
export MEMPALACE_BASE_DIR="$HOME/mempalace"

# Windows PowerShell（永久生效）
[Environment]::SetEnvironmentVariable("MEMPALACE_BASE_DIR", "D:\mempalace", "User")
```

---

## 记忆结构（Wing / Room）

每个项目独占一个 wing（以项目目录名命名），多项目记忆互不干扰：

```
<your-project-name>/       ← wing = 当前项目目录名
  changelog                ← CHANGELOG.md
  tech-log                 ← TECH_LOG.md、工程经验文档
  version                  ← VERSION.yaml、版本配置
  architecture             ← 架构文档
  project-state            ← 项目当前状态
  lessons                  ← 规则与教训
  ideas                    ← IDEAS.md、未来计划
  product-spec             ← 产品说明书
  prompts                  ← 系统提示词
  readme                   ← README.md
  conventions              ← CLAUDE.md、编码规范
```

---

## 依赖

- **Claude Code** CLI
- **Python 3.8+**（pip 在 PATH 中）
- **mempalace** — 首次使用时由 Skill 自动安装，无需手动操作

---

## 常见问题

**Q: 安装后 Claude 找不到 mempalace 工具？**
A: MCP Server 在 session 启动时加载。首次配置完成后必须重启 Claude Code 一次，重启后即可正常使用。

**Q: 重复执行会保存重复记忆吗？**
A: 不会。每次保存前调用 `tool_check_duplicate` 去重，相似度 ≥ 90% 的内容自动跳过（活文档阈值为 75%）。

**Q: macOS / Linux 支持吗？**
A: 完全支持，自动使用 `~/mempalace/<项目名>/palace`，或读取 `MEMPALACE_BASE_DIR`。

**Q: Fish shell 如何设置环境变量？**
A: 在 `~/.config/fish/config.fish` 加入：`set -x MEMPALACE_BASE_DIR "/your/path"`

**Q: 第一次运行为什么要等那么久？**
A: mempalace 需要从 PyPI 下载安装，约 30–60 秒。之后每次运行此步骤会被自动跳过。

---

## 许可证

MIT
