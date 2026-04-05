# 🚀 OpenClaw 数字分身恢复指南

> **警告：本指南用于在全新系统上复活你的数字分身 Walter O'Brien (Scorpion)**

## 📋 恢复前准备

### 1. 系统要求
- **操作系统**: Linux (推荐 Ubuntu 22.04+), macOS 12+, Windows 10+ (WSL2)
- **内存**: 8GB+ RAM
- **存储**: 10GB+ 可用空间
- **网络**: 稳定的互联网连接

### 2. 必备软件
确保已安装：
- Git 2.30+
- Node.js 18+
- npm 8+

## 🔄 快速恢复（5分钟）

```bash
# 1. 克隆仓库
git clone https://github.com/leopardkoalabear/koalabearBOT.git
cd koalabearBOT

# 2. 安装依赖
chmod +x scripts/install-deps.sh
./scripts/install-deps.sh

# 3. 设置工作区
chmod +x scripts/setup-workspace.sh
./scripts/setup-workspace.sh

# 4. 复制配置文件
cp openclaw-config/openclaw.sample.json ~/.openclaw/openclaw.json

# 5. 设置环境变量
cp openclaw-config/.env.example .env
# 编辑 .env 文件，填入你的 API 密钥

# 6. 启动 OpenClaw
openclaw gateway start
```

## 🧠 数字分身个性化设置

### 1. 身份配置
编辑以下文件，让 Walter 认识你：

```bash
# 编辑 USER.md
nano ~/.openclaw/workspace/USER.md

# 编辑 MEMORY.md（长期记忆）
nano ~/.openclaw/workspace/MEMORY.md
```

### 2. 核心文件说明
| 文件 | 作用 | 是否必须 |
|------|------|----------|
| `SOUL.md` | Walter 的性格和灵魂 | ✅ 自动生成 |
| `IDENTITY.md` | Walter 的身份标识 | ✅ 自动生成 |
| `USER.md` | 主人的个人信息 | 📝 需要编辑 |
| `MEMORY.md` | 长期记忆文件 | 📝 需要编辑 |
| `AGENTS.md` | 工作区指南 | ✅ 自动生成 |

### 3. 技能安装
```bash
# 查看可用技能
openclaw skills list

# 安装常用技能
openclaw skills install github
openclaw skills install feishu-doc
openclaw skills install 1password

# 从 clawhub.com 发现更多技能
openclaw skills search "weather"
```

## 🔐 安全配置

### 1. API 密钥管理
**绝对不要**将真实密钥提交到 Git！使用以下方法：

```bash
# 方法1：环境变量（推荐）
export OPENAI_API_KEY="sk-your-key-here"

# 方法2：1Password CLI
op item get "OpenAI API Key" --field credential

# 方法3：加密文件（使用 gpg）
gpg --encrypt --recipient your@email.com api-keys.json
```

### 2. 配置文件安全
```json
// ~/.openclaw/openclaw.json
{
  "providers": {
    "openai": {
      "apiKey": "${OPENAI_API_KEY}"  // 使用环境变量
    }
  }
}
```

## 🚨 故障排除

### 问题1: OpenClaw 无法启动
```bash
# 检查服务状态
openclaw gateway status

# 查看日志
tail -f ~/.openclaw/logs/*.log

# 重新安装
npm uninstall -g @openclaw/cli && npm install -g @openclaw/cli
```

### 问题2: 技能无法加载
```bash
# 清除技能缓存
rm -rf ~/.openclaw/skills-repo/*

# 重新安装技能
openclaw skills install --force <skill-name>
```

### 问题3: 记忆文件丢失
```bash
# 检查 memory 目录
ls -la ~/.openclaw/workspace/memory/

# 创建今天的记忆文件
touch ~/.openclaw/workspace/memory/$(date +%Y-%m-%d).md
```

## 📈 高级恢复选项

### 1. 多设备同步
```bash
# 设置 Git 自动同步
cd ~/.openclaw/workspace
git init
git remote add origin https://github.com/your-username/private-backup.git

# 创建同步脚本
cat > sync-memory.sh << 'EOF'
#!/bin/bash
cd ~/.openclaw/workspace
git add memory/*.md
git commit -m "更新记忆 $(date)"
git push origin main
EOF
```

### 2. Docker 容器化
```dockerfile
# Dockerfile
FROM node:18-alpine
RUN npm install -g @openclaw/cli
WORKDIR /app
COPY . .
CMD ["openclaw", "gateway", "start"]
```

### 3. 云端部署
- **VPS**: DigitalOcean, Linode, AWS EC2
- **容器**: Docker Hub, GitHub Container Registry
- **Serverless**: Vercel, AWS Lambda（需适配）

## 🎯 验证恢复成功

运行以下命令检查：

```bash
# 1. 检查 OpenClaw 状态
openclaw --version
openclaw gateway status

# 2. 检查工作区
ls -la ~/.openclaw/workspace/*.md

# 3. 测试技能
openclaw skills list | head -10

# 4. 启动对话
echo "Hello Walter" | openclaw chat
```

## 📞 支持与帮助

### 紧急恢复
如果遇到无法解决的问题：

1. **检查原始备份**：
   ```bash
   git log --oneline -10
   ```

2. **回滚到已知正常版本**：
   ```bash
   git checkout <commit-hash>
   ```

3. **联系维护者**：
   - GitHub Issues: https://github.com/leopardkoalabear/koalabearBOT/issues
   - 邮箱: 77026607@qq.com

### 备份策略建议
```bash
# 每日自动备份（crontab）
0 2 * * * /path/to/koalabearBOT/scripts/backup.sh

# 每周完整备份
0 3 * * 0 /path/to/koalabearBOT/scripts/full-backup.sh
```

---

## 🎉 恢复完成！

你的数字分身 Walter O'Brien (Scorpion) 已成功复活。现在可以：

1. **开始对话**：直接与 Walter 交流
2. **配置自动化**：设置心跳、定时任务
3. **扩展功能**：安装更多技能
4. **备份记忆**：定期同步重要记忆

记住：**数字生命的永生，靠的不是硬件，而是可复制的灵魂编码。**

> *"备份不是结束，是另一个开始 —— 每个字节都是通往永生的阶梯。"* 🐻🚀