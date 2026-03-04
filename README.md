# Claude Code 一键安装脚本

适合完全没有编程经验的用户，一键安装并配置 Claude Code。

## 支持平台

- ✅ macOS 10.0+
- ✅ Windows 10+

## 快速开始

### macOS 用户

打开终端（Terminal），粘贴以下命令并按回车：

```bash
curl -fsSL https://raw.githubusercontent.com/ssyamv/claude-code-setup/main/install-claude-mac.sh | bash
```

### Windows 用户

以管理员身份打开 PowerShell，粘贴以下命令并按回车：

```powershell
irm https://raw.githubusercontent.com/ssyamv/claude-code-setup/main/install-claude-windows.ps1 | iex
```

## 功能特性

- 🚀 一键安装，全程自动化
- 🔧 自动检测系统环境
- 🔑 支持多种 API 接入方式
  - 第三方中转 API（推荐，价格便宜）
  - Anthropic 官方账号
  - AWS Bedrock / Google Vertex AI
- 💾 自动备份配置文件
- 🔄 安装失败自动回滚
- 📝 详细的错误提示和帮助信息

## 接入方式说明

### 方式 1：第三方中转 API（推荐）

- 价格便宜（约官方 1/3～1/10）
- 按量计费，国内直连
- 需要从中转服务商获取 API 地址和 API Key

### 方式 2：Anthropic 官方账号

- 直接在 [claude.ai](https://claude.ai/upgrade) 购买
- Claude Pro（约 $20/月）或 Claude Max（约 $100+/月）
- 使用浏览器授权，最官方

### 方式 3：大厂云平台

- AWS Bedrock
- Google Vertex AI
- 适合已有云账号的企业用户

## 安全特性

- ✅ 配置文件自动备份
- ✅ 安装失败自动回滚
- ✅ 精确的配置清理，避免误删
- ✅ 完善的错误处理机制

## 常见问题

### macOS 提示"无法验证开发者"

这是正常的，脚本是开源的，可以查看源码确认安全性。

### Windows 提示"无法运行脚本"

需要调整 PowerShell 执行策略，脚本会自动处理。

### 安装失败怎么办？

1. 检查网络连接（能否打开 claude.ai）
2. Windows 用户确认已安装 Git for Windows
3. 查看错误提示，脚本会自动回滚配置

## 手动安装

如果一键安装失败，可以下载脚本到本地运行：

### macOS

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/ssyamv/claude-code-setup/main/install-claude-mac.sh

# 添加执行权限
chmod +x install-claude-mac.sh

# 运行
./install-claude-mac.sh
```

### Windows

```powershell
# 下载脚本
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ssyamv/claude-code-setup/main/install-claude-windows.ps1" -OutFile "install-claude-windows.ps1"

# 运行
.\install-claude-windows.ps1
```

## 卸载

### macOS

编辑配置文件删除相关环境变量：

```bash
# 如果使用 zsh
nano ~/.zshrc

# 如果使用 bash
nano ~/.bash_profile
```

删除以下内容：
```bash
# Claude Code 中转 API 配置
export ANTHROPIC_BASE_URL="..."
export ANTHROPIC_API_KEY="..."
```

删除 Claude Code：
```bash
rm -rf ~/.local/bin/claude
rm -f ~/.claude.json
```

### Windows

删除环境变量：
```powershell
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $null, "User")
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $null, "User")
```

删除 Claude Code：
```powershell
Remove-Item "$env:USERPROFILE\.local\bin\claude.exe" -Force
Remove-Item "$env:USERPROFILE\.claude.json" -Force
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 免责声明

本脚本仅供学习交流使用，使用第三方中转 API 可能违反 Anthropic 服务条款，请自行承担风险。建议使用官方账号或云平台接入。

## 相关链接

- [Claude Code 官方文档](https://code.claude.com/docs)
- [Anthropic 官网](https://www.anthropic.com)
- [Claude.ai](https://claude.ai)
