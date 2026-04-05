#!/bin/bash
# ============================================
# OpenClaw 健康检查脚本
# ============================================
# 检查备份系统、服务状态、配置完整性
# ============================================

set -e

# 配置参数
OPENCLAW_HOME="$HOME/.openclaw"
BACKUP_DIR="$HOME/.openclaw/backup"
LOG_FILE="/tmp/openclaw-health-check-$(date +%Y%m%d_%H%M%S).log"
MAX_ERRORS=5

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

header() { echo -e "${BLUE}=== $1 ===${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

# 初始化
ERROR_COUNT=0
WARNING_COUNT=0
CHECK_COUNT=0

echo "============================================"
echo "🔍 OpenClaw 健康检查开始 - $(date)"
echo "============================================"
echo "日志文件: $LOG_FILE"
echo ""

# 记录到日志文件
exec > >(tee -a "$LOG_FILE") 2>&1

# ==================== 1. 基础环境检查 ====================
header "1. 基础环境检查"
((CHECK_COUNT++))

# 1.1 检查 OpenClaw 目录
if [ -d "$OPENCLAW_HOME" ]; then
    success "OpenClaw 目录存在: $OPENCLAW_HOME"
else
    error "OpenClaw 目录不存在: $OPENCLAW_HOME"
    ((ERROR_COUNT++))
fi

# 1.2 检查工作区目录
if [ -d "$OPENCLAW_HOME/workspace" ]; then
    success "工作区目录存在"
    WS_SIZE=$(du -sh "$OPENCLAW_HOME/workspace" | cut -f1)
    warning "工作区大小: $WS_SIZE"
else
    error "工作区目录不存在"
    ((ERROR_COUNT++))
fi

# 1.3 检查 memory 目录
if [ -d "$OPENCLAW_HOME/workspace/memory" ]; then
    MEMORY_FILES=$(find "$OPENCLAW_HOME/workspace/memory" -name "*.md" | wc -l)
    if [ $MEMORY_FILES -gt 0 ]; then
        success "记忆目录存在 ($MEMORY_FILES 个记忆文件)"
    else
        warning "记忆目录为空"
        ((WARNING_COUNT++))
    fi
else
    warning "记忆目录不存在"
    ((WARNING_COUNT++))
fi

# ==================== 2. 服务状态检查 ====================
header "2. 服务状态检查"
((CHECK_COUNT++))

# 2.1 检查 OpenClaw CLI
if command -v openclaw &> /dev/null; then
    OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
    success "OpenClaw CLI 已安装 ($OPENCLAW_VERSION)"
else
    error "OpenClaw CLI 未安装"
    ((ERROR_COUNT++))
fi

# 2.2 检查网关服务
if command -v openclaw &> /dev/null; then
    if openclaw gateway status 2>/dev/null | grep -q "running"; then
        success "OpenClaw 网关服务正在运行"
    else
        warning "OpenClaw 网关服务未运行"
        ((WARNING_COUNT++))
    fi
fi

# 2.3 检查必需 CLI 工具
ESSENTIAL_TOOLS=("git" "curl" "tar" "gzip")
for tool in "${ESSENTIAL_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        success "$tool 已安装"
    else
        warning "$tool 未安装"
        ((WARNING_COUNT++))
    fi
done

# ==================== 3. 配置文件检查 ====================
header "3. 配置文件检查"
((CHECK_COUNT++))

# 3.1 检查主配置文件
if [ -f "$OPENCLAW_HOME/openclaw.json" ]; then
    CONFIG_SIZE=$(wc -l < "$OPENCLAW_HOME/openclaw.json")
    if [ $CONFIG_SIZE -gt 10 ]; then
        success "主配置文件存在 ($CONFIG_SIZE 行)"
        
        # 检查是否包含明文 API 密钥（安全警告）
        if grep -q "sk-" "$OPENCLAW_HOME/openclaw.json"; then
            warning "配置文件包含明文 API 密钥（格式为 sk-）"
            ((WARNING_COUNT++))
        fi
    else
        error "主配置文件过小 ($CONFIG_SIZE 行)，可能损坏"
        ((ERROR_COUNT++))
    fi
else
    error "主配置文件不存在"
    ((ERROR_COUNT++))
fi

# 3.2 检查核心身份文件
CORE_FILES=("SOUL.md" "IDENTITY.md" "AGENTS.md")
for file in "${CORE_FILES[@]}"; do
    if [ -f "$OPENCLAW_HOME/workspace/$file" ]; then
        success "$file 存在"
    else
        warning "$file 不存在"
        ((WARNING_COUNT++))
    fi
done

# 3.3 检查 USER.md 和 MEMORY.md（安全提醒）
if [ -f "$OPENCLAW_HOME/workspace/USER.md" ]; then
    warning "USER.md 存在（包含个人信息，不要上传到Git）"
    ((WARNING_COUNT++))
fi

if [ -f "$OPENCLAW_HOME/workspace/MEMORY.md" ]; then
    warning "MEMORY.md 存在（包含长期记忆，不要上传到Git）"
    ((WARNING_COUNT++))
fi

# ==================== 4. 备份系统检查 ====================
header "4. 备份系统检查"
((CHECK_COUNT++))

# 4.1 检查备份目录
if [ -d "$BACKUP_DIR" ]; then
    success "备份目录存在: $BACKUP_DIR"
    
    # 4.2 检查最近备份
    LAST_BACKUP=$(find "$BACKUP_DIR" -name "safe-*" -type d -exec stat -c %Y {} \; 2>/dev/null | sort -nr | head -1)
    if [ -n "$LAST_BACKUP" ]; then
        NOW=$(date +%s)
        HOURS_AGO=$(( (NOW - LAST_BACKUP) / 3600 ))
        
        if [ $HOURS_AGO -lt 48 ]; then
            success "最近备份是 $HOURS_AGO 小时前"
        elif [ $HOURS_AGO -lt 168 ]; then
            warning "最近备份是 $HOURS_AGO 小时前（超过2天）"
            ((WARNING_COUNT++))
        else
            error "最近备份是 $HOURS_AGO 小时前（超过7天）"
            ((ERROR_COUNT++))
        fi
    else
        warning "未找到安全备份"
        ((WARNING_COUNT++))
    fi
    
    # 4.3 检查备份大小
    BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
    warning "备份目录大小: $BACKUP_SIZE"
    
    # 4.4 检查备份索引
    if [ -f "$BACKUP_DIR/backup-index.json" ]; then
        success "备份索引存在"
    else
        warning "备份索引不存在"
        ((WARNING_COUNT++))
    fi
else
    warning "备份目录不存在"
    ((WARNING_COUNT++))
fi

# 4.5 检查 koalabearBOT 仓库
KOALA_DIR="/tmp/koalabearBOT"
if [ -d "$KOALA_DIR/.git" ]; then
    success "koalabearBOT 仓库存在"
    
    # 检查仓库状态
    cd "$KOALA_DIR" 2>/dev/null && \
    if git status --porcelain | grep -q "^ M"; then
        warning "koalabearBOT 仓库有未提交的修改"
        ((WARNING_COUNT++))
    fi
else
    warning "koalabearBOT 仓库未找到（可能在 /tmp）"
    ((WARNING_COUNT++))
fi

# ==================== 5. 安全配置检查 ====================
header "5. 安全配置检查"
((CHECK_COUNT++))

# 5.1 检查 .gitignore 是否包含敏感文件
if [ -f "/tmp/koalabearBOT/.gitignore" ]; then
    REQUIRED_PATTERNS=("openclaw.json" "*.bak" "memory/*.md" "workspace/MEMORY.md" "workspace/USER.md")
    MISSING_PATTERNS=0
    
    for pattern in "${REQUIRED_PATTERNS[@]}"; do
        if ! grep -q "$pattern" "/tmp/koalabearBOT/.gitignore"; then
            error ".gitignore 缺失排除模式: $pattern"
            ((ERROR_COUNT++))
            ((MISSING_PATTERNS++))
        fi
    done
    
    if [ $MISSING_PATTERNS -eq 0 ]; then
        success ".gitignore 配置完整"
    fi
else
    error ".gitignore 文件不存在"
    ((ERROR_COUNT++))
fi

# 5.2 检查配置文件模板是否去敏感化
if [ -f "/tmp/koalabearBOT/openclaw-config/openclaw.sample.json" ]; then
    if grep -q "REPLACE_WITH_YOUR_API_KEY" "/tmp/koalabearBOT/openclaw-config/openclaw.sample.json"; then
        success "配置文件模板已正确去敏感化"
    else
        warning "配置文件模板可能包含真实密钥"
        ((WARNING_COUNT++))
    fi
fi

# ==================== 6. 磁盘空间检查 ====================
header "6. 磁盘空间检查"
((CHECK_COUNT++))

# 6.1 检查 home 目录空间
HOME_USAGE=$(df -h "$HOME" | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$HOME_USAGE" -lt 80 ]; then
    success "Home 目录使用率: $HOME_USAGE%"
elif [ "$HOME_USAGE" -lt 95 ]; then
    warning "Home 目录使用率较高: $HOME_USAGE%"
    ((WARNING_COUNT++))
else
    error "Home 目录使用率过高: $HOME_USAGE%"
    ((ERROR_COUNT++))
fi

# 6.2 检查备份目录空间
if [ -d "$BACKUP_DIR" ]; then
    BACKUP_USAGE=$(du -sh "$BACKUP_DIR" | cut -f1)
    warning "备份目录大小: $BACKUP_USAGE"
fi

# ==================== 7. 网络连通性检查 ====================
header "7. 网络连通性检查"
((CHECK_COUNT++))

# 7.1 检查 GitHub 连接
if ping -c 1 -W 2 github.com &> /dev/null; then
    success "GitHub 网络连通正常"
else
    warning "无法连接到 GitHub"
    ((WARNING_COUNT++))
fi

# 7.2 检查必要 API 端点
API_ENDPOINTS=("api.openai.com" "gptapi.asia")
for endpoint in "${API_ENDPOINTS[@]}"; do
    if timeout 2 curl -s "https://$endpoint" &> /dev/null; then
        success "$endpoint 可访问"
    else
        warning "$endpoint 访问失败"
        ((WARNING_COUNT++))
    fi
done

# ==================== 8. 生成健康报告 ====================
header "8. 健康检查报告"
((CHECK_COUNT++))

TOTAL_CHECKS=$CHECK_COUNT
SUCCESS_CHECKS=$((TOTAL_CHECKS - ERROR_COUNT - WARNING_COUNT))

echo ""
echo "============================================"
echo "📊 健康检查摘要"
echo "============================================"
echo "检查项目总数: $TOTAL_CHECKS"
echo "✅ 成功检查: $SUCCESS_CHECKS"
echo "⚠️  警告项目: $WARNING_COUNT"
echo "❌ 错误项目: $ERROR_COUNT"
echo ""

# 总体状态判断
if [ $ERROR_COUNT -eq 0 ] && [ $WARNING_COUNT -eq 0 ]; then
    success "🌟 系统状态：优秀"
    echo "所有检查项目通过，系统运行正常。"
elif [ $ERROR_COUNT -eq 0 ] && [ $WARNING_COUNT -gt 0 ]; then
    warning "📋 系统状态：良好（有警告）"
    echo "系统运行正常，但有 $WARNING_COUNT 个需要注意的警告。"
elif [ $ERROR_COUNT -lt $MAX_ERRORS ]; then
    error "⚠️  系统状态：有问题"
    echo "系统有 $ERROR_COUNT 个错误需要修复。"
else
    error "🚨 系统状态：严重"
    echo "系统有 $ERROR_COUNT 个严重错误，需要立即修复！"
fi

echo ""
echo "============================================"
echo "📋 建议操作"
echo "============================================"

if [ $ERROR_COUNT -gt 0 ]; then
    echo "1. 修复上述错误项目"
fi

if [ ! -d "$BACKUP_DIR" ] || [ -z "$LAST_BACKUP" ]; then
    echo "2. 运行备份脚本：./scripts/daily-backup.sh"
fi

if [ "$HOME_USAGE" -gt 90 ]; then
    echo "3. 清理磁盘空间，当前使用率: $HOME_USAGE%"
fi

if ! command -v openclaw &> /dev/null; then
    echo "4. 安装 OpenClaw CLI：npm install -g @openclaw/cli"
fi

echo ""
echo "============================================"
echo "📁 日志文件: $LOG_FILE"
echo "下次检查：$(date -d '+1 day' '+%Y-%m-%d %H:%M:%S')"
echo "============================================"

# 退出码
if [ $ERROR_COUNT -eq 0 ]; then
    exit 0
else
    exit 1
fi