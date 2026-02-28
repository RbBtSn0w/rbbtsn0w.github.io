---
layout: post
title: "Agentic Coding 在 Xcode 落地指南（下）：排障清单、兼容性与团队协作"
date: 2026-02-27
categories: [AI, Project, Xcode]
tags: [agentic-coding,mcp,gemini-cli,debugging,team-workflow]
description: "从个人尝鲜到团队可复用：整理 Xcode + Gemini CLI 在 MCP 接入中的高频问题、版本策略与协作规范。"
---

## 为什么你需要一份“排障手册”

Agentic Coding 最容易翻车的地方，不是 Prompt，而是“环境与边界条件”：

- 工具版本不匹配
- MCP 响应格式差异
- 权限配置不一致
- 团队成员使用习惯不同

这篇的目标很明确：让你从“偶尔可用”升级到“稳定复现”。

![Agentic Coding 排障指南](/assets/img/post/agentic-coding-03/ide_troubleshooting.png)

系列导航：

- [第 1 篇：从概念到可运行环境](/posts/agentic-coding-xcode-gemini-01-overview/)
- [第 2 篇：一条 Prompt 做出可玩的 iOS Demo](/posts/agentic-coding-xcode-gemini-02-hands-on/)
- 第 3 篇（本文）：排障清单、兼容性与团队协作

## 高频问题 1：明明连上了，但工具调用异常

### 症状

- `/mcp list` 能看到工具
- 但执行工具后结果异常，或结构化字段缺失

### 根因

Xcode 26.3 早期桥接响应里，存在 `content` 文本化 JSON 与 `structuredContent` 期望不一致问题。

![JSON 数据结构异常修复](/assets/img/post/agentic-coding-03/json_bug_fix.png)

### 处理

确保 Gemini CLI 版本至少是包含该兼容修复的版本（`>= 0.27.3` 更稳妥）。

```bash
gemini --version
npm install -g @google/gemini-cli@latest
```

参考修复链路：Issue `#18371` 与 PR `#18376`（文末链接）。

## 高频问题 2：每次都弹权限确认，体验很割裂

### 建议

按项目启用 MCP 配置，不要在全局长期打开。

你可以给每个仓库保留独立的 `.gemini/settings.json`，这样：

- 只有当前工程会请求 Xcode 授权
- 减少无关项目噪音
- 权限审计更容易

## 高频问题 3：Agent 修改范围失控

### 建议做法：三段式约束

在任务描述里写清：

1. **允许修改的目录/文件**
2. **禁止触碰的区域**（例如项目配置、签名、CI 文件）
3. **每轮必须先构建再继续**

示例：

```text
仅允许修改 Sources/UI 与 Sources/Scene。
不要修改工程签名、Targets 配置和 CI 文件。
每轮改动后都执行构建检查，失败先修复再做下一步。
```

## 高频问题 4：团队里“每个人都能跑，但结果不一致”

这是最常见的协作问题。建议统一下面四项：

![团队协作与规则统一](/assets/img/post/agentic-coding-03/team_collaboration.png)

### 1) 版本基线

- Xcode 版本基线（例如 26.3）
- Gemini CLI 最低版本（例如 >= 0.27.3）

### 2) 会话规范

- 使用统一的任务模板（目标/约束/验收）
- 每个任务附“成功标准”

### 3) 代码审查规则

- Agent 生成代码也走同样 PR 流程
- 拒绝“没构建就提交”的改动

### 4) 回滚策略

- 开启 Git 仓库
- 小步提交，按功能分支隔离

## 推荐的团队任务模板（可直接复用）

```text
[目标]
实现 XXX 功能，优先保证可构建与可运行。

[约束]
- 只修改 A/B/C 目录
- 不修改工程配置、签名与 CI
- 优先复用现有组件与命名规范

[执行策略]
1. 先给出最小实现
2. 构建并修复错误
3. 补齐测试或验证步骤
4. 输出变更摘要与风险点

[验收标准]
- 编译通过
- 关键交互可复现
- 无新增 warning（或说明原因）
```

## 从“能用”到“好用”的关键指标

你可以用这 3 个指标衡量 Agentic Coding 质量：

- **首轮通过率**：第一次生成后可编译通过的比例
- **修复闭环时长**：从报错到通过构建的平均时间
- **可审查性**：PR 是否清晰展示了改动意图与边界

如果这三项都在改善，说明你不是“在玩新玩具”，而是在提升工程效率。

## 系列收官总结

这三篇的核心其实只有一句话：

> Agentic Coding 的上限，不取决于模型有多聪明，而取决于你的工程化约束有多清晰。

你可以把它看成一位新同事：

- 给明确目标，它会跑得很快
- 给模糊要求，它会跑偏得更快（这句含金量很高）


## 参考资料

- Peter Friese: Agentic Coding in Xcode with Gemini CLI  
  https://peterfriese.dev/blog/2026/agentic-coding-xcode-geminicli/
- Apple Docs: Giving external agentic coding tools access to Xcode  
  https://developer.apple.com/documentation/xcode/giving-agentic-coding-tools-access-to-xcode
- Apple Docs: Writing code with intelligence in Xcode  
  https://developer.apple.com/documentation/xcode/writing-code-with-intelligence-in-xcode
- Gemini CLI Issue #18371  
  https://github.com/google-gemini/gemini-cli/issues/18371
- Gemini CLI PR #18376  
  https://github.com/google-gemini/gemini-cli/pull/18376
