# =============================================================================
# Claude Code 一键安装脚本 (Windows 版)
# 适合完全没有编程经验的用户
# =============================================================================
# 运行方式（在 PowerShell 中粘贴以下命令）：
# irm https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-setup/main/install-claude-windows.ps1 | iex
# =============================================================================

# 设置编码，确保中文显示正常
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ---- 辅助函数 ----
function Write-Title {
    param([string]$Text)
    Write-Host "`n  $Text" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Text)
    Write-Host "  [OK] $Text" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host "  [!]  $Text" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Text)
    Write-Host "  [X]  $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "  -->  $Text" -ForegroundColor Blue
}

function Write-Line {
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}

function Wait-Enter {
    Write-Host ""
    Read-Host "  按回车键继续"
    Write-Host ""
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# ---- 欢迎界面 ----
Clear-Host
Write-Line
Write-Host ""
Write-Host "       Claude Code 一键安装向导 (Windows 版)" -ForegroundColor Cyan
Write-Host ""
Write-Host "  本向导将帮助您在 Windows 上安装并配置 Claude Code。" -ForegroundColor Yellow
Write-Host "  全程约需 5-15 分钟，请按提示一步步操作。" -ForegroundColor Yellow
Write-Host ""
Write-Line
Wait-Enter

# ---- 步骤 1：系统检查 ----
Clear-Host
Write-Line
Write-Title "步骤 1/4：检查系统环境"
Write-Line
Write-Host ""

# 检查 Windows 版本
$winVer = [System.Environment]::OSVersion.Version
$winBuild = (Get-WmiObject -Class Win32_OperatingSystem).BuildNumber
Write-Info "检测到 Windows 版本：$($winVer.Major).$($winVer.Minor) (Build $winBuild)"

if ($winVer.Major -lt 10) {
    Write-Err "您的 Windows 版本太旧，Claude Code 需要 Windows 10 或更高版本。"
    Write-Warn "请先升级系统后再运行此脚本。"
    Wait-Enter
    exit 1
}
Write-Ok "Windows 版本检查通过"

# 检查 PowerShell 版本
$psVer = $PSVersionTable.PSVersion.Major
Write-Info "PowerShell 版本：$psVer"
if ($psVer -lt 5) {
    Write-Warn "PowerShell 版本较低，建议升级到 5.1 或以上"
}

# 检查执行策略
$execPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($execPolicy -eq "Restricted" -or $execPolicy -eq "AllSigned") {
    Write-Warn "需要调整 PowerShell 脚本执行权限..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Ok "权限设置完成"
} else {
    Write-Ok "PowerShell 执行权限正常"
}

# 检查是否已安装 Claude Code
$claudeExe = "$env:USERPROFILE\.local\bin\claude.exe"
if (Test-Path $claudeExe) {
    try {
        $claudeVer = & $claudeExe --version 2>$null | Select-Object -First 1
        Write-Ok "检测到 Claude Code 已安装！（$claudeVer）"
        Write-Host ""
        Write-Host "  Claude Code 已安装，是否要重新安装/更新？" -ForegroundColor Yellow
        Write-Host ""
        $choice = Read-Host "  重新安装/更新？[y/N]"
        if ($choice -notmatch "^[Yy]$") {
            $script:SkipInstall = $true
        }
    } catch {
        Write-Warn "检测到旧版安装，将进行更新..."
    }
}

# ---- 步骤 2：账号确认 ----
Clear-Host
Write-Line
Write-Title "步骤 2/4：选择您的接入方式"
Write-Line
Write-Host ""
Write-Host "  Claude Code 支持以下接入方式，任选其一：" -ForegroundColor White
Write-Host ""
Write-Host "  【方式 A：Anthropic 官方账号】（个人用户推荐）" -ForegroundColor Green
Write-Host "  • Claude Pro 套餐（月付约 `$20）"
Write-Host "  • Claude Max 套餐（月付约 `$100+）"
Write-Host "  • Anthropic Console API 账号（按用量计费）"
Write-Host ""
Write-Host "  【方式 B：第三方云平台 API】（已有云账号的企业用户）" -ForegroundColor Green
Write-Host "  • Amazon Bedrock（AWS 用户）"
Write-Host "  • Google Vertex AI（GCP 用户）"
Write-Host "  • Microsoft Azure AI Foundry（Azure 用户）"
Write-Host ""
Write-Host "  注意：免费 Claude.ai 账号不支持 Claude Code" -ForegroundColor Red
Write-Host ""
Write-Line
Write-Host ""
Write-Host "  还没有账号？前往注册 Anthropic 账号：" -ForegroundColor Yellow
Write-Host "    https://claude.ai/upgrade" -ForegroundColor Cyan
Write-Host ""

$hasAccount = Read-Host "  您已有符合条件的账号或云平台凭证了吗？[Y/n]"
if ($hasAccount -match "^[Nn]$") {
    Write-Host ""
    Write-Info "请先准备好以下之一："
    Write-Info "  A) 访问 https://claude.ai/upgrade 注册 Claude Pro/Max 账号"
    Write-Info "  B) 联系公司 IT 获取 AWS/GCP/Azure 的 API 凭证"
    Write-Info "准备好后重新运行本脚本。"
    Write-Host ""
    exit 0
}

Write-Ok "确认完毕，继续安装..."
Wait-Enter

# ---- API 配置 ----
Clear-Host
Write-Line
Write-Title "步骤 2.5/4：配置 API Key"
Write-Line
Write-Host ""
Write-Host "  请选择您的接入方式：" -ForegroundColor White
Write-Host ""
Write-Host "  [1] ★ 推荐  第三方中转 API" -ForegroundColor Yellow
Write-Host "      价格便宜（约官方 1/3~1/10），按量计费，国内直连"
Write-Host ""
Write-Host "  [2]         Anthropic 官方账号（Claude Pro/Max/Console）"
Write-Host "      直接在 claude.ai 购买，最官方"
Write-Host ""
Write-Host "  [3]         大厂云平台（AWS Bedrock / Google Vertex）"
Write-Host "      公司已有云账号时使用"
Write-Host ""
Write-Host "  [4]         跳过，稍后手动配置"
Write-Host ""

$methodChoice = Read-Host "  请输入选项 [1/2/3/4]（直接回车默认选 1）"
if ([string]::IsNullOrWhiteSpace($methodChoice)) { $methodChoice = "1" }

# ---- 方式 1：中转 API ----
if ($methodChoice -eq "1") {
    Clear-Host
    Write-Line
    Write-Title "配置中转 API"
    Write-Line
    Write-Host ""
    Write-Host "  您需要从中转服务商处获取两样东西：" -ForegroundColor Yellow
    Write-Host "    • API 地址（Base URL）  例如：https://api.example.com" -ForegroundColor Cyan
    Write-Host "    • API Key               例如：sk-xxxxxxxxxxxxxxxx" -ForegroundColor Cyan
    Write-Host ""

    do {
        $baseUrl = Read-Host "  请粘贴 API 地址（Base URL）"
        $baseUrl = $baseUrl.TrimEnd('/')
        if (-not $baseUrl.StartsWith("http")) {
            Write-Warn "地址应以 http:// 或 https:// 开头，请重新输入"
        }
    } while (-not $baseUrl.StartsWith("http"))
    Write-Ok "地址格式正确"
    Write-Host ""

    do {
        $apiKey = Read-Host "  请粘贴 API Key"
        if ($apiKey.Length -lt 8) { Write-Warn "API Key 看起来太短，请确认后重新输入" }
    } while ($apiKey.Length -lt 8)
    Write-Ok "API Key 已输入"

    Write-Host ""
    Write-Info "正在写入系统环境变量（用户级，重启后永久生效）..."

    # 备份旧配置（如果存在）
    $script:OldBaseUrl = [System.Environment]::GetEnvironmentVariable("ANTHROPIC_BASE_URL", "User")
    $script:OldApiKey = [System.Environment]::GetEnvironmentVariable("ANTHROPIC_API_KEY", "User")

    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $baseUrl, "User")
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $apiKey, "User")
    # 当前会话也生效
    $env:ANTHROPIC_BASE_URL = $baseUrl
    $env:ANTHROPIC_API_KEY  = $apiKey
    Write-Ok "配置已保存！"

    # ---- 写入 .claude.json 以绕过 Claude Code 2.0 强制登录 ----
    Write-Info "正在写入 .claude.json 以跳过登录验证..."
    $claudeJsonPath = "$env:USERPROFILE\.claude.json"
    $claudeJsonContent = @"
{
  "hasCompletedOnboarding": true,
  "primaryApiKey": "$apiKey"
}
"@
    $claudeJsonContent | Set-Content -Path $claudeJsonPath -Encoding UTF8
    Write-Ok "已自动绕过 Claude Code 2.0 强制登录，无需浏览器授权！"

    $script:UseRelay = $true

