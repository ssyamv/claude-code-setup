#!/bin/bash
# =============================================================================
# Claude Code 一键安装脚本 (macOS 版)
# 适合完全没有编程经验的用户
# =============================================================================
# 运行方式（在终端中粘贴以下命令）：
# curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-setup/main/install-claude-mac.sh | bash
# =============================================================================

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

SHELL_CONFIG="$HOME/.zshrc"
[[ "$SHELL" == *"bash"* ]] && SHELL_CONFIG="$HOME/.bash_profile"

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
    print_info "正在将配置写入 $SHELL_CONFIG ..."

    # 备份配置文件
    cp "$SHELL_CONFIG" "${SHELL_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null

    # 清理旧配置（更精确的匹配，只删除 export 开头的配置行）
    sed -i '' '/^export ANTHROPIC_BASE_URL=/d' "$SHELL_CONFIG" 2>/dev/null
    sed -i '' '/^export ANTHROPIC_API_KEY=/d' "$SHELL_CONFIG" 2>/dev/null
    # 清理配置注释行
    sed -i '' '/^# Claude Code 中转 API 配置$/d' "$SHELL_CONFIG" 2>/dev/null

    # 写入新配置
    {
        echo ""
        echo "# Claude Code 中转 API 配置"
        echo "export ANTHROPIC_BASE_URL=\"$base_url\""
        echo "export ANTHROPIC_API_KEY=\"$api_key\""
    } >> "$SHELL_CONFIG"

    # 当前会话也生效
    export ANTHROPIC_BASE_URL="$base_url"
    export ANTHROPIC_API_KEY="$api_key"

    print_ok "配置已保存！每次打开终端自动生效。"

    # ---- 写入 ~/.claude.json 以绕过 Claude Code 2.0 强制登录 ----
    print_info "正在写入 ~/.claude.json 以跳过登录验证..."
    cat > "$HOME/.claude.json" << EOF
{
  "hasCompletedOnboarding": true,
  "primaryApiKey": "$api_key"
}
EOF
    print_ok "已自动绕过 Claude Code 2.0 强制登录，无需浏览器授权！"

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

    if [[ "$cloud_choice" == "1" ]]; then
        read -p "  AWS_REGION（默认 us-east-1）: " aws_region </dev/tty
        aws_region="${aws_region:-us-east-1}"
        read -p "  AWS_ACCESS_KEY_ID: " aws_key </dev/tty
        read -p "  AWS_SECRET_ACCESS_KEY: " aws_secret </dev/tty

        # 备份配置文件
        cp "$SHELL_CONFIG" "${SHELL_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null

        sed -i '' '/^export CLAUDE_CODE_USE_BEDROCK=/d' "$SHELL_CONFIG" 2>/dev/null
        sed -i '' '/^export AWS_REGION=/d' "$SHELL_CONFIG" 2>/dev/null
        sed -i '' '/^export AWS_ACCESS_KEY_ID=/d' "$SHELL_CONFIG" 2>/dev/null
        sed -i '' '/^export AWS_SECRET_ACCESS_KEY=/d' "$SHELL_CONFIG" 2>/dev/null
        sed -i '' '/^# Claude Code Amazon Bedrock 配置$/d' "$SHELL_CONFIG" 2>/dev/null

        {
            echo ""
            echo "# Claude Code Amazon Bedrock 配置"
            echo "export CLAUDE_CODE_USE_BEDROCK=1"
            echo "export AWS_REGION=\"$aws_region\""
            echo "export AWS_ACCESS_KEY_ID=\"$aws_key\""
            echo "export AWS_SECRET_ACCESS_KEY=\"$aws_secret\""
        } >> "$SHELL_CONFIG"

        export CLAUDE_CODE_USE_BEDROCK=1
        export AWS_REGION="$aws_region"
        export AWS_ACCESS_KEY_ID="$aws_key"
        export AWS_SECRET_ACCESS_KEY="$aws_secret"

    elif [[ "$cloud_choice" == "2" ]]; then
        read -p "  CLOUD_ML_REGION（默认 us-east5）: " gcp_region </dev/tty
        gcp_region="${gcp_region:-us-east5}"
        read -p "  ANTHROPIC_VERTEX_PROJECT_ID: " gcp_project </dev/tty

        # 备份配置文件
        cp "$SHELL_CONFIG" "${SHELL_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null

        sed -i '' '/^export CLAUDE_CODE_USE_VERTEX=/d' "$SHELL_CONFIG" 2>/dev/null
        sed -i '' '/^export CLOUD_ML_REGION=/d' "$SHELL_CONFIG" 2>/dev/null
        sed -i '' '/^export ANTHROPIC_VERTEX_PROJECT_ID=/d' "$SHELL_CONFIG" 2>/dev/null
        sed -i '' '/^# Claude Code Google Vertex AI 配置$/d' "$SHELL_CONFIG" 2>/dev/null

        {
            echo ""
            echo "# Claude Code Google Vertex AI 配置"
            echo "export CLAUDE_CODE_USE_VERTEX=1"
            echo "export CLOUD_ML_REGION=\"$gcp_region\""
            echo "export ANTHROPIC_VERTEX_PROJECT_ID=\"$gcp_project\""
        } >> "$SHELL_CONFIG"

        export CLAUDE_CODE_USE_VERTEX=1
        export CLOUD_ML_REGION="$gcp_region"
        export ANTHROPIC_VERTEX_PROJECT_ID="$gcp_project"
    fi
    print_ok "云平台配置已保存！"

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
        print_ok "检测到 Node.js $NODE_VER"
        HAS_NODE=true
    else
        print_warn "未检测到 Node.js"
        echo ""
        echo -e "  ${YELLOW}Node.js 可以让安装过程更快速、更稳定${NC}"
        echo ""
        echo -e "  ${BOLD}是否现在安装 Node.js？（推荐）${NC}"
        echo -e "  ${CYAN}• 选择 Y：${NC}自动安装 Node.js，然后用 npm 安装 Claude Code（推荐）"
        echo -e "  ${CYAN}• 选择 N：${NC}跳过，使用官方安装脚本（较慢，可能不稳定）"
        echo ""
        read -p "  是否安装 Node.js？[Y/n] " install_node </dev/tty

        if [[ ! "$install_node" =~ ^[Nn]$ ]]; then
            print_info "正在安装 Node.js..."
            echo ""

            # 检查是否安装了 Homebrew
            if command -v brew &>/dev/null; then
                print_info "使用 Homebrew 安装 Node.js..."
                if brew install node; then
                    print_ok "Node.js 安装成功！"
                    HAS_NODE=true
                else
                    print_warn "Homebrew 安装失败，将使用官方安装脚本"
                fi
            else
                print_warn "未检测到 Homebrew"
                echo ""
                echo -e "  ${YELLOW}推荐先安装 Homebrew（Mac 包管理器），然后再安装 Node.js${NC}"
                echo ""
                echo -e "  ${BOLD}安装 Homebrew 的命令：${NC}"
                echo -e "  ${CYAN}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
                echo ""
                read -p "  是否现在安装 Homebrew？[Y/n] " install_brew </dev/tty

                if [[ ! "$install_brew" =~ ^[Nn]$ ]]; then
                    print_info "正在安装 Homebrew..."
                    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
                        print_ok "Homebrew 安装成功！"

                        # 配置 Homebrew 环境变量
                        if [[ $(uname -m) == "arm64" ]]; then
                            eval "$(/opt/homebrew/bin/brew shellenv)"
                        else
                            eval "$(/usr/local/bin/brew shellenv)"
                        fi

                        print_info "正在安装 Node.js..."
                        if brew install node; then
                            print_ok "Node.js 安装成功！"
                            HAS_NODE=true
                        fi
                    else
                        print_warn "Homebrew 安装失败，将使用官方安装脚本"
                    fi
                else
                    print_info "跳过 Homebrew 安装，将使用官方安装脚本"
                fi
            fi
        else
            print_info "跳过 Node.js 安装，将使用官方安装脚本"
        fi
        echo ""
    fi

    # 使用 npm 安装（推荐方式）
    if [ "$HAS_NODE" = true ]; then
        print_info "使用 npm 安装 Claude Code（推荐方式）..."
        echo ""

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
            NPM_INSTALL_SUCCESS=true
        else
            print_warn "npm 安装失败，尝试恢复默认镜像源..."
            npm config set registry https://registry.npmjs.org 2>/dev/null
            print_info "将使用官方安装脚本..."
        fi
        echo ""
    fi

    # 如果 npm 安装失败或没有 Node.js，使用官方安装脚本
    if [ "$NPM_INSTALL_SUCCESS" != true ]; then
        print_info "使用官方安装脚本..."
        print_info "这可能需要 1～3 分钟，请耐心等待..."
        echo ""
        print_line
        echo ""

        if curl -fsSL https://claude.ai/install.sh | bash; then
            echo ""
            print_line
        else
            echo ""
            print_error "安装失败！正在回滚配置..."

            # 回滚配置文件
            LATEST_BACKUP=$(ls -t "${SHELL_CONFIG}.backup."* 2>/dev/null | head -n1)
            if [ -n "$LATEST_BACKUP" ]; then
                cp "$LATEST_BACKUP" "$SHELL_CONFIG"
                print_ok "配置文件已回滚"
            fi

            # 删除可能创建的 .claude.json
            [ -f "$HOME/.claude.json" ] && rm "$HOME/.claude.json"

            echo ""
            print_error "请检查以下事项："
            echo ""
            echo -e "  ${YELLOW}1. 确认网络连接正常（可以打开 claude.ai 网站）${NC}"
            echo -e "  ${YELLOW}2. 如果出现权限错误，请不要使用 sudo${NC}"
            echo -e "  ${YELLOW}3. 尝试稍后重新运行本脚本${NC}"
            echo ""
            echo -e "  如需帮助，请访问：${CYAN}https://code.claude.com/docs/en/troubleshooting${NC}"
            press_enter
            exit 1
        fi
    fi

    # 刷新 PATH
    export PATH="$HOME/.local/bin:$PATH"
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
else
    # 尝试直接路径
    if [ -f "$HOME/.local/bin/claude" ]; then
        print_ok "Claude Code 已安装到 ~/.local/bin/claude"
        print_warn "需要重启终端后才能使用 'claude' 命令"
        NEED_RESTART=true
    else
        print_error "安装验证失败，claude 命令未找到"
        print_info "请尝试关闭终端重新打开，再运行 'claude --version' 验证"
    fi
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
