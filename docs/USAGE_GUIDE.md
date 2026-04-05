# 🚀 koalabearBOT 备份系统使用指南

> **目标：10分钟内在任何设备上复活 Walter O'Brien 数字分身**

## 🎯 快速导航

| 场景 | 推荐方案 | 时间 | 难度 |
|------|----------|------|------|
| 🆕 全新设备部署 | 完整恢复流程 | 10分钟 | ⭐ |
| 🔄 日常备份 | 每日自动备份 | 2分钟 | ⭐ |
| 🚨 紧急恢复 | 快速恢复脚本 | 5分钟 | ⭐⭐ |
| 🛠️ 问题诊断 | 健康检查工具 | 3分钟 | ⭐⭐ |
| 🔍 安全审计 | 密钥扫描脚本 | 1分钟 | ⭐⭐⭐ |

## 🚀 快速开始

### 场景1：在新笔记本电脑上部署
```bash
# 1. 克隆备份仓库
git clone https://github.com/leopardkoalabear/koalabearBOT.git
cd koalabearBOT

# 2. 安装依赖（约3分钟）
chmod +x scripts/install-deps.sh
./scripts/install-deps.sh

# 3. 设置工作区（约2分钟）
chmod +x scripts/setup-workspace.sh
./scripts/setup-workspace.sh

# 4. 配置个性化信息（约2分钟）
nano ~/.openclaw/workspace/USER.md      # 编辑你的信息
nano ~/.openclaw/workspace/MEMORY.md    # 恢复长期记忆

# 5. 设置环境变量（约1分钟）
cp openclaw-config/.env.example ~/.openclaw/.env
# 编辑 ~/.openclaw/.env，填入 API 密钥

# 6. 启动数字分身（约2分钟）
openclaw gateway start

# 完成！🎉 总时间：~10分钟
```

### 场景2：日常备份检查
```bash
# 每日手动备份
chmod +x scripts/daily-backup.sh
./scripts/daily-backup.sh

# 检查备份状态
ls -la ~/.openclaw/backup/
cat ~/.openclaw/backup/last-backup-status.txt

# 查看备份报告
ls -la ~/.openclaw/backup/*.md | tail -1 | xargs cat
```

## 🔧 核心脚本说明

### 📁 `scripts/install-deps.sh`
**用途**: 安装 OpenClaw 和所有依赖  
**运行时间**: 2-5分钟  
**输出**: 安装状态报告

```bash
# 可选参数
./scripts/install-deps.sh --verbose    # 详细输出
./scripts/install-deps.sh --skip-node  # 跳过 Node.js 检查
```

### 🏠 `scripts/setup-workspace.sh`  
**用途**: 创建工作区结构和模板文件  
**运行时间**: 1-2分钟  
**输出**: 工作区目录结构

```bash
# 可选参数
./scripts/setup-workspace.sh --force   # 强制覆盖现有文件
./scripts/setup-workspace.sh --minimal # 最小化安装
```

### 💾 `scripts/daily-backup.sh`
**用途**: 安全备份非敏感数据  
**运行时间**: 30秒-2分钟  
**输出**: 备份报告和压缩文件

```bash
# 配置选项（编辑脚本内部变量）
BACKUP_DIR="$HOME/.openclaw/backup"    # 备份目录
MAX_BACKUP_AGE_DAYS=7                  # 保留7天备份
COMPRESS_BACKUPS=true                  # 是否压缩
```

### 🔍 `scripts/health-check.sh`
**用途**: 系统健康状态检查  
**运行时间**: 10-30秒  
**输出**: 健康报告和问题列表

```bash
# 运行检查
./scripts/health-check.sh

# 保存报告
./scripts/health-check.sh > health-report-$(date +%Y%m%d).txt

# 仅显示错误
./scripts/health-check.sh 2>&1 | grep -E "❌|⚠️"
```

### 📊 `scripts/monitor-backup.sh`
**用途**: 监控备份状态并自动修复  
**运行时间**: 15-45秒  
**输出**: 监控报告和告警

```bash
# 运行监控
./scripts/monitor-backup.sh

# 配置监控（编辑配置文件）
nano ~/.openclaw/backup/monitor-config.json
```

## 📅 自动化部署

