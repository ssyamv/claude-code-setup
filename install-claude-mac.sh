#!/bin/bash
# =============================================================================
# Claude Code 一键安装脚本 (macOS 版)
# 适合完全没有编程经验的用户
# =============================================================================
# 运行方式（在终端中粘贴以下命令）：
# curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-setup/main/install-claude-mac.sh | bash
# =============================================================================

# ---- 检测 Shell 配置文件 ----
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG="$HOME/.bash_profile"
else
    SHELL_CONFIG="$HOME/.profile"
fi

# ---- 颜色定义 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # 重置颜色

# ---- 辅助函数 ----
print_line() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_title() {
    echo -e "${BOLD}${CYAN}$1${NC}"
}

print_ok() {
    echo -e "  ${GREEN}✅ $1${NC}"
}

print_warn() {
    echo -e "  ${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "  ${RED}❌ $1${NC}"
}

print_info() {
    echo -e "  ${BLUE}ℹ️  $1${NC}"
}

press_enter() {
    echo ""
    read -p "  👉 按回车键继续..." _dummy </dev/tty
    echo ""
}

# ---- 欢迎界面 ----
clear
print_line
echo ""
print_title "     🤖 Claude Code 一键安装向导 (macOS 版)"
echo ""
echo -e "  ${YELLOW}本向导将帮助您在 Mac 上安装并配置 Claude Code。${NC}"
echo -e "  ${YELLOW}全程约需 3～10 分钟，请按提示一步步操作。${NC}"
echo ""
print_line
press_enter

# ---- 步骤 1：检查系统版本 ----
clear
print_line
print_title "  📋 步骤 1/4：检查系统环境"
print_line
echo ""

# 检查操作系统
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "此脚本只能在 macOS 上运行。"
    print_info "如果您使用的是 Windows，请改用 Windows 版安装脚本。"
    exit 1
fi

# 检查 macOS 版本
MACOS_VERSION=$(sw_vers -productVersion 2>/dev/null)
MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
if [ "$MACOS_MAJOR" -lt 10 ]; then
    print_warn "检测到 macOS $MACOS_VERSION（版本过旧）"
    print_warn "Claude Code 可能无法在此版本上运行。"
    echo ""
    echo -e "  ${YELLOW}建议您先升级系统，再运行此脚本。${NC}"
    echo -e "  ${YELLOW}升级方法：点击左上角苹果图标 → 系统设置 → 通用 → 软件更新${NC}"
    press_enter
    exit 1
else
    print_ok "macOS $MACOS_VERSION 系统检查通过"
fi

# 检查是否已安装
if command -v claude &>/dev/null; then
    CLAUDE_VER=$(claude --version 2>/dev/null | head -n1)
    print_ok "检测到 Claude Code 已安装！（$CLAUDE_VER）"
    echo ""
    echo -e "  ${YELLOW}您已经安装了 Claude Code，是否要重新安装/更新？${NC}"
    echo ""
    read -p "  重新安装/更新？[y/N] " choice </dev/tty
    if [[ ! "$choice" =~ ^[Yy]$ ]]; then
        echo ""
        print_ok "跳过安装，直接进入使用指引..."
        SKIP_INSTALL=true
    fi
fi

# ---- 步骤 2：选择接入方式并配置 API ----
clear
print_line
print_title "  🔑 步骤 2/4：配置 API Key"
print_line
echo ""
echo -e "  ${BOLD}请选择您的接入方式：${NC}"
echo ""
echo -e "  ${YELLOW}[1]${NC} ${GREEN}★ 推荐${NC} 第三方中转 API"
echo -e "      价格便宜（约官方 1/3～1/10），按量计费，国内直连"
echo ""
echo -e "  ${YELLOW}[2]${NC}     Anthropic 官方账号（Claude Pro/Max/Console）"
echo -e "      直接在 claude.ai 购买，最官方"
echo ""
echo -e "  ${YELLOW}[3]${NC}     大厂云平台（AWS Bedrock / Google Vertex / Azure）"
echo -e "      公司已有云账号时使用"
echo ""
echo -e "  ${YELLOW}[4]${NC}     跳过，稍后手动配置"
echo ""

