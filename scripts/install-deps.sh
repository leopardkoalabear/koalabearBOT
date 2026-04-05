#!/bin/bash
# ============================================
# OpenClaw 依赖安装脚本
# ============================================
# 用法: ./scripts/install-deps.sh
# ============================================

set -e  # 遇到错误立即退出

echo "🚀 开始安装 OpenClaw 依赖..."

# 检查操作系统
OS="$(uname -s)"
case "$OS" in
    Linux*)     OS_TYPE="linux" ;;
    Darwin*)    OS_TYPE="macos" ;;
    CYGWIN*|MINGW*|MSYS*) OS_TYPE="windows" ;;
    *)          echo "❌ 不支持的操作系统: $OS"; exit 1 ;;
esac

echo "📦 检测到系统: $OS_TYPE"

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装"
    echo "📝 请从 https://nodejs.org/ 安装 Node.js 18+"
    exit 1
fi

NODE_VERSION=$(node --version)
echo "✅ Node.js $NODE_VERSION 已安装"

# 检查 npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm 未安装"
    exit 1
fi

echo "✅ npm $(npm --version) 已安装"

# 安装 OpenClaw CLI
echo "📦 安装 OpenClaw CLI..."
if ! command -v openclaw &> /dev/null; then
    npm install -g @openclaw/cli
    echo "✅ OpenClaw CLI 安装完成"
else
    OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
    echo "✅ OpenClaw CLI 已安装 ($OPENCLAW_VERSION)"
fi

# 安装常用 CLI 工具
echo "📦 安装常用 CLI 工具..."

# GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "📝 需要安装 GitHub CLI"
    echo "   请访问: https://cli.github.com/"
else
    echo "✅ GitHub CLI 已安装"
fi

# 1Password CLI
if ! command -v op &> /dev/null; then
    echo "📝 需要安装 1Password CLI"
    echo "   请访问: https://developer.1password.com/docs/cli/"
else
    echo "✅ 1Password CLI 已安装"
fi

# Git (必需)
if ! command -v git &> /dev/null; then
    echo "❌ Git 未安装"
    echo "📝 请从 https://git-scm.com/ 安装 Git"
    exit 1
fi
echo "✅ Git $(git --version | cut -d' ' -f3) 已安装"

# Python3 (可选但推荐)
if command -v python3 &> /dev/null; then
    echo "✅ Python3 $(python3 --version | cut -d' ' -f2) 已安装"
else
    echo "⚠️  Python3 未安装 (某些技能可能需要)"
fi

# 创建 OpenClaw 配置目录
OPENCLAW_HOME="$HOME/.openclaw"
if [ ! -d "$OPENCLAW_HOME" ]; then
    echo "📁 创建 OpenClaw 目录: $OPENCLAW_HOME"
    mkdir -p "$OPENCLAW_HOME"
fi

echo ""
echo "============================================"
echo "🎉 依赖安装完成！"
echo ""
echo "接下来:"
echo "1. 复制配置文件: cp openclaw-config/openclaw.sample.json $OPENCLAW_HOME/openclaw.json"
echo "2. 编辑配置文件: 填入你的 API 密钥"
echo "3. 复制环境变量: cp openclaw-config/.env.example .env"
echo "4. 安装技能: 运行 ./scripts/setup-workspace.sh"
echo "============================================"