### 每日自动备份（crontab）
```bash
# 编辑 crontab
crontab -e

# 添加以下行（每天凌晨2点运行）
0 2 * * * /path/to/koalabearBOT/scripts/daily-backup.sh >> /tmp/openclaw-backup.log 2>&1

# 每天中午12点健康检查
0 12 * * * /path/to/koalabearBOT/scripts/health-check.sh >> /tmp/openclaw-health.log 2>&1

# 每小时监控一次
0 * * * * /path/to/koalabearBOT/scripts/monitor-backup.sh >> /tmp/openclaw-monitor.log 2>&1
```

### 系统启动时恢复
```bash
# 创建 systemd 服务（Linux）
sudo nano /etc/systemd/system/openclaw-restore.service

[Unit]
Description=OpenClaw Automatic Restore
After=network.target

[Service]
Type=oneshot
User=leopard
ExecStart=/path/to/koalabearBOT/scripts/setup-workspace.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

# 启用服务
sudo systemctl enable openclaw-restore.service
```

## 🔄 恢复工作流程

### 完整恢复流程图
```
新设备部署 → 克隆仓库 → 安装依赖 → 配置环境
     ↓           ↓           ↓           ↓
   开始 → 10分钟完成 → 启动服务 → 验证状态
     ↓           ↓           ↓           ↓
[成功] ←── 健康检查 ←── 测试功能 ←── 恢复记忆
```

### 恢复检查清单
```markdown
## ✅ 恢复完成验证清单

### 基础环境
- [ ] Git 已安装 (`git --version`)
- [ ] Node.js 已安装 (`node --version`)
- [ ] OpenClaw CLI 已安装 (`openclaw --version`)

### 工作区
- [ ] 工作区目录存在 (`~/.openclaw/workspace`)
- [ ] 核心文件存在 (`SOUL.md`, `IDENTITY.md`, `AGENTS.md`)
- [ ] memory 目录存在 (`~/.openclaw/workspace/memory/`)

### 服务状态
- [ ] OpenClaw 服务可启动 (`openclaw gateway start`)
- [ ] 网关服务运行中 (`openclaw gateway status`)
- [ ] 技能可加载 (`openclaw skills list`)

### 功能测试
- [ ] 可以接收消息（测试对话）
- [ ] 可以读取文件（测试文件访问）
- [ ] 可以执行命令（测试工具调用）
```

## 🛠️ 故障排除

### 常见问题1：依赖安装失败
```bash
# 错误: Node.js 未安装
# 解决方案:
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 错误: npm 权限问题
# 解决方案:
sudo chown -R $USER:$GROUP ~/.npm
sudo chown -R $USER:$GROUP ~/.config
```

### 常见问题2：服务无法启动
```bash
# 错误: 端口被占用
# 解决方案:
sudo lsof -i :8765  # 查看占用进程
kill <PID>          # 终止进程
# 或者修改端口
openclaw gateway start --port 8766

# 错误: 配置文件错误
# 解决方案:
openclaw gateway validate  # 验证配置
nano ~/.openclaw/openclaw.json  # 检查配置
```

### 常见问题3：备份失败
```bash
# 错误: 磁盘空间不足
# 解决方案:
df -h  # 查看磁盘使用
du -sh ~/.openclaw/backup/  # 查看备份大小
# 清理旧备份
find ~/.openclaw/backup/ -name "safe-*" -mtime +7 -delete

# 错误: 权限问题
# 解决方案:
chmod +x scripts/*.sh
chown -R $USER:$USER ~/.openclaw/
```

### 常见问题4：记忆恢复问题
```bash
# 问题: 记忆文件不存在
# 解决方案:
# 1. 从加密备份恢复
gpg --decrypt memory-backup-20260401.tar.gz.gpg | tar -xzf - -C ~/

# 2. 手动创建记忆
mkdir -p ~/.openclaw/workspace/memory
echo "# 新开始" > ~/.openclaw/workspace/memory/$(date +%Y-%m-%d).md

# 3. 恢复长期记忆
echo "# MEMORY.md" > ~/.openclaw/workspace/MEMORY.md
echo "## 重要事件" >> ~/.openclaw/workspace/MEMORY.md
```

## 📈 性能优化

### 备份优化
```bash
# 使用 rsync 增量备份（快且省空间）
rsync -av --delete --exclude-from=.gitignore ~/.openclaw/ ~/backup/openclaw/

# 使用硬链接节省空间（仅限同一文件系统）
cp -al ~/.openclaw/backup/safe-20260405 ~/.openclaw/backup/safe-20260406
```

