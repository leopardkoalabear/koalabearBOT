# 🔐 OpenClaw 密钥安全管理指南

> **核心原则：密钥不出门，安全在心中**

## 🚨 安全红线

### ❌ 绝对禁止
1. **永远不要**在 Git 仓库中提交：
   - 真实的 `openclaw.json` 文件
   - 任何包含 `sk-` 的 API 密钥
   - 个人密码、令牌、私钥
   - 配置文件备份（`*.bak`, `*.backup`）

2. **永远不要**在日志中输出：
   - API 密钥的任何部分
   - 个人身份信息
   - 敏感配置内容

3. **永远不要**在代码中硬编码：
   - 任何形式的凭证
   - 访问令牌
   - 数据库连接字符串

## 🗝️ 密钥管理策略

### 级别1：环境变量（推荐）
```bash
# .bashrc 或 .zshrc
export OPENAI_API_KEY="sk-..."
export GITHUB_TOKEN="ghp_..."
export CUSTOM_API_KEY="sk-..."

# 在配置文件中引用
{
  "providers": {
    "openai": {
      "apiKey": "${OPENAI_API_KEY}"
    }
  }
}
```

### 级别2：1Password CLI（企业级）
```bash
# 安装 1Password CLI
# 配置后使用
export OPENAI_API_KEY=$(op item get "OpenAI API" --field credential)

# 或者直接使用
op run -- openclaw gateway start
```

### 级别3：加密配置文件
```bash
# 创建加密配置文件
gpg --encrypt --recipient your@email.com openclaw-secrets.json

# 使用时解密
gpg --decrypt openclaw-secrets.json.gpg > /tmp/secrets.json && \
openclaw --config /tmp/secrets.json && \
rm /tmp/secrets.json
```

## 🔧 安全配置示例

### 安全的 `openclaw.json` 模板
```json
{
  "providers": {
    "openai": {
      "apiKey": "${OPENAI_API_KEY}",
      "baseUrl": "https://api.openai.com/v1"
    },
    "custom-gptapi-asia": {
      "apiKey": "${CUSTOM_GPTAPI_ASIA_API_KEY}",
      "baseUrl": "https://gptapi.asia/v1"
    }
  },
  "features": {
    "secureMode": true,
    "logRedaction": true
  }
}
```

### 环境变量文件（`.env`）
```bash
# .env.example（模板）
OPENAI_API_KEY=REPLACE_WITH_YOUR_KEY
GITHUB_TOKEN=REPLACE_WITH_YOUR_TOKEN
CUSTOM_GPTAPI_ASIA_API_KEY=REPLACE_WITH_YOUR_KEY

# .env.local（本地，不上传）
# 从 1Password 获取真实值
```

## 🛡️ 安全审计工具

### 1. 密钥扫描脚本
```bash
#!/bin/bash
# scripts/scan-secrets.sh

# 扫描 Git 历史中的密钥
echo "扫描 Git 历史中的敏感信息..."
git log --all --full-history --name-only --pretty=format: | \
  sort -u | \
  xargs -I {} sh -c 'if [ -f "{}" ]; then grep -l "sk-\|ghp_\|xoxb-\|AKIA" "{}" 2>/dev/null; fi' | \
  sort -u

# 扫描当前文件
echo "扫描当前文件中的密钥..."
grep -r "sk-\|ghp_\|xoxb-\|AKIA" --include="*.json" --include="*.yml" --include="*.yaml" --include="*.js" --include="*.ts" . 2>/dev/null || true
```

### 2. 配置验证脚本
```bash
#!/bin/bash
# scripts/validate-config.sh

CONFIG_FILE="$HOME/.openclaw/openclaw.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ 配置文件不存在"
  exit 1
fi

# 检查是否包含明文密钥
if grep -q "sk-" "$CONFIG_FILE"; then
  echo "❌ 配置文件中包含明文 API 密钥"
  echo "   请使用环境变量：\${OPENAI_API_KEY}"
  exit 1
fi

# 检查环境变量引用
if ! grep -q "\${" "$CONFIG_FILE"; then
  echo "⚠️  配置文件中没有使用环境变量引用"
  echo "   建议使用：\${VARIABLE_NAME} 格式"
fi

echo "✅ 配置文件安全验证通过"
```

## 🔄 密钥轮换流程

### 每月密钥轮换检查清单
```markdown
## 📅 每月第1天执行

### 1. 列出所有 API 密钥
- [ ] OpenAI API 密钥
- [ ] GitHub Personal Access Token
- [ ] 自定义 API 提供商密钥
- [ ] 飞书/钉钉访问令牌
- [ ] 数据库连接字符串

### 2. 检查密钥权限
- [ ] 是否为最小必要权限？
- [ ] 是否有未使用的密钥？
- [ ] 是否有过期的密钥？

### 3. 轮换操作
- [ ] 生成新密钥
- [ ] 更新环境变量/1Password
- [ ] 测试新密钥
- [ ] 停用旧密钥（保留7天）
- [ ] 完全删除旧密钥

### 4. 审计日志
- [ ] 记录轮换时间
- [ ] 记录操作人员
- [ ] 记录影响范围
```