while true; do
    read -p "  请输入选项 [1/2/3/4]（默认 1）: " method_choice </dev/tty
    method_choice="${method_choice:-1}"
    if [[ "$method_choice" =~ ^[1-4]$ ]]; then break; fi
    print_warn "请输入 1、2、3 或 4"
done

# ---- 方式 1：中转 API（推荐）----
if [[ "$method_choice" == "1" ]]; then
    clear
    print_line
    print_title "  🔀 配置中转 API"
    print_line
    echo ""
    echo -e "  ${YELLOW}您需要从中转服务商处获取两样东西：${NC}"
    echo -e "  ${CYAN}  • API 地址（Base URL）${NC} 例如：https://api.example.com"
    echo -e "  ${CYAN}  • API Key${NC}           例如：sk-xxxxxxxxxxxxxxxx"
    echo ""

    # 输入 Base URL
    while true; do
        read -p "  请粘贴 API 地址（Base URL）: " base_url </dev/tty
        base_url="${base_url%/}"  # 去掉末尾斜杠
        # 去除可能的空格和引号
        base_url="$(echo "$base_url" | xargs | sed 's/^[\"'\'']*//;s/[\"'\'']*$//')"
        if [[ "$base_url" =~ ^https?:// ]]; then
            print_ok "地址格式正确"
            break
        else
            print_warn "地址必须以 http:// 或 https:// 开头，请重新输入"
            print_info "示例：https://api.example.com"
        fi
    done

    echo ""

    # 输入 API Key
    while true; do
        read -p "  请粘贴 API Key: " api_key </dev/tty
        if [[ ${#api_key} -gt 8 ]]; then
            print_ok "API Key 已输入"
            break
        else
            print_warn "API Key 看起来太短，请确认后重新输入"
        fi
    done

    echo ""
    print_info "正在配置 Claude Code..."

    # ---- 写入 ~/.claude.json 以绕过 Claude Code 2.0 强制登录 ----
    print_info "正在写入 ~/.claude.json 以跳过登录验证..."
    cat > "$HOME/.claude.json" << EOF
{
  "hasCompletedOnboarding": true,
  "primaryApiKey": "$api_key"
}
EOF
    print_ok "已自动绕过 Claude Code 2.0 强制登录，无需浏览器授权！"

    # ---- 配置 ~/.claude/settings.json（统一配置文件）----
    print_info "正在配置 ~/.claude/settings.json..."
    mkdir -p "$HOME/.claude"

    # 检查是否已存在 settings.json
    if [ -f "$HOME/.claude/settings.json" ]; then
        # 备份现有配置
        cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "已备份现有配置文件"
    fi

    # 写入新配置（包含 API key 和 Base URL）
    cat > "$HOME/.claude/settings.json" << EOF
{
  "env": {
    "ANTHROPIC_API_KEY": "$api_key",
    "ANTHROPIC_BASE_URL": "$base_url",
    "CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "DISABLE_ERROR_REPORTING": "1",
    "DISABLE_TELEMETRY": "1"
  },
  "model": "sonnet"
}
EOF
    print_ok "配置已保存到 ~/.claude/settings.json！"

    USE_RELAY=true

# ---- 方式 2：Anthropic 官方账号 ----
elif [[ "$method_choice" == "2" ]]; then
    clear
    print_line
    print_title "  🏢 Anthropic 官方账号"
    print_line
    echo ""
    echo -e "  ${YELLOW}官方账号使用浏览器授权，无需手动配置 API Key。${NC}"
    echo -e "  安装完成后输入 ${BOLD}claude${NC}，系统会自动打开浏览器让您登录。"
    echo ""
    echo -e "  ${YELLOW}如果还没有付费账号，请先在浏览器中注册：${NC}"
    echo -e "  ${CYAN}  https://claude.ai/upgrade${NC}"
    echo ""
    read -p "  已有付费账号，按回车继续..." _dummy </dev/tty
    USE_OFFICIAL=true

# ---- 方式 3：大厂云平台 ----
elif [[ "$method_choice" == "3" ]]; then
    clear
    print_line
    print_title "  ☁️  大厂云平台 API"
    print_line
    echo ""
    echo -e "  ${YELLOW}请选择您的云平台：${NC}"
    echo -e "  ${CYAN}[1]${NC} Amazon Bedrock"
    echo -e "  ${CYAN}[2]${NC} Google Vertex AI"
    echo ""
    read -p "  选择 [1/2]: " cloud_choice </dev/tty

    mkdir -p "$HOME/.claude"

    # 检查是否已存在 settings.json
    if [ -f "$HOME/.claude/settings.json" ]; then
        cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "已备份现有配置文件"
    fi

    if [[ "$cloud_choice" == "1" ]]; then
        read -p "  AWS_REGION（默认 us-east-1）: " aws_region </dev/tty
        aws_region="${aws_region:-us-east-1}"
        read -p "  AWS_ACCESS_KEY_ID: " aws_key </dev/tty
        read -p "  AWS_SECRET_ACCESS_KEY: " aws_secret </dev/tty

        # 写入 settings.json
        cat > "$HOME/.claude/settings.json" << EOF
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "AWS_REGION": "$aws_region",
    "AWS_ACCESS_KEY_ID": "$aws_key",
    "AWS_SECRET_ACCESS_KEY": "$aws_secret",
    "CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "DISABLE_ERROR_REPORTING": "1",
    "DISABLE_TELEMETRY": "1"
  },
  "model": "sonnet"
}
EOF

    elif [[ "$cloud_choice" == "2" ]]; then
        read -p "  CLOUD_ML_REGION（默认 us-east5）: " gcp_region </dev/tty
        gcp_region="${gcp_region:-us-east5}"
        read -p "  ANTHROPIC_VERTEX_PROJECT_ID: " gcp_project </dev/tty

        # 写入 settings.json
        cat > "$HOME/.claude/settings.json" << EOF
{
  "env": {
    "CLAUDE_CODE_USE_VERTEX": "1",
    "CLOUD_ML_REGION": "$gcp_region",
    "ANTHROPIC_VERTEX_PROJECT_ID": "$gcp_project",
    "CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "DISABLE_ERROR_REPORTING": "1",
    "DISABLE_TELEMETRY": "1"
  },
  "model": "sonnet"
}
EOF
    fi
    print_ok "云平台配置已保存到 ~/.claude/settings.json！"

# ---- 方式 4：跳过 ----
else
    print_info "跳过 API 配置，您可以在安装完成后手动设置环境变量。"
fi

press_enter

# ---- 步骤 3：安装 Claude Code ----
if [ "$SKIP_INSTALL" != true ]; then
    clear
    print_line
    print_title "  📦 步骤 3/4：下载并安装 Claude Code"
    print_line
    echo ""
    print_info "正在检查安装环境..."
    echo ""

    # 检查是否已安装 Node.js 和 npm
    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        NODE_VER=$(node --version 2>/dev/null)
        NODE_MAJOR=$(echo "$NODE_VER" | sed 's/v//' | cut -d. -f1)
        if [ "$NODE_MAJOR" -lt 20 ]; then
            print_warn "检测到 Node.js $NODE_VER（版本过旧，需要 v20 或更高版本）"
            echo ""
            echo -e "  ${YELLOW}Claude Code 最新版本需要 Node.js v20+，当前版本不兼容${NC}"
            echo -e "  ${YELLOW}将自动使用 nvm 升级 Node.js...${NC}"
            echo ""

            # 加载已有 nvm 或重新安装
            export NVM_DIR="$HOME/.nvm"
            if [ ! -s "$NVM_DIR/nvm.sh" ]; then
                print_info "正在安装 nvm..."
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
            fi
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

            print_info "正在安装 Node.js LTS 版本（v20+）..."
            if nvm install --lts && nvm use --lts; then
                NODE_VER=$(node --version 2>/dev/null)
                print_ok "Node.js 已升级至 $NODE_VER"
                HAS_NODE=true
            else
                print_error "Node.js 升级失败，请手动执行：nvm install --lts"
                exit 1
            fi
        else
            print_ok "检测到 Node.js $NODE_VER"
            HAS_NODE=true
        fi
    else
        print_warn "未检测到 Node.js"
        echo ""
        echo -e "  ${YELLOW}Claude Code 需要 Node.js 环境才能安装${NC}"
        echo ""
        echo -e "  ${BOLD}是否现在安装 Node.js？${NC}"
        echo ""
        read -p "  安装 Node.js？[Y/n] " install_node </dev/tty

        if [[ "$install_node" =~ ^[Nn]$ ]]; then
            print_error "没有 Node.js 无法继续安装"
            echo ""
            echo -e "  ${YELLOW}请先手动安装 Node.js，然后重新运行此脚本${NC}"
            echo -e "  ${CYAN}安装方法：${NC}"
            echo -e "  ${CYAN}1. 安装 Homebrew：${NC}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            echo -e "  ${CYAN}2. 安装 Node.js：${NC}brew install node"
            echo ""
            exit 1
        fi

        print_info "正在安装 Node.js（无需管理员权限）..."
        echo ""

        # 使用 nvm 安装 Node.js（无需管理员权限）
        print_info "使用 nvm 安装 Node.js..."

        if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash; then
            print_ok "nvm 安装成功！"
            echo ""

            # 加载 nvm
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

            print_info "正在安装 Node.js LTS 版本..."
            if nvm install --lts && nvm use --lts; then
                print_ok "Node.js 安装成功！"
                NODE_VER=$(node --version 2>/dev/null)
                print_ok "当前版本：$NODE_VER"
                HAS_NODE=true
            else
                print_error "Node.js 安装失败"
                exit 1
            fi
        else
            print_error "nvm 安装失败"
            echo ""
            echo -e "  ${YELLOW}请检查网络连接后重试${NC}"
            exit 1
        fi
        echo ""
    fi

    # 使用 npm 安装
    print_info "使用 npm 安装 Claude Code..."
    echo ""

    # 检查当前 npm prefix 配置
    CURRENT_PREFIX=$(npm config get prefix 2>/dev/null)

    # 如果 prefix 指向系统目录，需要重新配置到用户目录
    if [[ "$CURRENT_PREFIX" == "/usr/local" ]] || [[ "$CURRENT_PREFIX" == "/usr" ]]; then
        print_warn "检测到 npm 配置为系统目录，需要重新配置以避免权限问题"
        echo ""

        # 配置 npm 使用用户目录（避免需要 sudo）
        print_info "正在配置 npm 使用用户目录..."
        mkdir -p "$HOME/.npm-global"
        npm config set prefix "$HOME/.npm-global" 2>/dev/null

        # 添加到 PATH
        if ! grep -q "/.npm-global/bin" "$SHELL_CONFIG" 2>/dev/null; then
            echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$SHELL_CONFIG"
        fi
        export PATH="$HOME/.npm-global/bin:$PATH"
        print_ok "npm 已配置为使用用户目录（~/.npm-global）"
        echo ""
    else
        print_ok "npm 配置检查通过"
        echo ""
    fi

    # 配置 npm 使用国内镜像源（淘宝镜像）
    print_info "正在配置 npm 国内镜像源..."
    npm config set registry https://registry.npmmirror.com 2>/dev/null
    print_ok "镜像源配置完成"
    echo ""

    print_info "正在执行：npm install -g @anthropic-ai/claude-code"
    print_info "这可能需要 1-3 分钟，请耐心等待..."
    echo ""

    if npm install -g @anthropic-ai/claude-code; then
        print_ok "Claude Code 安装成功！"
    else
        print_error "npm 安装失败"
        echo ""
        print_error "请检查以下事项："
        echo ""
        echo -e "  ${YELLOW}1. 确认网络连接正常${NC}"
        echo -e "  ${YELLOW}2. 尝试手动安装：${NC}npm install -g @anthropic-ai/claude-code"
        echo -e "  ${YELLOW}3. 如果仍然失败，尝试恢复默认镜像源：${NC}npm config set registry https://registry.npmjs.org"
        echo ""

        # 删除可能创建的配置文件
        [ -f "$HOME/.claude.json" ] && rm "$HOME/.claude.json"
        [ -f "$HOME/.claude/settings.json" ] && rm "$HOME/.claude/settings.json"

        exit 1
    fi
    echo ""
fi

# 验证安装
echo ""
print_line
print_title "  🔍 验证安装结果"
print_line
echo ""

# 等待一秒确保路径生效
sleep 1

if command -v claude &>/dev/null; then
    CLAUDE_VER=$(claude --version 2>/dev/null | head -n1)
    print_ok "Claude Code 安装成功！版本：$CLAUDE_VER"
elif [ -f "$HOME/.npm-global/bin/claude" ]; then
    print_ok "Claude Code 已安装到 ~/.npm-global/bin/claude"
    print_warn "需要重启终端后才能使用 'claude' 命令"
    NEED_RESTART=true
else
    print_error "安装验证失败，claude 命令未找到"
    print_info "请尝试关闭终端重新打开，再运行 'claude --version' 验证"
fi

# ---- 步骤 4：启动测试 ----
clear
print_line
print_title "  🚀 步骤 4/4：启动测试"
print_line
echo ""

if [ "$USE_RELAY" = true ]; then
    echo -e "  ${GREEN}✅ 您使用的是中转 API，无需浏览器登录，直接启动即可！${NC}"
    echo ""
    echo -e "  ${BOLD}启动方式：${NC}"
    echo -e "  ${CYAN}1.${NC} 打开终端，进入任意文件夹"
    echo -e "  ${CYAN}2.${NC} 输入 ${BOLD}claude${NC} 按回车，即可开始对话"
elif [ "$USE_OFFICIAL" = true ]; then
    echo -e "  ${BOLD}官方账号使用浏览器授权，步骤如下：${NC}"
    echo ""
    echo -e "  ${CYAN}1.${NC} 在终端输入 ${BOLD}claude${NC} 并按回车"
    echo -e "  ${CYAN}2.${NC} 系统自动打开浏览器"
    echo -e "  ${CYAN}3.${NC} 在浏览器中登录您的 Claude 账号"
    echo -e "  ${CYAN}4.${NC} 点击授权，回到终端即可使用"
else
    echo -e "  ${BOLD}输入 ${CYAN}claude${NC} 按回车启动，根据您的配置完成后续授权。${NC}"
fi

echo ""
print_line
echo ""

if [ "$NEED_RESTART" = true ]; then
    print_warn "需要先重启终端才能使用！"
    echo ""
    echo -e "  ${CYAN}1.${NC} 关闭当前终端（按 Cmd+W）"
    echo -e "  ${CYAN}2.${NC} 重新打开终端（Launchpad 搜索"终端"）"
    echo -e "  ${CYAN}3.${NC} 输入 ${BOLD}claude${NC} 开始使用"
else
    read -p "  是否现在立即测试启动？[Y/n] " start_now </dev/tty
    if [[ ! "$start_now" =~ ^[Nn]$ ]]; then
        echo ""
        print_info "正在启动 Claude Code..."
        echo ""
        sleep 1
        claude
    fi
fi

# ---- 完成 ----
clear
print_line
print_title "  🎉 恭喜！安装配置完成！"
print_line
echo ""
echo -e "  ${BOLD}快速使用指南：${NC}"
echo ""
echo -e "  ${CYAN}【如何启动】${NC}"
echo -e "  在终端中输入 ${BOLD}claude${NC} 按回车即可开始对话"
echo ""
echo -e "  ${CYAN}【在项目文件夹中使用】${NC}"
echo -e "  先在 Finder 中进入项目文件夹"
echo -e "  右键点击文件夹 → 选择"在终端中打开""
echo -e "  然后输入 ${BOLD}claude${NC} 开始工作"
echo ""
echo -e "  ${CYAN}【常用对话示例】${NC}"
echo -e "  • 帮我看看这个文件夹里有什么"
echo -e "  • 帮我写一个 Python 脚本，计算文件夹大小"
echo -e "  • 我的代码报错了，帮我找问题"
echo ""
echo -e "  ${CYAN}【完整使用指南】${NC}"
echo -e "  请查看：${BOLD}claude-code-guide.md${NC} 文档"
echo -e "  或访问官方文档：${CYAN}https://code.claude.com/docs/en/quickstart${NC}"
echo ""
print_line
echo ""
echo -e "  ${GREEN}${BOLD}安装脚本执行完毕。感谢使用！${NC}"
echo ""