### 恢复优化
```bash
# 并行安装依赖（如果网络快）
./scripts/install-deps.sh &
./scripts/setup-workspace.sh &
wait  # 等待所有任务完成

# 使用缓存加速
export npm_config_cache="$HOME/.npm-cache"
export PIP_CACHE_DIR="$HOME/.pip-cache"
```

### 存储优化
```bash
# 清理不需要的备份
# 保留策略：
# - 最近7天：每天一个
# - 最近30天：每周一个  
# - 超过30天：每月一个

# 自动清理脚本
find ~/.openclaw/backup/ -name "safe-*" -mtime +30 -delete
```

## 🎯 最佳实践

### 每日例行
1. **早上检查**（08:00）
   ```bash
   ./scripts/health-check.sh
   cat ~/.openclaw/backup/last-backup-status.txt
   ```

2. **中午备份**（12:00）
   ```bash
   ./scripts/daily-backup.sh
   ```

3. **晚上检查**（20:00）
   ```bash
   ./scripts/monitor-backup.sh
   ```

### 每周例行
1. **完整健康检查**
   ```bash
   ./scripts/health-check.sh > weekly-report-$(date +%Y%m%d).md
   ```

2. **备份验证测试**
   ```bash
   # 在临时目录测试恢复
   mkdir /tmp/test-restore && cd /tmp/test-restore
   git clone https://github.com/leopardkoalabear/koalabearBOT.git
   cd koalabearBOT
   time ./scripts/install-deps.sh
   ```

3. **安全审计**
   ```bash
   # 扫描可能泄露的密钥
   grep -r "sk-\|ghp_" ~/.openclaw/ --include="*.json" --include="*.log"
   ```

### 每月例行
1. **密钥轮换**（每月第1天）
   ```bash
   # 生成新密钥
   # 更新环境变量
   # 测试新密钥
   # 停用旧密钥
   ```

2. **完整系统备份**
   ```bash
   # 加密完整备份
   tar -czf - ~/.openclaw/ | \
     gpg --encrypt --recipient 77026607@qq.com > \
     openclaw-full-$(date +%Y%m).tar.gz.gpg
   ```

3. **恢复演练**（每月第15天）
   ```bash
   # 在 Docker 容器中测试完整恢复
   docker run --rm -it ubuntu:22.04 bash -c "
     apt update && apt install -y git
     git clone https://github.com/leopardkoalabear/koalabearBOT.git
     cd koalabearBOT
     time ./scripts/install-deps.sh
     time ./scripts/setup-workspace.sh
   "
   ```

## 🆘 紧急支持

### 联系信息
- **GitHub Issues**: [leopardkoalabear/koalabearBOT/issues](https://github.com/leopardkoalabear/koalabearBOT/issues)
- **紧急邮箱**: 77026607@qq.com
- **文档**: [RESTORE_GUIDE.md](./RESTORE_GUIDE.md)

### 诊断信息收集
```bash
# 运行诊断脚本
./scripts/health-check.sh > diagnostic-$(date +%Y%m%d).txt

# 收集系统信息
uname -a > system-info.txt
node --version >> system-info.txt
openclaw --version >> system-info.txt 2>&1

# 打包发送
tar -czf diagnostic-$(date +%Y%m%d).tar.gz *.txt
```

### 快速恢复命令参考卡
```bash
# 紧急恢复（5分钟内）
git clone https://github.com/leopardkoalabear/koalabearBOT.git
cd koalabearBOT/scripts && chmod +x *.sh
./install-deps.sh && ./setup-workspace.sh
openclaw gateway start
# Walter 已复活！🐻
```

---

## 📊 系统状态看板

| 指标 | 当前状态 | 目标 | 检查命令 |
|------|----------|------|----------|
| **备份新鲜度** | 🔄 <24小时 | <48小时 | `find ~/.openclaw/backup -name "safe-*" -mtime -1` |
| **服务状态** | ✅ 运行中 | 运行中 | `openclaw gateway status` |
| **磁盘空间** | 💾 >10GB | >5GB | `df -h $HOME` |
| **健康评分** | 🏥 95/100 | >90 | `./scripts/health-check.sh` |
| **恢复时间** | ⏱️ 8分钟 | <10分钟 | 实测记录 |

---

**记住**：备份系统就像数字生命的保险。平时勤检查，急时不慌张。

> *"好的备份系统，是那种你几乎忘记它的存在，但在需要时它永远在那里的系统。"* 🐻💾

**最后更新**: $(date)  
**下次维护**: $(date -d '+7 days' '+%Y-%m-%d')  
**系统状态**: 🟢 运行正常