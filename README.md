# save-project-memory

> Claude Code Skill — 将项目文档自动保存到 [mempalace](https://github.com/milla-jovovich/mempalace) 向量记忆库

[English](./README.en.md) | 中文

---

## 这个 Skill 做什么

这是 [mempalace](https://github.com/milla-jovovich/mempalace) 的 Claude Code Skill 封装。在任意项目里说一句"save to mempalace"，Claude 自动完成：

1. **安装 mempalace**（首次约 30–60 秒，之后跳过）
2. **注册 MCP Server**（每台机器仅需一次）
3. **自动确定存储路径**（环境变量 → 非系统盘 → 项目本地）
4. **运行 `mempalace mine .`** — 由 mempalace 原生扫描并保存项目内容

文件扫描、分类、去重全部由 mempalace 官方逻辑处理，保存原文（verbatim），不做摘要。

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

执行 `/reload-plugins` 后生效。

---

### 备用：Python 一键脚本

```bash
git clone https://github.com/mosjin/save-project-memory.git
cd save-project-memory
python install.py
```

然后在 Claude Code 中运行 `/reload-plugins`。卸载：`python install.py --remove`

---

<details>
<summary>Shell 脚本安装（含自定义存储路径）</summary>

**macOS / Linux：**

```bash
git clone https://github.com/mosjin/save-project-memory.git
cd save-project-memory
bash install.sh                              # 默认：~/mempalace/<项目名>/palace
bash install.sh --base-dir /data/mempalace   # 自定义存储根目录
```

**Windows（PowerShell）：**

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
save to mempalace
```

### 首次使用流程

```
1. Skill 运行，安装 mempalace（~30–60 秒）
2. 注册 MCP Server，写入存储路径配置
3. ⚠️  提示重启 Claude Code（MCP 在启动时加载，首次必须重启一次）
4. 重启后再说 "save to mempalace"，运行 mempalace mine .
5. 完成
```

### 后续使用

重启后每次说 "save to mempalace" 直接进入扫描，全程幂等，随时可重复执行。

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

## 依赖

- **Claude Code** CLI
- **Python 3.8+**（pip 在 PATH 中）
- **mempalace** — 首次使用时由 Skill 自动安装，无需手动操作

---

## 常见问题

**Q: 安装后 Claude 找不到 mempalace 工具？**

A: MCP Server 在 session 启动时加载。首次配置完成后必须重启 Claude Code 一次，重启后即可正常使用。

---

**Q: macOS / Linux 支持吗？**

A: 完全支持，自动使用 `~/mempalace/<项目名>/palace`，或读取 `MEMPALACE_BASE_DIR`。

---

**Q: Fish shell 如何设置环境变量？**

A: 在 `~/.config/fish/config.fish` 加入：`set -x MEMPALACE_BASE_DIR "/your/path"`

---

**Q: 第一次运行为什么要等那么久？**

A: mempalace 需要从 PyPI 下载安装，约 30–60 秒。之后每次运行此步骤会被自动跳过。

---

**Q: Windows 上步骤 3 报 WinError 32 / PermissionError？**

A: Claude Code 正在占用 `.claude.json` 文件。关闭 Claude Code → 在终端单独运行步骤 3 的 Python 脚本 → 重新打开 Claude Code。

---

## 许可证

MIT