# ---- 方式 2：官方账号 ----
} elseif ($methodChoice -eq "2") {
    Clear-Host
    Write-Line
    Write-Title "Anthropic 官方账号"
    Write-Line
    Write-Host ""
    Write-Host "  官方账号使用浏览器授权，无需手动配置 API Key。" -ForegroundColor Yellow
    Write-Host "  安装完成后输入 claude，系统会自动打开浏览器让您登录。" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  如果还没有付费账号，请先注册：https://claude.ai/upgrade" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "  已有付费账号，按回车继续"
    $script:UseOfficial = $true

# ---- 方式 3：大厂云平台 ----
} elseif ($methodChoice -eq "3") {
    Clear-Host
    Write-Line
    Write-Title "大厂云平台 API"
    Write-Line
    Write-Host ""
    Write-Host "  请选择云平台：" -ForegroundColor Yellow
    Write-Host "  [1] Amazon Bedrock" -ForegroundColor Cyan
    Write-Host "  [2] Google Vertex AI" -ForegroundColor Cyan
    Write-Host ""
    $cloudChoice = Read-Host "  选择 [1/2]"

    if ($cloudChoice -eq "1") {
        $awsRegion = Read-Host "  AWS_REGION（直接回车默认 us-east-1）"
        if ([string]::IsNullOrWhiteSpace($awsRegion)) { $awsRegion = "us-east-1" }
        $awsKey    = Read-Host "  AWS_ACCESS_KEY_ID"
        $awsSecret = Read-Host "  AWS_SECRET_ACCESS_KEY"

        # 备份旧配置
        $script:OldBedrockConfig = @{
            UseBedrock = [System.Environment]::GetEnvironmentVariable("CLAUDE_CODE_USE_BEDROCK","User")
            Region = [System.Environment]::GetEnvironmentVariable("AWS_REGION","User")
            KeyId = [System.Environment]::GetEnvironmentVariable("AWS_ACCESS_KEY_ID","User")
            Secret = [System.Environment]::GetEnvironmentVariable("AWS_SECRET_ACCESS_KEY","User")
        }

        [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_USE_BEDROCK","1","User")
        [System.Environment]::SetEnvironmentVariable("AWS_REGION",$awsRegion,"User")
        [System.Environment]::SetEnvironmentVariable("AWS_ACCESS_KEY_ID",$awsKey,"User")
        [System.Environment]::SetEnvironmentVariable("AWS_SECRET_ACCESS_KEY",$awsSecret,"User")
        $env:CLAUDE_CODE_USE_BEDROCK = "1"
        $env:AWS_REGION = $awsRegion
    } elseif ($cloudChoice -eq "2") {
        $gcpRegion  = Read-Host "  CLOUD_ML_REGION（直接回车默认 us-east5）"
        if ([string]::IsNullOrWhiteSpace($gcpRegion)) { $gcpRegion = "us-east5" }
        $gcpProject = Read-Host "  ANTHROPIC_VERTEX_PROJECT_ID"

        # 备份旧配置
        $script:OldVertexConfig = @{
            UseVertex = [System.Environment]::GetEnvironmentVariable("CLAUDE_CODE_USE_VERTEX","User")
            Region = [System.Environment]::GetEnvironmentVariable("CLOUD_ML_REGION","User")
            ProjectId = [System.Environment]::GetEnvironmentVariable("ANTHROPIC_VERTEX_PROJECT_ID","User")
        }

        [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_USE_VERTEX","1","User")
        [System.Environment]::SetEnvironmentVariable("CLOUD_ML_REGION",$gcpRegion,"User")
        [System.Environment]::SetEnvironmentVariable("ANTHROPIC_VERTEX_PROJECT_ID",$gcpProject,"User")
        $env:CLAUDE_CODE_USE_VERTEX = "1"
    }
    Write-Ok "云平台配置已保存！"

} else {
    Write-Info "跳过 API 配置，您可以在安装完成后手动设置环境变量。"
}

# ---- 步骤 3：安装 Git for Windows（必需前提） ----
if (-not $script:SkipInstall) {
    Clear-Host
    Write-Line
    Write-Title "步骤 3/4（前置）：安装 Git for Windows"
    Write-Line
    Write-Host ""
    Write-Host "  Claude Code 在 Windows 上需要 Git for Windows 才能运行。" -ForegroundColor Yellow
    Write-Host "  这是一个免费工具，我们来检查是否已安装。" -ForegroundColor Yellow
    Write-Host ""

    # 检查 Git 是否已安装
    $gitInstalled = $false
    $gitPaths = @(
        "C:\Program Files\Git\bin\bash.exe",
        "C:\Program Files (x86)\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )

    foreach ($path in $gitPaths) {
        if (Test-Path $path) {
            $gitInstalled = $true
            $gitBashPath = $path
            break
        }
    }

    # 也检查 PATH 中的 git
    if (-not $gitInstalled) {
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if ($gitCmd) {
            $gitDir = Split-Path (Split-Path $gitCmd.Source -Parent) -Parent
            $bashPath = Join-Path $gitDir "bin\bash.exe"
            if (Test-Path $bashPath) {
                $gitInstalled = $true
                $gitBashPath = $bashPath
            }
        }
    }

    if ($gitInstalled) {
        Write-Ok "Git for Windows 已安装！路径：$gitBashPath"
    } else {
        Write-Warn "未检测到 Git for Windows，需要安装..."
        Write-Host ""

        # 尝试用 winget 安装
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            Write-Info "正在使用 Windows 包管理器 (winget) 安装 Git..."
            Write-Host ""
            winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements

            # 刷新 PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("Path", "User")

            # 再次检查
            if (Test-Path "C:\Program Files\Git\bin\bash.exe") {
                Write-Ok "Git for Windows 安装成功！"
                $gitBashPath = "C:\Program Files\Git\bin\bash.exe"
            } else {
                Write-Warn "自动安装可能需要重启终端生效，继续执行..."
            }
        } else {
            # 手动下载安装
            Write-Host ""
            Write-Host "  即将打开 Git for Windows 下载页面..." -ForegroundColor Yellow
            Write-Host "  请下载并安装（所有选项保持默认即可），安装完成后回来继续。" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "  按回车键打开下载页面"
            Start-Process "https://git-scm.com/download/win"
            Write-Host ""
            Write-Host "  请在 Git 安装完成后，按回车键继续..." -ForegroundColor Yellow
            Wait-Enter
        }
    }

    # ---- 安装 Claude Code ----
    Clear-Host
    Write-Line
    Write-Title "步骤 3/4：下载并安装 Claude Code"
    Write-Line
    Write-Host ""
    Write-Info "正在从官方服务器下载 Claude Code..."
    Write-Info "这可能需要 2-5 分钟，请耐心等待，期间请勿关闭窗口。"
    Write-Host ""
    Write-Line
    Write-Host ""

    try {
        # 运行官方 PowerShell 安装脚本
        Write-Info "正在下载官方安装脚本..."

        # 使用正确的方式下载并执行安装脚本
        # 添加 User-Agent 和其他必要的头信息
        $headers = @{
            'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }

        $useBackupMethod = $false

        try {
            # 尝试下载官方安装脚本，添加更多头信息以绕过 Cloudflare
            $installScript = Invoke-RestMethod -Uri "https://claude.ai/install.ps1" `
                -Headers $headers `
                -MaximumRedirection 5 `
                -ErrorAction Stop

            # 检查是否下载到了 HTML 而不是脚本
            if ($installScript -match "<!DOCTYPE|<html|<title>") {
                Write-Warn "下载的内容是 HTML 页面，切换到备用安装方式..."
                $useBackupMethod = $true
            }
        } catch {
            Write-Warn "主安装源连接失败（$($_.Exception.Message)），切换到备用方案..."
            $useBackupMethod = $true
        }

        if ($useBackupMethod) {
            # 备用方案：优先使用 npm 安装（最简单可靠）
            $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
            $npmCmd = Get-Command npm -ErrorAction SilentlyContinue

            # 如果没有 Node.js，提供安装选项
            if (-not $nodeCmd) {
                Write-Host ""
                Write-Host "  检测到系统未安装 Node.js" -ForegroundColor Yellow
                Write-Host "  Node.js 可以让安装过程更快速、更稳定" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "  是否现在安装 Node.js？（推荐）" -ForegroundColor Cyan
                Write-Host "  • 选择 Y：自动安装 Node.js，然后用 npm 安装 Claude Code（推荐）" -ForegroundColor White
                Write-Host "  • 选择 N：跳过，使用传统下载方式（较慢，可能不稳定）" -ForegroundColor White
                Write-Host ""

                $installNode = Read-Host "  是否安装 Node.js？[Y/n]"

                if ($installNode -notmatch "^[Nn]$") {
                    Write-Info "正在安装 Node.js..."
                    Write-Host ""

                    # 检查是否有 winget
                    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
                    if ($wingetCmd) {
                        Write-Info "使用 winget 安装 Node.js LTS 版本..."
                        $wingetProcess = Start-Process -FilePath "winget" -ArgumentList "install", "--id", "OpenJS.NodeJS.LTS", "-e", "--source", "winget", "--accept-package-agreements", "--accept-source-agreements" -NoNewWindow -Wait -PassThru

                        if ($wingetProcess.ExitCode -eq 0) {
                            Write-Ok "Node.js 安装成功！"

                            # 刷新 PATH
                            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                                        [System.Environment]::GetEnvironmentVariable("Path", "User")

                            # 重新检测
                            $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
                            $npmCmd = Get-Command npm -ErrorAction SilentlyContinue

                            if ($nodeCmd -and $npmCmd) {
                                Write-Ok "Node.js 和 npm 已就绪！"
                            } else {
                                Write-Warn "Node.js 安装完成，但可能需要重启 PowerShell 才能生效"
                                Write-Info "继续使用传统下载方式..."
                            }
                        } else {
                            Write-Warn "Node.js 安装失败，继续使用传统下载方式..."
                        }
                    } else {
                        # 没有 winget，提供手动安装指引
                        Write-Warn "未检测到 winget（Windows 包管理器）"
                        Write-Host ""
                        Write-Host "  请手动安装 Node.js：" -ForegroundColor Yellow
                        Write-Host "  1. 访问：https://nodejs.org/zh-cn/" -ForegroundColor Cyan
                        Write-Host "  2. 下载并安装 LTS 版本" -ForegroundColor Cyan
                        Write-Host "  3. 安装完成后重新运行本脚本" -ForegroundColor Cyan
                        Write-Host ""

                        $openBrowser = Read-Host "  是否现在打开 Node.js 下载页面？[Y/n]"
                        if ($openBrowser -notmatch "^[Nn]$") {
                            Start-Process "https://nodejs.org/zh-cn/"
                            Write-Host ""
                            Write-Info "请在安装 Node.js 后重新运行本脚本以获得最佳体验"
                            Write-Info "现在将继续使用传统下载方式..."
                            Write-Host ""
                            Start-Sleep -Seconds 3
                        }
                    }
                } else {
                    Write-Info "跳过 Node.js 安装，使用传统下载方式..."
                }
                Write-Host ""
            }

            if ($nodeCmd -and $npmCmd) {
                Write-Info "检测到 Node.js 和 npm，使用 npm 安装（推荐方式）..."
                Write-Host ""

                try {
                    # 使用 npm 全局安装
                    Write-Info "正在执行：npm install -g @anthropic-ai/claude-code"
                    $npmProcess = Start-Process -FilePath "npm" -ArgumentList "install", "-g", "@anthropic-ai/claude-code" -NoNewWindow -Wait -PassThru

                    if ($npmProcess.ExitCode -eq 0) {
                        Write-Ok "Claude Code 安装成功！"
                        Write-Host ""

                        # npm 全局安装会自动添加到 PATH，无需手动配置
                        # 刷新当前会话的 PATH
                        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                                    [System.Environment]::GetEnvironmentVariable("Path", "User")

                        # 跳过后续的手动下载步骤
                        $script:NpmInstallSuccess = $true
                    } else {
                        throw "npm 安装失败，退出码：$($npmProcess.ExitCode)"
                    }
                } catch {
                    Write-Warn "npm 安装失败（$($_.Exception.Message)），尝试手动下载..."
                    $script:NpmInstallSuccess = $false
                }
            }

            # 如果 npm 安装失败或没有 npm，使用手动下载方式
            if (-not $script:NpmInstallSuccess) {
                Write-Info "使用备用方案：直接从官方 Google Cloud Storage 下载..."

                # 创建安装目录
                $installDir = "$env:USERPROFILE\.local\bin"
                $downloadDir = "$env:USERPROFILE\.claude\downloads"
                if (-not (Test-Path $installDir)) {
                    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
                }
                if (-not (Test-Path $downloadDir)) {
                    New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
                }

                # 检测系统架构
                if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
                    $platform = "win32-arm64"
                } else {
                    $platform = "win32-x64"
                }

                # 获取最新版本号
                Write-Info "正在获取最新版本信息..."
                $gcsBucket = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"
                try {
                $version = Invoke-RestMethod -Uri "$gcsBucket/latest" -ErrorAction Stop
                Write-Info "最新版本：$version"

                # 下载并解压
                $zipUrl = "$gcsBucket/$version/claude-code-$platform.zip"
                $zipPath = Join-Path $downloadDir "claude-code-$platform.zip"

                # 检查是否安装了 Node.js
                $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
                if ($nodeCmd) {
                    Write-Info "检测到 Node.js，使用 Node.js 下载（更稳定，约 50-100MB）..."

                    # 创建临时的 Node.js 下载脚本
                    $nodeScript = @"
const https = require('https');
const fs = require('fs');
const url = '$($zipUrl.Replace('\', '\\'))';
const dest = '$($zipPath.Replace('\', '\\'))';

console.log('开始下载...');
const file = fs.createWriteStream(dest);
https.get(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
}, (response) => {
    const total = parseInt(response.headers['content-length'], 10);
    let downloaded = 0;
    response.on('data', (chunk) => {
        downloaded += chunk.length;
        const percent = ((downloaded / total) * 100).toFixed(1);
        process.stdout.write('\r下载进度: ' + percent + '%');
    });
    response.pipe(file);
    file.on('finish', () => {
        file.close();
        console.log('\n下载完成！');
    });
}).on('error', (err) => {
    fs.unlink(dest, () => {});
    console.error('下载失败:', err.message);
    process.exit(1);
});
"@
                    $nodeScriptPath = Join-Path $downloadDir "download.js"
                    $nodeScript | Set-Content -Path $nodeScriptPath -Encoding UTF8

                    # 执行 Node.js 下载
                    $nodeProcess = Start-Process -FilePath "node" -ArgumentList $nodeScriptPath -NoNewWindow -Wait -PassThru

                    # 清理临时脚本
                    Remove-Item $nodeScriptPath -Force -ErrorAction SilentlyContinue

                    if ($nodeProcess.ExitCode -ne 0 -or -not (Test-Path $zipPath)) {
                        throw "Node.js 下载失败"
                    }
                    Write-Ok "下载完成！"
                } else {
                    Write-Info "正在下载 Claude Code（约 50-100MB，请耐心等待）..."
                    # 使用 WebClient 以支持更好的错误处理
                    $webClient = New-Object System.Net.WebClient
                    $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
                    $webClient.DownloadFile($zipUrl, $zipPath)
                    Write-Ok "下载完成！"
                }

                Write-Info "正在解压..."
                Expand-Archive -Path $zipPath -DestinationPath $downloadDir -Force

                # 复制到安装目录
                $exePath = Join-Path $downloadDir "claude.exe"
                $targetPath = Join-Path $installDir "claude.exe"
                Copy-Item -Path $exePath -Destination $targetPath -Force
                Write-Ok "安装完成！"

                # 清理临时文件
                Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
                Remove-Item $exePath -Force -ErrorAction SilentlyContinue

            } catch {
                # 如果 GCS 也失败，尝试 GitHub releases
                Write-Warn "官方源下载失败（$($_.Exception.Message)）"
                Write-Info "尝试从 GitHub releases 下载..."

                try {
                    $claudeUrl = "https://github.com/anthropics/claude-code/releases/latest/download/claude-windows-x64.exe"
                    $claudePath = Join-Path $installDir "claude.exe"

                    # 检查是否安装了 Node.js
                    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
                    if ($nodeCmd) {
                        Write-Info "检测到 Node.js，使用 Node.js 下载（更稳定）..."

                        # 创建临时的 Node.js 下载脚本
                        $nodeScript = @"
const https = require('https');
const fs = require('fs');
const url = '$($claudeUrl.Replace('\', '\\'))';
const dest = '$($claudePath.Replace('\', '\\'))';

console.log('开始下载...');
const file = fs.createWriteStream(dest);
https.get(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
}, (response) => {
    if (response.statusCode === 302 || response.statusCode === 301) {
        https.get(response.headers.location, (res) => {
            const total = parseInt(res.headers['content-length'], 10);
            let downloaded = 0;
            res.on('data', (chunk) => {
                downloaded += chunk.length;
                const percent = ((downloaded / total) * 100).toFixed(1);
                process.stdout.write('\r下载进度: ' + percent + '%');
            });
            res.pipe(file);
            file.on('finish', () => {
                file.close();
                console.log('\n下载完成！');
            });
        }).on('error', (err) => {
            fs.unlink(dest, () => {});
            console.error('下载失败:', err.message);
            process.exit(1);
        });
    } else {
        const total = parseInt(response.headers['content-length'], 10);
        let downloaded = 0;
        response.on('data', (chunk) => {
            downloaded += chunk.length;
            const percent = ((downloaded / total) * 100).toFixed(1);
            process.stdout.write('\r下载进度: ' + percent + '%');
        });
        response.pipe(file);
        file.on('finish', () => {
            file.close();
            console.log('\n下载完成！');
        });
    }
}).on('error', (err) => {
    fs.unlink(dest, () => {});
    console.error('下载失败:', err.message);
    process.exit(1);
});
"@
                        $nodeScriptPath = Join-Path $downloadDir "download.js"
                        $nodeScript | Set-Content -Path $nodeScriptPath -Encoding UTF8

                        # 执行 Node.js 下载
                        $nodeProcess = Start-Process -FilePath "node" -ArgumentList $nodeScriptPath -NoNewWindow -Wait -PassThru

                        # 清理临时脚本
                        Remove-Item $nodeScriptPath -Force -ErrorAction SilentlyContinue

                        if ($nodeProcess.ExitCode -eq 0 -and (Test-Path $claudePath)) {
                            Write-Ok "使用 Node.js 下载完成！"
                        } else {
                            throw "Node.js 下载失败"
                        }
                    } else {
                        # 使用 PowerShell 下载
                        Write-Info "正在下载（约 50-100MB，请耐心等待）..."
                        $webClient = New-Object System.Net.WebClient
                        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
                        $webClient.DownloadFile($claudeUrl, $claudePath)
                        Write-Ok "从 GitHub 下载完成！"
                    }
                } catch {
                    # 最后的尝试：提供手动下载指引
                    Write-Err "自动下载失败：$($_.Exception.Message)"
                    Write-Host ""
                    Write-Host "  可能的原因：" -ForegroundColor Yellow
                    Write-Host "  1. 网络连接不稳定或速度较慢" -ForegroundColor Yellow
                    Write-Host "  2. 需要配置代理才能访问 GitHub/Google" -ForegroundColor Yellow
                    Write-Host "  3. 防火墙或杀毒软件拦截了下载" -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "  手动安装方法：" -ForegroundColor Cyan
                    Write-Host "  1. 在浏览器中打开以下任一链接下载：" -ForegroundColor White
                    Write-Host "     • $claudeUrl" -ForegroundColor Gray
                    Write-Host "     或" -ForegroundColor White
                    Write-Host "     • $zipUrl" -ForegroundColor Gray
                    Write-Host ""
                    Write-Host "  2. 将下载的文件重命名为 claude.exe" -ForegroundColor White
                    Write-Host "  3. 移动到：$installDir" -ForegroundColor White
                    Write-Host "  4. 重启 PowerShell 后输入 claude 即可使用" -ForegroundColor White
                    Write-Host ""
                    throw "自动下载失败，请参考上述手动安装方法"
                }
            }

                # 添加到 PATH（仅在手动下载时需要，npm 会自动处理）
                if (-not $script:NpmInstallSuccess) {
                    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
                    if ($userPath -notlike "*$installDir*") {
                        [System.Environment]::SetEnvironmentVariable("Path", "$userPath;$installDir", "User")
                        Write-Ok "已添加到系统 PATH"
                    }
                }
            }
        } elseif ($installScript -and -not [string]::IsNullOrWhiteSpace($installScript)) {
            Write-Info "正在执行官方安装脚本..."
            & ([scriptblock]::Create($installScript))
        }

        Write-Host ""
        Write-Line
        Write-Host ""
    } catch {
        Write-Host ""
        Write-Err "安装过程中出现错误：$($_.Exception.Message)"

        # 回滚配置
        Write-Info "正在回滚配置..."

        if ($script:OldBaseUrl -or $script:OldApiKey) {
            if ($script:OldBaseUrl) {
                [System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $script:OldBaseUrl, "User")
            } else {
                [System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $null, "User")
            }
            if ($script:OldApiKey) {
                [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $script:OldApiKey, "User")
            } else {
                [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $null, "User")
            }
        }

        if ($script:OldBedrockConfig) {
            [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_USE_BEDROCK", $script:OldBedrockConfig.UseBedrock, "User")
            [System.Environment]::SetEnvironmentVariable("AWS_REGION", $script:OldBedrockConfig.Region, "User")
            [System.Environment]::SetEnvironmentVariable("AWS_ACCESS_KEY_ID", $script:OldBedrockConfig.KeyId, "User")
            [System.Environment]::SetEnvironmentVariable("AWS_SECRET_ACCESS_KEY", $script:OldBedrockConfig.Secret, "User")
        }

        if ($script:OldVertexConfig) {
            [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_USE_VERTEX", $script:OldVertexConfig.UseVertex, "User")
            [System.Environment]::SetEnvironmentVariable("CLOUD_ML_REGION", $script:OldVertexConfig.Region, "User")
            [System.Environment]::SetEnvironmentVariable("ANTHROPIC_VERTEX_PROJECT_ID", $script:OldVertexConfig.ProjectId, "User")
        }

        # 删除可能创建的 .claude.json
        $claudeJsonPath = "$env:USERPROFILE\.claude.json"
        if (Test-Path $claudeJsonPath) {
            Remove-Item $claudeJsonPath -Force
        }

        Write-Ok "配置已回滚"
        Write-Host ""
        Write-Host "  请检查以下事项：" -ForegroundColor Yellow
        Write-Host "  1. 确认网络连接正常（可以打开 claude.ai 网站）" -ForegroundColor Yellow
        Write-Host "  2. 确认已安装 Git for Windows" -ForegroundColor Yellow
        Write-Host "  3. 尝试稍后重新运行本脚本" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  如需帮助，请访问：https://code.claude.com/docs/en/troubleshooting" -ForegroundColor Cyan
        Wait-Enter
        exit 1
    }

    # 刷新 PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" +
                "$env:USERPROFILE\.local\bin"
}

# ---- 验证安装 ----
Write-Host ""
Write-Line
Write-Title "验证安装结果"
Write-Line
Write-Host ""

Start-Sleep -Seconds 2

$claudeExePath = "$env:USERPROFILE\.local\bin\claude.exe"
$claudeInPath = Get-Command claude -ErrorAction SilentlyContinue

if ($claudeInPath) {
    $claudeVer = & claude --version 2>$null | Select-Object -First 1
    Write-Ok "Claude Code 安装成功！版本：$claudeVer"
} elseif (Test-Path $claudeExePath) {
    Write-Ok "Claude Code 已安装到：$claudeExePath"
    Write-Warn "需要重启 PowerShell 后才能直接使用 'claude' 命令"
    $script:NeedRestart = $true
} else {
    Write-Err "安装验证失败，请尝试重启 PowerShell 后手动运行 'claude --version'"
}

# ---- 步骤 4：启动测试 ----
Clear-Host
Write-Line
Write-Title "步骤 4/4：启动测试"
Write-Line
Write-Host ""

if ($script:UseRelay) {
    Write-Host "  [OK] 您使用的是中转 API，无需浏览器登录，直接启动即可！" -ForegroundColor Green
    Write-Host ""
    Write-Host "  启动方式：" -ForegroundColor White
    Write-Host "  1.  打开 PowerShell" -ForegroundColor Cyan
    Write-Host "  2.  输入 claude 按回车，即可开始对话" -ForegroundColor Cyan
} elseif ($script:UseOfficial) {
    Write-Host "  官方账号使用浏览器授权：" -ForegroundColor White
    Write-Host ""
    Write-Host "  1.  输入 claude 并按回车" -ForegroundColor Cyan
    Write-Host "  2.  系统自动打开浏览器" -ForegroundColor Cyan
    Write-Host "  3.  登录 Claude 账号并点击授权" -ForegroundColor Cyan
    Write-Host "  4.  回到 PowerShell 即可使用" -ForegroundColor Cyan
} else {
    Write-Host "  输入 claude 按回车启动，根据您的配置完成后续授权。" -ForegroundColor White
}

Write-Host ""
Write-Line
Write-Host ""

if ($script:NeedRestart) {
    Write-Warn "需要先重启 PowerShell 才能使用！"
    Write-Host ""
    Write-Host "  1.  关闭当前 PowerShell 窗口" -ForegroundColor Cyan
    Write-Host "  2.  重新打开 PowerShell（Win+R → powershell → 回车）" -ForegroundColor Cyan
    Write-Host "  3.  输入 claude 开始使用" -ForegroundColor Cyan
} else {
    $startNow = Read-Host "  是否现在立即测试启动？[Y/n]"
    if ($startNow -notmatch "^[Nn]$") {
        Write-Host ""
        Write-Info "正在启动 Claude Code..."
        Write-Host ""
        Start-Sleep -Seconds 1
        & claude
    }
}

# ---- 完成 ----
Clear-Host
Write-Line
Write-Host ""
Write-Host "  [完成] 恭喜！安装配置完成！" -ForegroundColor Green
Write-Host ""
Write-Line
Write-Host ""
Write-Host "  快速使用指南：" -ForegroundColor White
Write-Host ""
Write-Host "  【如何启动】" -ForegroundColor Cyan
Write-Host "  打开 PowerShell → 输入 claude → 按回车 → 开始对话"
Write-Host ""
Write-Host "  【在项目文件夹中使用】" -ForegroundColor Cyan
Write-Host "  在文件资源管理器中打开项目文件夹"
Write-Host "  按住 Shift，右键点击空白处 → 选择在此处打开 PowerShell 窗口"
Write-Host "  然后输入 claude 开始工作"
Write-Host ""
Write-Host "  【常用对话示例】" -ForegroundColor Cyan
Write-Host "  - 帮我看看这个文件夹里有什么"
Write-Host "  - 帮我写一个 Python 脚本，统计 CSV 文件的行数"
Write-Host "  - 我的代码报错了，帮我找原因"
Write-Host ""
Write-Host "  【完整使用指南】" -ForegroundColor Cyan
Write-Host "  请查看：claude-code-guide.md 文档"
Write-Host "  或访问官方文档：https://code.claude.com/docs/en/quickstart" -ForegroundColor Cyan
Write-Host ""
Write-Line
Write-Host ""
Write-Host "  安装脚本执行完毕。感谢使用！" -ForegroundColor Green
Write-Host ""
Read-Host "  按回车键退出"
