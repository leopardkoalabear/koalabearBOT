#!/bin/bash
# ============================================
# OpenClaw 每日自动备份脚本
# ============================================
# 安全策略：绝对不备份敏感文件，只备份安全内容
# ============================================

set -e  # 遇到错误立即退出
set -u  # 使用未定义变量时报错

# 配置参数
BACKUP_DIR="$HOME/.openclaw/backup"
OPENCLAW_HOME="$HOME/.openclaw"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$BACKUP_DIR/backup-$DATE.log"

# 颜色输出函数
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 初始化日志
mkdir -p "$BACKUP_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "============================================"
echo "🚀 OpenClaw 每日备份开始 - $(date)"
echo "============================================"

# 检查备份目录权限
if [ ! -w "$BACKUP_DIR" ]; then
    error "备份目录不可写: $BACKUP_DIR"
    exit 1
fi

info "备份目录: $BACKUP_DIR"
info "日志文件: $LOG_FILE"

# 1. 检查 OpenClaw 服务状态
info "检查 OpenClaw 服务状态..."
if command -v openclaw &> /dev/null; then
    if openclaw gateway status 2>/dev/null | grep -q "running"; then
        info "OpenClaw 服务正在运行"
        SERVICE_RUNNING=true
    else
        warn "OpenClaw 服务未运行"
        SERVICE_RUNNING=false
    fi
else
    error "OpenClaw CLI 未安装"
    exit 1
fi

# 2. 安全文件快照（排除敏感文件）
SAFE_BACKUP_DIR="$BACKUP_DIR/safe-$DATE"
mkdir -p "$SAFE_BACKUP_DIR"

info "创建安全文件快照..."
rsync -av --delete \
    --exclude='openclaw.json' \
    --exclude='*.bak' \
    --exclude='*.backup' \
    --exclude='update-check.json' \
    --exclude='memory/*.md' \
    --exclude='workspace/MEMORY.md' \
    --exclude='workspace/USER.md' \
    --exclude='workspace/IDENTITY.md' \
    --exclude='workspace/SOUL.md' \
    --exclude='logs/' \
    --exclude='tmp/' \
    --exclude='models/' \
    --exclude='backup/' \
    "$OPENCLAW_HOME/" \
    "$SAFE_BACKUP_DIR/" 2>/dev/null || true

# 3. 统计备份内容
BACKUP_SIZE=$(du -sh "$SAFE_BACKUP_DIR" | cut -f1)
FILE_COUNT=$(find "$SAFE_BACKUP_DIR" -type f | wc -l)
DIR_COUNT=$(find "$SAFE_BACKUP_DIR" -type d | wc -l)

info "备份统计:"
info "  备份大小: $BACKUP_SIZE"
info "  文件数量: $FILE_COUNT"
info "  目录数量: $DIR_COUNT"

# 4. 验证备份完整性
info "验证备份完整性..."
if [ $FILE_COUNT -gt 10 ]; then
    # 检查关键文件是否存在
    MISSING_FILES=0
    
    # 检查目录结构
    for dir in workspace scripts extensions; do
        if [ -d "$SAFE_BACKUP_DIR/$dir" ]; then
            info "  ✅ 目录存在: $dir"
        else
            warn "  ⚠️  目录缺失: $dir"
            MISSING_FILES=$((MISSING_FILES+1))
        fi
    done
    
    if [ $MISSING_FILES -eq 0 ]; then
        info "备份完整性验证通过"
    else
        warn "备份完整性警告：缺失 $MISSING_FILES 个目录"
    fi
else
    error "备份文件数量异常 ($FILE_COUNT)，可能有问题"
    exit 1
fi

# 5. 压缩备份（可选）
if command -v tar &> /dev/null && command -v gzip &> /dev/null; then
    info "压缩备份文件..."
    cd "$BACKUP_DIR"
    tar -czf "safe-$DATE.tar.gz" "safe-$DATE/"
    COMPRESSED_SIZE=$(du -h "safe-$DATE.tar.gz" | cut -f1)
    info "压缩后大小: $COMPRESSED_SIZE"
    
    # 清理原始目录
    rm -rf "$SAFE_BACKUP_DIR"
    info "清理未压缩的备份目录"
fi