## 🚨 紧急响应流程

### 场景1：密钥泄露
```bash
# 立即行动
1. 在提供商控制台撤销泄露的密钥
2. 生成新密钥
3. 更新所有环境中的配置
4. 扫描日志和备份，清除泄露痕迹
5. 审计访问日志，确认泄露范围
```

### 场景2：配置文件误提交
```bash
# 从 Git 历史中彻底删除
git filter-repo --force \
  --path openclaw.json \
  --path ".env" \
  --path "*secret*" \
  --path "*key*" \
  --invert-paths

# 强制推送（警告协作者）
git push origin main --force

# 轮换所有相关密钥
```

### 场景3：设备丢失/被盗
```bash
1. 远程擦除设备（如果支持）
2. 撤销所有设备上的会话令牌
3. 轮换所有 API 密钥
4. 审查最近活动日志
5. 启用双因素认证（如果尚未启用）
```

## 📊 安全监控指标

### 每日检查
```bash
# 检查是否有明文密钥
scripts/scan-secrets.sh

# 检查配置安全性
scripts/validate-config.sh

# 检查密钥使用情况
openclaw gateway status | grep -i "auth\|key\|token"
```

### 监控告警规则
```yaml
安全监控规则:
  - 名称: 明文密钥检测
    条件: 文件包含 "sk-[a-zA-Z0-9]{48}"
    动作: 立即告警，阻止提交
    
  - 名称: 异常访问模式
    条件: 同一密钥短时间内多地区访问
    动作: 临时冻结，人工审核
    
  - 名称: 密钥使用超量
    条件: API 调用量突增 10倍
    动作: 限流告警，成本控制
```

## 🛠️ 安全工具推荐

### 1. 密钥管理
- **1Password**: 企业级密码管理
- **Bitwarden**: 开源密码管理
- **Hashicorp Vault**: 专业密钥管理
- **AWS Secrets Manager**: 云原生方案

### 2. 代码扫描
- **GitGuardian**: Git 密钥扫描
- **TruffleHog**: 密钥挖掘工具
- **gitleaks**: Git 历史扫描
- **detect-secrets**: 密钥检测框架

### 3. 安全审计
- **OWASP ZAP**: Web 安全测试
- **Nessus**: 漏洞扫描
- **Lynis**: Linux 安全审计
- **ClamAV**: 恶意软件扫描

## 📚 安全最佳实践

### 开发阶段
1. **使用预提交钩子**防止密钥提交
   ```bash
   # .git/hooks/pre-commit
   #!/bin/bash
   if grep -r "sk-\|ghp_" --include="*.json" --include="*.yml" .; then
     echo "❌ 检测到明文密钥，提交被阻止"
     exit 1
   fi
   ```

2. **代码审查**时重点关注：
   - 新添加的配置文件
   - 环境变量使用
   - 外部 API 调用

### 部署阶段
1. **区分环境**：开发、测试、生产使用不同密钥
2. **最小权限**：每个服务使用独立密钥
3. **密钥轮换**：定期（90天）更换密钥
4. **访问日志**：记录所有密钥使用情况

### 运维阶段
1. **定期审计**：每月审查密钥使用
2. **漏洞扫描**：每周扫描系统漏洞
3. **备份加密**：所有备份必须加密
4. **访问控制**：严格的权限管理

## 🆘 安全支持

### 紧急联系人
- **GitHub 安全**: security@github.com
- **OpenAI 支持**: support@openai.com
- **本地管理员**: 系统负责人

### 安全资源
- [OpenClaw 安全文档](https://docs.openclaw.ai/security)
- [OWASP 密钥管理指南](https://owasp.org/www-project-top-ten/)
- [GitHub 安全最佳实践](https://docs.github.com/en/security)

### 培训材料
- 安全意识培训（每季度）
- 应急响应演练（每半年）
- 安全代码审查（每次发布）

---

## 📝 安全承诺

作为 OpenClaw 用户，我承诺：

1. **保护密钥**：绝不泄露、共享或不当存储 API 密钥
2. **定期审计**：每月检查密钥安全状态
3. **及时响应**：发现安全问题立即报告和修复
4. **持续学习**：关注安全最佳实践，不断提升

> *"安全不是功能，是基础。密钥不是密码，是信任。"* 🔐

---

**最后检查**: $(date)  
**下次审计**: $(date -d '+30 days' '+%Y-%m-%d')  
**安全状态**: 🔒 受保护