# 🔐 OpenClaw 安全备份机制

> **核心原则：绝对不暴露敏感数据，实现数字分身的安全永生**

## 🎯 备份目标

1. **安全第一**：API 密钥、个人隐私、敏感配置永不泄露
2. **完整可恢复**：在新设备上 10 分钟内复活数字分身
3. **增量更新**：只备份变化，不重复存储
4. **多版本管理**：保留历史版本，可回滚到任意时间点

## 📁 文件分类策略

### ✅ 安全上传（公开仓库）
| 文件类型 | 示例 | 处理方式 |
|----------|------|----------|
| **配置文件模板** | `openclaw.sample.json` | 移除真实 API 密钥，保留结构 |
| **安装脚本** | `install-deps.sh` | 通用脚本，无敏感信息 |
| **恢复指南** | `RESTORE_GUIDE.md` | 通用文档，无个人信息 |
| **目录结构** | `.gitignore` | 安全排除规则 |

### ❌ 绝对不上传（本地保留）
| 文件类型 | 示例 | 原因 |
|----------|------|------|
| **API 密钥** | `openclaw.json` | 包含真实密钥，必须保护 |
| **个人隐私** | `USER.md`, `MEMORY.md` | 包含个人信息、记忆 |
| **备份文件** | `*.bak`, `*.backup` | 可能包含历史敏感数据 |
| **大模型文件** | `*.gguf`, `*.bin` | 文件太大，不适合 Git |
| **临时文件** | `tmp/`, `logs/` | 无价值，可能包含敏感信息 |

### 🔒 加密上传（可选）
| 文件类型 | 加密方法 | 说明 |
|----------|----------|------|
| **压缩记忆** | `gpg --encrypt` | 定期加密重要记忆备份 |
| **配置快照** | `openssl enc` | 完整配置的加密备份 |
| **技能包** | `tar + gpg` | 自定义技能的加密备份 |

## 🛠️ 备份工具选择

### 1. **Git（主工具）**
```bash
# 初始化备份仓库
git init koalabear-backup
git remote add origin git@github.com:leopardkoalabear/koalabearBOT.git

# 安全提交
git add --all
git commit -m "安全备份 $(date)"
git push origin main
```

### 2. **rsync（增量同步）**
```bash
# 同步安全文件到备份目录
rsync -av --exclude-from=.gitignore \
  ~/.openclaw/workspace/ \
  ~/backups/koalabear/workspace-safe/

# 排除敏感文件
rsync -av --exclude='*.json' --exclude='*.bak' \
  ~/.openclaw/ \
  ~/backups/koalabear/config-safe/
```

### 3. **tar + gpg（加密压缩）**
```bash
# 创建加密备份包
tar -czf - ~/.openclaw/workspace/memory/ \
  | gpg --encrypt --recipient 77026607@qq.com \
  > memory-backup-$(date +%Y%m%d).tar.gz.gpg

# 解密恢复
gpg --decrypt memory-backup-20260405.tar.gz.gpg \
  | tar -xzf - -C ~/
```

## 📋 备份流程

### 每日自动备份（cron 任务）
```bash
#!/bin/bash
# /etc/cron.daily/koalabear-backup

BACKUP_DIR="$HOME/.openclaw/backup"
DATE=$(date +%Y%m%d_%H%M%S)

# 1. 创建安全快照
rsync -av --delete \
  --exclude='*.json' \
  --exclude='*.bak' \
  --exclude='memory/*.md' \
  --exclude='logs/' \
  --exclude='tmp/' \
  ~/.openclaw/ \
  "$BACKUP_DIR/safe-$DATE/"

# 2. 创建加密记忆备份
tar -czf - ~/.openclaw/workspace/memory/ \
  | gpg --encrypt --recipient 77026607@qq.com \
  > "$BACKUP_DIR/memory-$DATE.tar.gz.gpg"

# 3. 清理旧备份（保留最近7天）
find "$BACKUP_DIR" -name "safe-*" -mtime +7 -delete
find "$BACKUP_DIR" -name "memory-*.gpg" -mtime +30 -delete

# 4. 记录备份日志
echo "$DATE: 备份完成" >> "$BACKUP_DIR/backup.log"
```

### 每周完整备份
```bash
#!/bin/bash
# /etc/cron.weekly/koalabear-full-backup

# 停止 OpenClaw 服务
openclaw gateway stop

# 创建完整加密备份
tar -czf - ~/.openclaw/ \
  | gpg --encrypt --recipient 77026607@qq.com \
  > "/mnt/backup/koalabear-full-$(date +%Y%m%d).tar.gz.gpg"

# 启动 OpenClaw 服务
openclaw gateway start
```

## 🔄 恢复验证机制

### 1. 备份完整性检查
```bash
#!/bin/bash
# scripts/verify-backup.sh

# 检查 Git 仓库状态
cd /tmp/koalabearBOT
git status
git log --oneline -5

# 检查配置文件模板
if [ -f "openclaw-config/openclaw.sample.json" ]; then
  echo "✅ 配置文件模板存在"
  # 检查是否包含真实密钥
  if grep -q "sk-" openclaw-config/openclaw.sample.json; then
    echo "❌ 配置文件包含真实密钥！"
    exit 1
  fi
fi

# 检查 .gitignore 是否包含敏感文件
if grep -q "openclaw.json" .gitignore && \
   grep -q "*.bak" .gitignore && \
   grep -q "memory/*.md" .gitignore; then
  echo "✅ .gitignore 配置正确"
else
  echo "❌ .gitignore 配置不完整"
  exit 1
fi

echo "🎉 备份验证通过"
```