# 6. 清理旧备份（保留最近7天）
info "清理旧备份..."
if command -v find &> /dev/null; then
    # 清理7天前的安全备份
    find "$BACKUP_DIR" -name "safe-*" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
    find "$BACKUP_DIR" -name "safe-*.tar.gz" -mtime +7 -delete 2>/dev/null || true
    find "$BACKUP_DIR" -name "backup-*.log" -mtime +30 -delete 2>/dev/null || true
    
    info "已清理7天前的备份"
else
    warn "find 命令不可用，跳过清理旧备份"
fi

# 7. 生成备份报告
REPORT_FILE="$BACKUP_DIR/backup-report-$DATE.md"
cat > "$REPORT_FILE" << EOF
# OpenClaw 每日备份报告

## 基本信息
- **备份时间**: $(date)
- **备份目录**: $BACKUP_DIR
- **备份类型**: 安全文件快照（排除敏感数据）

## 备份统计
- **备份大小**: $BACKUP_SIZE
- **文件数量**: $FILE_COUNT
- **目录数量**: $DIR_COUNT
- **服务状态**: $([ "$SERVICE_RUNNING" = true ] && echo "运行中" || echo "未运行")

## 包含内容
✅ 安全配置文件（模板）  
✅ 技能目录结构  
✅ 扩展文件  
✅ 脚本文件  
✅ 工作区模板  

## 排除内容
❌ API 密钥配置文件 (\`openclaw.json\`)  
❌ 备份文件 (\`*.bak\`, \`*.backup\`)  
❌ 个人记忆文件 (\`memory/*.md\`)  
❌ 身份文件 (\`USER.md\`, \`IDENTITY.md\`, \`SOUL.md\`)  
❌ 日志文件  
❌ 临时文件  
❌ 大模型文件  

## 完整性检查
$(if [ $MISSING_FILES -eq 0 ]; then echo "✅ 所有关键目录都存在"; else echo "⚠️  缺失 $MISSING_FILES 个目录"; fi)

## 后续步骤
1. 敏感数据（API密钥）使用 1Password 管理
2. 个人记忆文件需要单独加密备份
3. 定期测试恢复流程

## 日志文件
\`$LOG_FILE\`

---

> *备份时间: $(date)*  
> *备份ID: $DATE*
EOF

info "备份报告生成: $REPORT_FILE"

# 8. 更新备份索引
INDEX_FILE="$BACKUP_DIR/backup-index.json"
if [ ! -f "$INDEX_FILE" ]; then
    cat > "$INDEX_FILE" << EOF
{
  "backups": [],
  "lastUpdated": "$(date -Iseconds)",
  "totalBackups": 0
}
EOF
fi

# 简单的索引更新（使用临时文件避免损坏）
TEMP_INDEX=$(mktemp)
jq --arg date "$DATE" \
   --arg size "$BACKUP_SIZE" \
   --arg files "$FILE_COUNT" \
   --arg report "$REPORT_FILE" \
   '.backups += [{"date": $date, "size": $size, "files": $files, "report": $report}] | .lastUpdated = now | .totalBackups = (.backups | length)' \
   "$INDEX_FILE" > "$TEMP_INDEX" 2>/dev/null && mv "$TEMP_INDEX" "$INDEX_FILE" || warn "无法更新备份索引（jq 未安装）"

# 9. 最终统计
TOTAL_BACKUPS=$(find "$BACKUP_DIR" -name "safe-*" -type d | wc -l)
TOTAL_BACKUPS=$((TOTAL_BACKUPS + $(find "$BACKUP_DIR" -name "safe-*.tar.gz" | wc -l)))
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

echo ""
echo "============================================"
echo "🎉 每日备份完成！"
echo "============================================"
info "备份ID: $DATE"
info "总备份数: $TOTAL_BACKUPS"
info "备份总大小: $TOTAL_SIZE"
info "日志文件: $LOG_FILE"
info "报告文件: $REPORT_FILE"
echo ""
info "下次备份：$(date -d '+1 day' '+%Y-%m-%d %H:%M:%S')"
echo "============================================"

# 10. 如果有错误，记录退出状态
if [ $? -eq 0 ]; then
    echo "SUCCESS" > "$BACKUP_DIR/last-backup-status.txt"
    echo "$DATE" > "$BACKUP_DIR/last-backup-time.txt"
    exit 0
else
    echo "FAILED" > "$BACKUP_DIR/last-backup-status.txt"
    exit 1
fi