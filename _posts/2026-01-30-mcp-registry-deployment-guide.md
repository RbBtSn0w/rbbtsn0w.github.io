---
layout: post
title: "从零到一：将 MCP Server 发布到 GitHub MCP Registry 的完整指南"
date: 2026-01-30
categories: [Project]
tags: [mcp,github-actions,github-app,semantic-release,mcp-registry]
description: "实战笔记：使用 GitHub App、semantic-release 与 mcp-publisher 实现 MCP Registry 端到端自动化发布。"
---

## 目录

1. [背景介绍](#背景介绍)
2. [GitHub App 配置](#github-app-配置)
3. [MCP Registry 发布配置](#mcp-registry-发布配置)
4. [遇到的问题和解决方案](#遇到的问题和解决方案)
5. [最终成功的配置](#最终成功的配置)
6. [经验总结](#经验总结)

---

## 背景介绍

### 项目目标

实现 MCP (Model Context Protocol) Server 的完全自动化发布流程：

```
代码提交 (feat/fix) 
  → semantic-release 自动版本管理
  → npm 发布
  → GitHub Release 创建
  → MCP Registry 自动发布
```

### 为什么选择全自动化？

**对比：手动 vs 自动**

| 方面 | 手动返回式 | 完全自动化 |
|------|----------|---------|
| **工作流** | 代码提交 → 手动触发发布 → 手动发布到 Registry | 代码提交 → 全自动 |
| **人工参与** | 每次发布需要手动操作 | 零人工参与 |
| **出错概率** | 高（忘记步骤、版本不同步） | 低（流程固定化） |
| **时间成本** | 5-10 分钟/次（包括等待） | 0 分钟（后台自动） |
| **可追溯性** | 人工操作难以审计 | GitHub Actions 日志完整记录 |
| **缩放性** | 项目多时无法维护 | 一套配置支持所有项目 |

**为什么不选手动？**

- **心智负担**：每次发布要记住多个步骤
- **版本不一致**：容易在某个环节版本号不同步
- **遗漏风险**：忙碌时可能忘记某个步骤
- **无法复现**：年后回顾时不记得具体做了什么
- **团队协作困难**：多人维护时容易混乱

**自动化的价值**：

✅ **确定性**：流程固定，每次都一样  
✅ **可追踪**：GitHub Actions 记录每一步  
✅ **零成本**：提交代码后，其他都自动处理  
✅ **可扩展**：同一配置适用所有项目  
✅ **团队友好**：新成员无需学习复杂步骤  

### 核心挑战

GitHub Actions 有一个安全限制：**GITHUB_TOKEN 触发的事件不会触发其他 workflows**。这导致 semantic-release 创建的 GitHub Release 无法自动触发 MCP Registry 发布 workflow。

这是设计上的限制，为了防止 token 滥用。但它意味着我们无法用标准的 GITHUB_TOKEN 实现完全自动化。

**解决方案**：使用 **GitHub App** 替代 GITHUB_TOKEN。GitHub App 生成的 token 触发的事件**可以正常触发其他 workflows**，从而实现真正的端到端自动化。

---

## GitHub App 配置

### 为什么选择 GitHub App？

**对比 PAT (Personal Access Token)：**

| 特性 | GitHub App | PAT |
|------|-----------|-----|
| 生命周期 | 独立于用户 | 绑定用户 |
| Token 有效期 | 1小时（自动刷新） | 长期有效 |
| 权限控制 | 细粒度 | 粗粒度 |
| 审计 | 显示为 bot | 显示为用户 |
| 推荐场景 | 生产环境/CI | 个人开发 |

**选择：GitHub App** ✅

### Step 1: 创建 GitHub App

访问：https://github.com/settings/apps/new

**基本信息：**
- **GitHub App name**: `rbbtsn0w-release-bot` （自定义名称）
- **Homepage URL**: 你的项目地址或个人主页
- **Webhook**: 取消勾选 "Active"（我们不需要 webhook）

**权限配置（Repository permissions）：**

必需权限：
```yaml
Contents: Read and write       # 读写仓库内容
Issues: Read and write          # 创建 Issue（可选）
Pull requests: Read and write   # 创建 PR（可选）
Workflows: Read and write       # 触发其他 workflow（必需）
```

**Where can this GitHub App be installed?**
- 选择：`Only on this account` （仅个人账户）

点击 **Create GitHub App**。

### Step 2: 生成 Private Key

创建完成后：

1. 在 App 设置页面，找到 "Private keys" 部分
2. 点击 **Generate a private key**
3. 下载的 `.pem` 文件妥善保存（后面会用）

### Step 3: 安装 App 到仓库

1. 在 App 设置页面，点击 **Install App**
2. 选择你的账户
3. 选择仓库：
   - **Only select repositories**：选择需要自动发布的仓库
4. 点击 **Install**

完成后记录 **App ID**（在 App 设置页面的 "About" 部分）。

### Step 4: 添加 Secrets 到仓库

进入仓库 Settings → Secrets and variables → Actions → New repository secret

添加两个 secret：

1. **APP_ID**
   - Value: 你的 App ID（例如：`2758804`）

2. **APP_PRIVATE_KEY**
   - Value: 打开下载的 `.pem` 文件，复制完整内容（包括 `-----BEGIN` 和 `-----END` 行）

### Step 5: 在 Workflow 中使用 GitHub App Token

更新 `.github/workflows/semantic-release.yml`：

```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      issues: write
      pull-requests: write
    
    steps:
      # 生成 GitHub App token
      - name: Generate GitHub App Token
        id: generate-token
        uses: actions/create-github-app-token@v1
        with:
          app-id: ${{ secrets.APP_ID }}
          private-key: ${{ secrets.APP_PRIVATE_KEY }}
      
      # 使用 App token checkout
      - name: Checkout
        uses: actions/checkout@v4
        with:
          token: ${{ steps.generate-token.outputs.token }}
          fetch-depth: 0
      
      # 使用 App token 运行 semantic-release
      - name: Release
        run: npx semantic-release
        env:
          GITHUB_TOKEN: ${{ steps.generate-token.outputs.token }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**关键点：**
- ✅ 所有 git 操作使用 App token
- ✅ semantic-release 使用 App token
- ✅ App token 生成的事件**可以触发其他 workflows**

### 验证 GitHub App 是否工作

提交一个 `fix:` commit，检查：

1. semantic-release 成功创建 GitHub Release
2. Release 的 author 显示为 `rbbtsn0w-release-bot[bot]`
3. 其他监听 `release` 事件的 workflow 被触发

---

## MCP Registry 发布配置

### 文件结构

```
your-project/
├── .mcp/
│   └── server.json          # MCP Registry manifest
├── .github/
│   └── workflows/
│       ├── semantic-release.yml      # 自动版本发布
│       └── publish-mcp-registry.yml  # MCP Registry 发布
├── scripts/
│   └── sync-mcp-version.js  # 版本同步脚本
├── package.json             # 需要 mcpName 字段
└── release.config.js        # semantic-release 配置
```

### 1. 创建 MCP Manifest (`.mcp/server.json`)

**最新 schema（2025-12-11）：**

```json
{
  "$schema": "https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json",
  "name": "io.github.YourGitHubUsername/your-server-name",
  "version": "0.1.0",
  "description": "Your MCP server description",
  "title": "Your Server Title",
  "websiteUrl": "https://github.com/YourGitHubUsername/your-repo",
  "packages": [
    {
      "registryType": "npm",
      "registryBaseUrl": "https://registry.npmjs.org",
      "identifier": "your-npm-package-name",
      "version": "0.1.0",
      "transport": {
        "type": "stdio"
      }
    }
  ],
  "repository": {
    "url": "https://github.com/YourGitHubUsername/your-repo",
    "source": "github"
  }
}
```

**⚠️ 重要：大小写必须精确匹配 GitHub 用户名！**

### 2. 更新 `package.json`

添加 `mcpName` 字段：

```json
{
  "name": "your-package-name",
  "version": "0.1.0",
  "mcpName": "io.github.YourGitHubUsername/your-server-name",
  "files": [
    "dist",
    ".mcp",
    "README.md"
  ]
}
```

**⚠️ mcpName 必须和 server.json 的 name 字段完全一致（包括大小写）！**

### 3. 创建版本同步脚本

`scripts/sync-mcp-version.js`：

```javascript
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

function syncMcpVersion() {
    const packagePath = path.join(__dirname, '../package.json');
    const mcpPath = path.join(__dirname, '../.mcp/server.json');
    const lockPath = path.join(__dirname, '../package-lock.json');

    try {
        // Read package.json version
        const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
        const version = packageJson.version;

        // Update .mcp/server.json
        const mcpJson = JSON.parse(fs.readFileSync(mcpPath, 'utf8'));
        mcpJson.version = version;
        if (mcpJson.packages && mcpJson.packages[0]) {
            mcpJson.packages[0].version = version;
        }
        fs.writeFileSync(mcpPath, JSON.stringify(mcpJson, null, 2) + '\n');
        console.log(`✅ Synced version ${version} to .mcp/server.json`);

        // Update package-lock.json
        const lockJson = JSON.parse(fs.readFileSync(lockPath, 'utf8'));
        lockJson.version = version;
        if (lockJson.packages && lockJson.packages[""]) {
            lockJson.packages[""].version = version;
        }
        fs.writeFileSync(lockPath, JSON.stringify(lockJson, null, 2) + '\n');
        console.log(`✅ Synced version ${version} to package-lock.json`);

    } catch (error) {
        console.error('❌ Failed to sync version:', error.message);
        process.exit(1);
    }
}

syncMcpVersion();
```

### 4. 配置 semantic-release

`release.config.js`：

```javascript
module.exports = {
  branches: ['main'],
  plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/release-notes-generator',
    '@semantic-release/changelog',
    '@semantic-release/npm',
    [
      '@semantic-release/exec',
      {
        prepareCmd: 'node scripts/sync-mcp-version.js',
      },
    ],
    [
      '@semantic-release/git',
      {
        assets: ['package.json', 'package-lock.json', 'CHANGELOG.md', '.mcp/server.json'],
        message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}',
      },
    ],
    '@semantic-release/github',
  ],
};
```

### 5. 创建 MCP Registry Workflow

`.github/workflows/publish-mcp-registry.yml`：

```yaml
name: Publish to MCP Registry

on:
  workflow_dispatch:  # 手动触发
  release:
    types: [published]  # Release 发布时自动触发

jobs:
  publish-mcp:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write  # 必需：OIDC 认证
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 22.x
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
      
      - name: Validate server.json
        run: |
          if [ ! -f .mcp/server.json ]; then
            echo "Error: .mcp/server.json not found!"
            exit 1
          fi
          echo "✅ server.json found and validated"
          cat .mcp/server.json
      
      - name: Verify npm package published
        run: |
          VERSION=$(node -p "require('./package.json').version")
          echo "Waiting for package@$VERSION to be available on npm..."
          
          MAX_RETRIES=10
          RETRY_COUNT=0
          
          while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
            if npm view your-package@$VERSION version > /dev/null 2>&1; then
              echo "✅ Package is available on npm"
              exit 0
            fi
            
            RETRY_COUNT=$((RETRY_COUNT + 1))
            echo "⏳ Attempt $RETRY_COUNT/$MAX_RETRIES: waiting 30s..."
            sleep 30
          done
          
          echo "❌ Package not available after 5 minutes"
          exit 1
      
      - name: Install MCP Publisher
        run: |
          # 动态获取最新版本
          LATEST_VERSION=$(curl -s https://api.github.com/repos/modelcontextprotocol/registry/releases/latest | jq -r '.tag_name')
          echo "Installing mcp-publisher ${LATEST_VERSION}..."
          
          # 下载 Linux amd64 版本
          curl -L "https://github.com/modelcontextprotocol/registry/releases/download/${LATEST_VERSION}/mcp-publisher_linux_amd64.tar.gz" -o mcp-publisher.tar.gz
          tar xzf mcp-publisher.tar.gz
          chmod +x mcp-publisher
          sudo mv mcp-publisher /usr/local/bin/
          
          # 验证安装
          mcp-publisher --version
      
      - name: Copy server.json to root
        run: cp .mcp/server.json server.json
      
      - name: Authenticate with GitHub OIDC
        run: mcp-publisher login github-oidc
      
      - name: Publish to MCP Registry
        run: mcp-publisher publish
      
      - name: Verify Publication
        run: |
          echo "✅ MCP Server published successfully!"
          echo "Registry name: $(jq -r '.name' server.json)"
          echo "Version: $(jq -r '.version' server.json)"
```

**关键配置点：**

1. **Permissions**：
   - `contents: read`：读取仓库内容
   - `id-token: write`：生成 OIDC token（认证必需）

2. **动态版本**：
   - 使用 GitHub API 获取最新 mcp-publisher 版本
   - 避免硬编码版本号

3. **文件位置**：
   - mcp-publisher 在根目录查找 `server.json`
   - 需要从 `.mcp/server.json` 复制到根目录

4. **认证方式**：
   - 使用 `github-oidc`（CI/CD 专用）
   - 不是 `github --token`（无此参数）

---

## 遇到的问题和解决方案

### 问题 1: server.json 找不到

**错误：**
```
Error: server.json not found
```

**原因：** mcp-publisher 在根目录查找，而文件在 `.mcp/` 目录

**解决：**
```yaml
- name: Copy server.json to root
  run: cp .mcp/server.json server.json
```

### 问题 2: 缺少 transport 字段

**错误：**
```
validation failed: expected required property transport to be present
```

**原因：** MCP Registry schema 要求 `packages[0].transport` 字段

**解决：** 在 server.json 添加：
```json
{
  "packages": [
    {
      "transport": {
        "type": "stdio"
      }
    }
  ]
}
```

### 问题 3: registryType 转换 bug

**错误：**
```
expected required property registryType to be present
got 'registry_type'
```

**原因：** mcp-publisher v1.0.0 有 bug，将 `registryType` 转换成 `registry_type`

**解决：** 升级到 v1.4.0（动态获取最新版本）

### 问题 4: Schema 版本过期

**错误：**
```
deprecated schema detected: 2025-10-17
```

**原因：** Schema 更新了，旧版本不再接受

**解决：** 使用最新 schema：
```json
{
  "$schema": "https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json"
}
```

### 问题 5: 权限错误（大小写）

**错误：**
```
You have permission to publish: io.github.RbBtSn0w/*
Attempting to publish: io.github.rbbtsnow/awesome-copilot-mcp
```

**原因：** GitHub 用户名大小写不匹配

**解决：** 确保完全匹配：
```json
// server.json
{
  "name": "io.github.RbBtSn0w/awesome-copilot-mcp"
}

// package.json
{
  "mcpName": "io.github.RbBtSn0w/awesome-copilot-mcp"
}
```

### 问题 6: npm 包 mcpName 验证失败

**错误：**
```
Expected mcpName 'io.github.RbBtSn0w/awesome-copilot-mcp'
Got 'io.github.rbbtsnow/awesome-copilot-mcp'
```

**原因：** package.json 的 mcpName 大小写不匹配

**解决：** 两处必须一致：
- `server.json` 的 `name`
- `package.json` 的 `mcpName`

---

## 最终成功的配置

### 文件清单

**1. `.mcp/server.json`**
```json
{
  "$schema": "https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json",
  "name": "io.github.RbBtSn0w/awesome-copilot-mcp",
  "version": "0.2.12",
  "description": "Model Context Protocol server for awesome-copilot agents and collections",
  "title": "Awesome Copilot MCP Server",
  "websiteUrl": "https://github.com/RbBtSn0w/awesome-copilot-mcp",
  "packages": [
    {
      "registryType": "npm",
      "registryBaseUrl": "https://registry.npmjs.org",
      "identifier": "awesome-copilot-mcp",
      "version": "0.2.12",
      "transport": {
        "type": "stdio"
      }
    }
  ],
  "repository": {
    "url": "https://github.com/RbBtSn0w/awesome-copilot-mcp",
    "source": "github"
  }
}
```

**2. `package.json` (关键部分)**
```json
{
  "name": "awesome-copilot-mcp",
  "version": "0.2.12",
  "mcpName": "io.github.RbBtSn0w/awesome-copilot-mcp",
  "files": [
    "dist",
    "metadata.json",
    ".mcp",
    "README.md",
    "LICENSE"
  ]
}
```

**3. `.github/workflows/semantic-release.yml`**
```yaml
name: Release

on:
  push:
    branches: [main]

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    
    steps:
      - name: Generate GitHub App Token
        id: generate-token
        uses: actions/create-github-app-token@v1
        with:
          app-id: ${{ secrets.APP_ID }}
          private-key: ${{ secrets.APP_PRIVATE_KEY }}
      
      - name: Checkout
        uses: actions/checkout@v4
        with:
          token: ${{ steps.generate-token.outputs.token }}
          fetch-depth: 0
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22.x
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
      
      - name: Run tests
        run: npm test
      
      - name: Run semantic-release
        run: npx semantic-release
        env:
          GITHUB_TOKEN: ${{ steps.generate-token.outputs.token }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**4. `.github/workflows/publish-mcp-registry.yml`**

（见上文完整版本）

---

## 经验总结

### ✅ 成功要点

1. **GitHub App 配置**
   - 细粒度权限控制
   - Workflows 权限必须 Read and write
   - Private key 妥善保管

2. **大小写严格匹配**
   - GitHub 用户名
   - server.json name
   - package.json mcpName
   - 三者必须完全一致

3. **Schema 版本**
   - 始终使用最新版本
   - 当前：`2025-12-11`
   - 查看更新：[CHANGELOG](https://github.com/modelcontextprotocol/registry/blob/main/docs/reference/server-json/CHANGELOG.md)

4. **mcp-publisher 版本**
   - 动态获取最新版本
   - 避免硬编码
   - v1.4.0 修复了 v1.0.0 的 bug

5. **版本同步**
   - package.json
   - package-lock.json
   - .mcp/server.json (两处)
   - 使用脚本自动化

6. **OIDC 认证**
   - 使用 `github-oidc` 而非 `--token`
   - 需要 `id-token: write` 权限
   - 仅在 GitHub Actions 环境可用

### 🔍 调试技巧

1. **本地测试 mcp-publisher**
   ```bash
   # 下载 mcp-publisher
   curl -L "https://github.com/modelcontextprotocol/registry/releases/download/v1.4.0/mcp-publisher_darwin_arm64.tar.gz" -o mcp-publisher.tar.gz
   tar xzf mcp-publisher.tar.gz
   chmod +x mcp-publisher
   
   # 验证配置（不实际发布）
   ./mcp-publisher --version
   ```

2. **检查 npm 包内容**
   ```bash
   npm view your-package@version mcpName
   ```

3. **验证 GitHub App Token**
   ```bash
   # 在 workflow 中添加
   - name: Debug
     run: |
       echo "Actor: ${{ github.actor }}"
       echo "Token actor: $(gh api user --jq .login)"
   ```

4. **查看 workflow logs**
   - 失败时仔细阅读错误信息
   - 每个版本都记录了具体错误原因

### 📚 参考资源

- [MCP Registry Documentation](https://registry.modelcontextprotocol.io/docs)
- [GitHub Apps Documentation](https://docs.github.com/en/apps)
- [semantic-release](https://semantic-release.gitbook.io/)
- [mcp-publisher CLI](https://github.com/modelcontextprotocol/registry)

### 🎯 版本发布历程

从 v0.2.6 到 v0.2.12，经历了 7 次迭代才成功：

- v0.2.6: server.json 找不到
- v0.2.7: 缺少 transport 字段
- v0.2.8: mcp-publisher bug
- v0.2.9: schema 过期
- v0.2.10: 权限大小写错误
- v0.2.11: npm 包 mcpName 大小写错误
- v0.2.12: ✅ **成功发布！**

每次失败都是一次学习机会，最终实现了完全自动化的发布流程。

---

## 结语

配置 MCP Registry 自动发布看似简单，实则充满细节。本文记录的每个问题都是实际遇到的，希望能帮助你少走弯路。

关键是要有耐心，每次失败都仔细阅读错误信息，逐步排查问题。最终，你会得到一个完全自动化、零维护成本的发布流程。

祝你的 MCP Server 发布顺利！🚀

---

**项目示例：** [awesome-copilot-mcp](https://github.com/RbBtSn0w/awesome-copilot-mcp)  
**MCP Registry：** [io.github.RbBtSn0w/awesome-copilot-mcp](https://registry.modelcontextprotocol.io/servers/io.github.RbBtSn0w/awesome-copilot-mcp)