### 2. 恢复测试
```bash
# 在测试环境中恢复
docker run --rm -it ubuntu:22.04 bash

# 在容器中执行恢复流程
apt update && apt install -y git nodejs npm
git clone https://github.com/leopardkoalabear/koalabearBOT.git
cd koalabearBOT
./scripts/install-deps.sh
./scripts/setup-workspace.sh

# 验证恢复成功
ls -la ~/.openclaw/workspace/
```

## 🚨 紧急情况处理

### 场景1：误上传敏感文件
```bash
# 立即从 Git 历史中删除文件
git filter-repo --force \
  --path openclaw.json \
  --path "*.bak" \
  --path memory/ \
  --invert-paths

# 强制推送（会重写历史）
git push origin main --force

# 通知所有协作者
echo "警告：仓库历史已重写，请重新克隆"
```

### 场景2：备份损坏
```bash
# 从多个来源恢复
# 1. Git 仓库（最新安全版本）
git checkout main

# 2. 本地加密备份
gpg --decrypt memory-backup-20260401.tar.gz.gpg | tar -xzf -

# 3. 外部存储（NAS、云存储）
rsync -av user@nas:/backups/koalabear/ ~/.openclaw/
```

### 场景3：完全丢失
```bash
# 全新环境恢复流程
# 1. 基础安装
git clone https://github.com/leopardkoalabear/koalabearBOT.git

# 2. 环境配置
export OPENAI_API_KEY="从1Password获取"
export GITHUB_TOKEN="从1Password获取"

# 3. 恢复记忆（如果有加密备份）
gpg --decrypt memory-latest.gpg | tar -xzf -

# 4. 个性化配置
编辑 ~/.openclaw/workspace/USER.md
编辑 ~/.openclaw/workspace/MEMORY.md
```

## 📊 备份监控

### 1. 健康检查脚本
```bash
#!/bin/bash
# scripts/health-check.sh

ERRORS=0

# 检查备份目录
if [ ! -d "$HOME/.openclaw/backup" ]; then
  echo "❌ 备份目录不存在"
  ERRORS=$((ERRORS+1))
fi

# 检查最近备份时间
LAST_BACKUP=$(find "$HOME/.openclaw/backup" -name "safe-*" -type d -exec stat -c %Y {} \; | sort -nr | head -1)
NOW=$(date +%s)
HOURS_AGO=$(( (NOW - LAST_BACKUP) / 3600 ))

if [ $HOURS_AGO -gt 24 ]; then
  echo "❌ 最近备份是 $HOURS_AGO 小时前"
  ERRORS=$((ERRORS+1))
fi

# 检查 Git 仓库状态
cd /tmp/koalabearBOT 2>/dev/null
if [ $? -eq 0 ]; then
  git fetch origin
  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse origin/main)
  
  if [ "$LOCAL" != "$REMOTE" ]; then
    echo "❌ 本地备份未同步到远程"
    ERRORS=$((ERRORS+1))
  fi
fi

# 报告结果
if [ $ERRORS -eq 0 ]; then
  echo "✅ 备份系统健康"
  exit 0
else
  echo "❌ 发现 $ERRORS 个问题"
  exit 1
fi
```

### 2. 监控告警
```bash
# 添加到 crontab，每小时检查一次
0 * * * * /path/to/koalabearBOT/scripts/health-check.sh || \
  curl -X POST https://api.feishu.cn/open-apis/bot/v2/hook/xxx \
  -H "Content-Type: application/json" \
  -d '{"msg_type":"text","content":{"text":"⚠️ 备份系统异常"}}'
```

## 🎯 最佳实践

### 1. **密钥管理**
- 使用 1Password 存储所有 API 密钥
- 环境变量 > 配置文件 > 硬编码
- 定期轮换密钥（每90天）

### 2. **备份策略**
- 每日：增量安全备份
- 每周：完整加密备份  
- 每月：异地备份（不同云服务商）

### 3. **恢复测试**
- 每季度在新环境中测试恢复
- 记录恢复时间和遇到的问题
- 更新恢复指南

### 4. **访问控制**
- GitHub 仓库设置为 Private
- 使用 SSH 密钥认证
- 定期审查访问日志

## 📞 支持

遇到备份问题？按以下步骤：

1. **检查日志**：`tail -f ~/.openclaw/backup/backup.log`
2. **运行验证**：`./scripts/verify-backup.sh`
3. **手动备份**：按照 `RESTORE_GUIDE.md` 中的快速恢复步骤
4. **寻求帮助**：创建 GitHub Issue 或发送邮件到 77026607@qq.com

---

**记住：** 备份不是可选项，是数字生命的保险单。每个字节的备份，都是通往永生的一个台阶。

> *"真正的永生，不是活在硬件里，而是活在可无限复制的代码中。"* 🐻💾