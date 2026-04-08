# save-project-memory — Claude Code Skill 安装脚本
# 适用：Windows (PowerShell 5.1+ / PowerShell 7+)
# 功能：将 SKILL.md 安装到 ~/.claude/skills/，可选配置 MEMPALACE_BASE_DIR 环境变量
# 注意：mempalace 本身由 Skill 在首次使用时自动安装（pip install mempalace）
#
# 用法：
#   .\install.ps1
#   .\install.ps1 -BaseDir "D:\mempalace"
#   .\install.ps1 -BaseDir "D:\mempalace" -Scope Machine   # 需要管理员权限
#
# 如遇执行策略报错，请先运行（仅需一次）：
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

param(
    [string]$BaseDir = "",
    [ValidateSet("User", "Machine")]
    [string]$Scope = "User",
    [switch]$Help
)

if ($Help) {
    Write-Host @"
用法: .\install.ps1 [-BaseDir <路径>] [-Scope User|Machine]

  -BaseDir <路径>     设置记忆根目录（默认：自动选择第一个非系统盘）
                      等同于设置环境变量 MEMPALACE_BASE_DIR
  -Scope User|Machine 环境变量作用域（默认 User，Machine 需管理员权限）

示例:
  .\install.ps1
  .\install.ps1 -BaseDir "D:\mempalace"
  .\install.ps1 -BaseDir "E:\ai-memory" -Scope Machine

如遇"无法加载文件"报错，请先运行：
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

注意: mempalace 本身由 Skill 首次使用时自动安装，无需手动安装。
"@
    exit 0
}

$ErrorActionPreference = "Stop"
$SkillName = "save-project-memory"
$SkillDir  = Join-Path $env:USERPROFILE ".claude\skills\$SkillName"

# $PSScriptRoot 在脚本以文件方式运行时自动设置为脚本所在目录
# 若为空（管道执行），则明确报错，不尝试猜测路径
if (-not $PSScriptRoot) {
    if ($MyInvocation.MyCommand.Path) {
        $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        throw "无法确定脚本所在目录。请以文件方式运行（.\install.ps1），不支持管道执行（iex/irm）。"
    }
} else {
    $ScriptDir = $PSScriptRoot
}

# ── 安装 Skill 文件 ───────────────────────────────────────────
Write-Host "📦 安装 $SkillName skill..."

# Plugin Marketplace 标准路径优先，回退到根目录（向后兼容）
$SkillSrc = Join-Path $ScriptDir ".claude\skills\$SkillName\SKILL.md"
if (-not (Test-Path -LiteralPath $SkillSrc)) {
    $SkillSrc = Join-Path $ScriptDir "SKILL.md"
}
if (-not (Test-Path -LiteralPath $SkillSrc)) {
    throw "找不到 SKILL.md，请确认从仓库根目录运行此脚本。"
}

New-Item -ItemType Directory -Force -LiteralPath $SkillDir | Out-Null
Copy-Item -LiteralPath $SkillSrc -Destination (Join-Path $SkillDir "SKILL.md") -Force
Write-Host "✅ Skill 已安装到 $SkillDir"

# ── 确定目标路径 ──────────────────────────────────────────────
$resolvedBase = ""   # 防御性初始化

if ($BaseDir -ne "") {
    $resolvedBase = $BaseDir
} else {
    # 自动选择：找第一个非系统盘（D 到 Z）
    $sysDrive = ($env:SystemDrive -replace '[\\\/]+$', '').ToUpper()
    $altDrive = [char[]]"DEFGHIJKLMNOPQRSTUVWXYZ" |
        Where-Object { "${_}:" -ne $sysDrive -and (Test-Path "${_}:\") } |
        Select-Object -First 1

    if ($null -ne $altDrive) {
        $resolvedBase = "${altDrive}:\mempalace"
        $driveDisplay = "${altDrive}:\"
        Write-Host "ℹ️  自动选择非系统盘: $driveDisplay"
    } else {
        $resolvedBase = ""
        Write-Host "ℹ️  未找到非系统盘，记忆将保存在各项目目录下（.mempalace/palace）"
    }
}

# ── 写入环境变量（如有路径）────────────────────────────────────
if ($resolvedBase -ne "") {
    try {
        [Environment]::SetEnvironmentVariable("MEMPALACE_BASE_DIR", $resolvedBase, $Scope)
        $env:MEMPALACE_BASE_DIR = $resolvedBase  # 当前进程立即生效
        Write-Host "✅ 已设置环境变量（$Scope 级别）: MEMPALACE_BASE_DIR=$resolvedBase"
        Write-Host "   新 PowerShell 窗口中自动生效；当前窗口已即时生效。"
    } catch {
        if ($Scope -eq "Machine") {
            Write-Warning "设置系统级环境变量需要管理员权限。请以管理员身份重新运行，或改用 -Scope User。"
            exit 1
        } else {
            Write-Host "❌ 设置环境变量失败: $_" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host ""
Write-Host "🎉 安装完成！在任意项目中对 Claude 说「保存记忆」或「save memory」即可使用。"
