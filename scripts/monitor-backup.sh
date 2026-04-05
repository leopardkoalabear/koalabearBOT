#!/bin/bash
# ============================================
# OpenClaw 备份监控脚本
# ============================================
# 监控备份状态，发送告警，自动修复问题
# ============================================

set -e

# 配置参数
OPENCLAW_HOME="$HOME/.openclaw"
BACKUP_DIR="$HOME/.openclaw/backup"
ALERT_FILE="$BACKUP_DIR/alerts.json"
CONFIG_FILE="$BACKUP_DIR/monitor-config.json"
LOG_FILE="$BACKUP_DIR/monitor-$(date +%Y%m%d).log"

# 默认配置
DEFAULT_CONFIG='{
  "alerts": {
    "enabled": true,
    "max_backup_age_hours": 48,
    "min_disk_space_gb": 5,
    "max_error_count": 3,
    "check_interval_hours": 24
  },
  "notifications": {
    "email": "",
    "webhook": "",
    "feishu_webhook": "",
    "telegram_bot": ""
  },
  "auto_fix": {
    "enabled": true,
    "run_backup_if_old": true,
    "clean_old_backups": true,
    "restart_service_if_down": false
  }
}'

# 初始化配置
init_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$DEFAULT_CONFIG" > "$CONFIG_FILE"
        echo "初始化监控配置文件: $CONFIG_FILE"
    fi
    
    # 加载配置
    if command -v jq &> /dev/null; then
        ALERTS_ENABLED=$(jq -r '.alerts.enabled' "$CONFIG_FILE")
        MAX_BACKUP_AGE=$(jq -r '.alerts.max_backup_age_hours' "$CONFIG_FILE")
        MIN_DISK_SPACE=$(jq -r '.alerts.min_disk_space_gb' "$CONFIG_FILE")
        MAX_ERROR_COUNT=$(jq -r '.alerts.max_error_count' "$CONFIG_FILE")
        AUTO_FIX_ENABLED=$(jq -r '.auto_fix.enabled' "$CONFIG_FILE")
    else
        # 如果 jq 不可用，使用默认值
        ALERTS_ENABLED=true
        MAX_BACKUP_AGE=48
        MIN_DISK_SPACE=5
        MAX_ERROR_COUNT=3
        AUTO_FIX_ENABLED=true
    fi
}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"; }
alert() { echo -e "${RED}🚨 $1${NC}" | tee -a "$LOG_FILE"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"; }

# 初始化
mkdir -p "$BACKUP_DIR"
init_config
ALERTS=()

echo "============================================"
log "🔍 OpenClaw 备份监控开始"
log "配置文件: $CONFIG_FILE"
log "告警文件: $ALERT_FILE"
echo "============================================"

# ==================== 检查函数 ====================

check_backup_age() {
    info "检查备份时间..."
    
    # 查找最新备份
    LATEST_BACKUP=$(find "$BACKUP_DIR" \( -name "safe-*" -o -name "safe-*.tar.gz" \) -type f -exec stat -c %Y {} \; 2>/dev/null | sort -nr | head -1)
    
    if [ -z "$LATEST_BACKUP" ]; then
        alert "未找到任何备份文件"
        ALERTS+=("无备份文件")
        return 1
    fi
    
    NOW=$(date +%s)
    HOURS_AGO=$(( (NOW - LATEST_BACKUP) / 3600 ))
    
    if [ $HOURS_AGO -gt "$MAX_BACKUP_AGE" ]; then
        alert "备份过时：最近备份是 $HOURS_AGO 小时前（阈值: ${MAX_BACKUP_AGE}小时）"
        ALERTS+=("备份过时: ${HOURS_AGO}小时")
        return 1
    else
        success "备份新鲜度正常: $HOURS_AGO 小时前"
        return 0
    fi
}

check_disk_space() {
    info "检查磁盘空间..."
    
    # 获取 home 目录可用空间（GB）
    if command -v df &> /dev/null; then
        AVAILABLE_GB=$(df -BG "$HOME" | awk 'NR==2 {gsub("G","",$4); print $4}')
        
        if [ "$AVAILABLE_GB" -lt "$MIN_DISK_SPACE" ]; then
            alert "磁盘空间不足：仅剩 ${AVAILABLE_GB}GB（阈值: ${MIN_DISK_SPACE}GB）"
            ALERTS+=("磁盘空间不足: ${AVAILABLE_GB}GB")
            return 1
        else
            success "磁盘空间充足: ${AVAILABLE_GB}GB"
            return 0
        fi
    else
        warning "无法检查磁盘空间（df 命令不可用）"
        return 0
    fi
}

check_backup_integrity() {
    info "检查备份完整性..."
    
    # 检查备份目录结构
    if [ ! -d "$BACKUP_DIR" ]; then
        alert "备份目录不存在: $BACKUP_DIR"
        ALERTS+=("备份目录不存在")
        return 1
    fi
    
    # 检查备份索引
    if [ ! -f "$BACKUP_DIR/backup-index.json" ]; then
        warning "备份索引不存在"
        ALERTS+=("备份索引不存在")
    else
        success "备份索引存在"
    fi
    
    # 检查备份文件数量
    BACKUP_COUNT=$(find "$BACKUP_DIR" \( -name "safe-*" -o -name "safe-*.tar.gz" \) -type f | wc -l)
    
    if [ "$BACKUP_COUNT" -eq 0 ]; then
        alert "没有找到备份文件"
        ALERTS+=("无备份文件")
        return 1
    elif [ "$BACKUP_COUNT" -lt 3 ]; then
        warning "备份文件较少: $BACKUP_COUNT 个"
        ALERTS+=("备份文件少: ${BACKUP_COUNT}个")
    else
        success "备份文件数量正常: $BACKUP_COUNT 个"
    fi
    
    return 0
}

check_openclaw_service() {
    info "检查 OpenClaw 服务..."
    
    if ! command -v openclaw &> /dev/null; then
        alert "OpenClaw CLI 未安装"
        ALERTS+=("OpenClaw CLI 未安装")
        return 1
    fi
    
    if openclaw gateway status 2>/dev/null | grep -q "running"; then
        success "OpenClaw 服务运行正常"
        return 0
    else
        alert "OpenClaw 服务未运行"
        ALERTS+=("OpenClaw 服务未运行")
        return 1
    fi
}

check_health_status() {
    info "运行健康检查..."
    
    if [ -f "/tmp/koalabearBOT/scripts/health-check.sh" ]; then
        chmod +x "/tmp/koalabearBOT/scripts/health-check.sh"
        
        # 运行健康检查并捕获输出
        HEALTH_OUTPUT=$(/tmp/koalabearBOT/scripts/health-check.sh 2>&1)
        HEALTH_EXIT=$?
        
        if [ $HEALTH_EXIT -eq 0 ]; then
            success "健康检查通过"
            return 0
        else
            # 提取错误信息
            ERRORS=$(echo "$HEALTH_OUTPUT" | grep -c "❌")
            WARNINGS=$(echo "$HEALTH_OUTPUT" | grep -c "⚠️")
            
            alert "健康检查失败: $ERRORS 个错误, $WARNINGS 个警告"
            ALERTS+=("健康检查失败: ${ERRORS}错误 ${WARNINGS}警告")
            
            # 记录详细错误
            echo "$HEALTH_OUTPUT" >> "$BACKUP_DIR/health-check-details-$(date +%Y%m%d).log"
            return 1
        fi
    else
        warning "健康检查脚本不存在"
        return 0
    fi
}

# ==================== 自动修复函数 ====================

auto_fix_backup_age() {
    if [ "$AUTO_FIX_ENABLED" != "true" ]; then
        return 0
    fi
    
    info "尝试自动修复：运行新备份..."
    
    if [ -f "/tmp/koalabearBOT/scripts/daily-backup.sh" ]; then
        chmod +x "/tmp/koalabearBOT/scripts/daily-backup.sh"
        
        if /tmp/koalabearBOT/scripts/daily-backup.sh; then
            success "自动备份运行成功"
            return 0
        else
            alert "自动备份运行失败"
            return 1
        fi
    else
        alert "备份脚本不存在，无法自动修复"
        return 1
    fi
}

auto_clean_old_backups() {
    if [ "$AUTO_FIX_ENABLED" != "true" ]; then
        return 0
    fi
    
    info "清理旧备份..."
    
    # 清理30天前的备份
    find "$BACKUP_DIR" -name "safe-*" -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null || true
    find "$BACKUP_DIR" -name "safe-*.tar.gz" -mtime +30 -delete 2>/dev/null || true
    find "$BACKUP_DIR" -name "backup-*.log" -mtime +60 -delete 2>/dev/null || true
    
    success "已清理30天前的旧备份"
}

# ==================== 告警函数 ====================

send_alert() {
    if [ "$ALERTS_ENABLED" != "true" ]; then
        return 0
    fi
    
    local alert_message="$1"
    local alert_level="$2"
    local alert_time=$(date -Iseconds)
    
    info "发送告警: $alert_message"
    
    # 保存到告警文件
    ALERT_JSON=$(cat <<EOF
{
  "timestamp": "$alert_time",
  "level": "$alert_level",
  "message": "$alert_message",
  "checks_failed": ${#ALERTS[@]},
  "alerts": $(printf '%s\n' "${ALERTS[@]}" | jq -R . | jq -s .)
}
EOF
)
    
    # 如果 jq 可用，优雅地追加
    if command -v jq &> /dev/null; then
        if [ ! -f "$ALERT_FILE" ]; then
            echo '{"alerts": []}' > "$ALERT_FILE"
        fi
        
        jq --argjson new "$ALERT_JSON" '.alerts += [$new]' "$ALERT_FILE" > "$ALERT_FILE.tmp" && \
        mv "$ALERT_FILE.tmp" "$ALERT_FILE"
    else
        # 简单的文本追加
        echo "$ALERT_JSON" >> "$ALERT_FILE"
    fi
    
    # 这里可以添加发送到飞书、邮件等的代码
    # 示例：发送到飞书 webhook
    if [ -n "$FEISHU_WEBHOOK" ]; then
        curl -X POST "$FEISHU_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"msg_type\":\"text\",\"content\":{\"text\":\"$alert_message\"}}" \
            >/dev/null 2>&1 || true
    fi
}

# ==================== 主监控流程 ====================

main() {
    local failed_checks=0
    
    # 运行所有检查
    check_backup_age || ((failed_checks++))
    check_disk_space || ((failed_checks++))
    check_backup_integrity || ((failed_checks++))
    check_openclaw_service || ((failed_checks++))
    check_health_status || ((failed_checks++))
    
    # 汇总结果
    echo ""
    echo "============================================"
    log "📊 监控检查完成"
    log "总检查数: 5"
    log "失败检查: $failed_checks"
    log "告警数量: ${#ALERTS[@]}"
    echo "============================================"
    
    # 如果有失败，发送告警
    if [ $failed_checks -gt 0 ]; then
        ALERT_MSG="OpenClaw 备份监控告警：$failed_checks 个检查失败"
        
        for alert in "${ALERTS[@]}"; do
            ALERT_MSG="$ALERT_MSG\n- $alert"
        done
        
        send_alert "$ALERT_MSG" "error"
        
        # 自动修复
        if [ "$AUTO_FIX_ENABLED" = "true" ]; then
            info "尝试自动修复..."
            
            # 如果备份过时，运行新备份
            if [[ " ${ALERTS[*]} " =~ "备份过时" ]]; then
                auto_fix_backup_age
            fi
            
            # 清理旧备份
            auto_clean_old_backups
        fi
        
        # 如果有太多错误，退出码为2
        if [ $failed_checks -ge "$MAX_ERROR_COUNT" ]; then
            alert "🚨 严重：超过 $MAX_ERROR_COUNT 个检查失败，需要立即处理！"
            exit 2
        else
            exit 1
        fi
    else
        success "🎉 所有监控检查通过"
        
        # 清理旧告警（保留最近7天）
        if [ -f "$ALERT_FILE" ] && command -v jq &> /dev/null; then
            ONE_WEEK_AGO=$(date -d '7 days ago' +%s)
            jq --arg time "$ONE_WEEK_AGO" '.alerts = (.alerts | map(select(.timestamp | fromdateiso8601 > ($time | tonumber))))' "$ALERT_FILE" > "$ALERT_FILE.tmp" && \
            mv "$ALERT_FILE.tmp" "$ALERT_FILE"
        fi
        
        exit 0
    fi
}

# 运行主函数
main