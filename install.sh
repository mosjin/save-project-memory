#!/usr/bin/env bash
# save-project-memory — Claude Code Skill 安装脚本
# 适用：macOS / Linux
# 功能：将 SKILL.md 安装到 ~/.claude/skills/，可选配置 MEMPALACE_BASE_DIR 环境变量
# 注意：mempalace 本身由 Skill 在首次使用时自动安装（pip install mempalace）
#
# 用法：
#   bash install.sh
#   bash install.sh --base-dir /data/mempalace   # 自定义记忆根目录

set -euo pipefail

SKILL_NAME="save-project-memory"
SKILL_DIR="${HOME}/.claude/skills/${SKILL_NAME}"
# 兼容直接执行和 source/pipe 两种调用方式
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# ── 解析参数 ──────────────────────────────────────────────────
BASE_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-dir)
      BASE_DIR="$2"; shift 2 ;;
    --base-dir=*)
      BASE_DIR="${1#*=}"; shift ;;
    -h|--help)
      echo "用法: bash install.sh [--base-dir <路径>]"
      echo ""
      echo "  --base-dir <路径>   设置记忆根目录（默认: ~/mempalace）"
      echo "                      等同于设置环境变量 MEMPALACE_BASE_DIR"
      echo ""
      echo "注意: mempalace 本身由 Skill 首次使用时自动安装，无需手动安装。"
      exit 0 ;;
    *)
      echo "未知参数: $1"; exit 1 ;;
  esac
done

# ── 安装 Skill 文件 ───────────────────────────────────────────
echo "📦 安装 ${SKILL_NAME} skill..."
mkdir -p "${SKILL_DIR}"
cp "${SCRIPT_DIR}/SKILL.md" "${SKILL_DIR}/SKILL.md"
echo "✅ Skill 已安装到 ${SKILL_DIR}"

# ── 配置 MEMPALACE_BASE_DIR（可选）───────────────────────────
if [[ -n "${BASE_DIR}" ]]; then
  # 检测 shell 类型，选择对应的 rc 文件
  SHELL_RC=""
  if [[ -n "${ZSH_VERSION:-}" ]] || [[ "${SHELL:-}" == */zsh ]]; then
    SHELL_RC="${HOME}/.zshrc"
  elif [[ "${SHELL:-}" == */fish ]]; then
    echo "ℹ️  检测到 Fish shell，请手动将以下内容加入 ~/.config/fish/config.fish："
    echo "    set -x MEMPALACE_BASE_DIR \"${BASE_DIR}\""
  else
    SHELL_RC="${HOME}/.bashrc"
  fi

  if [[ -n "${SHELL_RC}" ]]; then
    EXPORT_LINE="export MEMPALACE_BASE_DIR=\"${BASE_DIR}\""

    if grep -qF "MEMPALACE_BASE_DIR" "${SHELL_RC}" 2>/dev/null; then
      # 已存在：用 grep -v 删除旧行，再追加新行
      # 注意：不用 sed，因为 BASE_DIR 中的特殊字符（|、& 等）会破坏 sed 表达式
      TMP_RC="$(mktemp)"
      grep -vF "MEMPALACE_BASE_DIR" "${SHELL_RC}" > "${TMP_RC}" || true
      printf '\n# mempalace 记忆根目录 (由 save-project-memory 写入)\n%s\n' \
        "${EXPORT_LINE}" >> "${TMP_RC}"
      mv "${TMP_RC}" "${SHELL_RC}"
      echo "✅ 已更新 ${SHELL_RC} 中的 MEMPALACE_BASE_DIR"
    else
      printf '\n# mempalace 记忆根目录 (由 save-project-memory 写入)\n%s\n' \
        "${EXPORT_LINE}" >> "${SHELL_RC}"
      echo "✅ 已写入 ${SHELL_RC}: MEMPALACE_BASE_DIR=${BASE_DIR}"
    fi

    echo "⚠️  请重新加载 shell 或运行: source ${SHELL_RC}"
  fi
else
  echo "ℹ️  未指定 --base-dir，将自动选择存储路径（~/mempalace/<项目名>/palace）"
  echo "   如需自定义，可运行: bash install.sh --base-dir /your/path"
fi

echo ""
echo "🎉 安装完成！在任意项目中对 Claude 说「保存记忆」或「save memory」即可使用。"
