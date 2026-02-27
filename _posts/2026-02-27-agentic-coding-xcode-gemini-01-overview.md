---
layout: post
title: "Agentic Coding 在 Xcode 落地指南（上）：从概念到可运行环境"
date: 2026-02-27
categories: [AI, Xcode]
tags: [agentic-coding,xcode,mcp,gemini-cli,developer-workflow]
description: "基于 Xcode 26.3 与 Gemini CLI 的实战路线图：你将从 0 到 1 完成环境准备、MCP 连接与首个可执行会话。"
---

## 写在前面

这是一套三篇连载的第 1 篇，灵感来自 Peter Friese 的文章（文末附链接），但内容会结合我自己的实践方式重写为中文落地版本，重点是：**你今天就能在本机跑起来**。

系列导航：

- 第 1 篇（本文）：从概念到环境准备
- [第 2 篇：从提示词到可运行 Demo（Newton’s Apple）](/posts/agentic-coding-xcode-gemini-02-hands-on/)
- [第 3 篇：常见坑、兼容性与团队落地清单](/posts/agentic-coding-xcode-gemini-03-troubleshooting/)

## 为什么现在要关注 Agentic Coding？

Xcode 26.3 把“AI 辅助写代码”从聊天升级为“可执行代理（Agent）协作”：

- 不只是给建议，还能配合工程上下文做修改
- 能触发构建、根据错误继续迭代修复
- 通过 MCP（Model Context Protocol）打通外部 Agent 与 Xcode 能力

简单说，以前是“你写、AI 看”，现在更像“你定目标、Agent 跑流程”。

## 先决条件（别跳过）

要复现这套流程，建议满足以下版本：

1. `Xcode 26.3`
2. `Gemini CLI >= 0.27.3`

为什么 Gemini 版本不能太低？

- 在 Xcode 26.3 早期桥接返回里，`structuredContent` 兼容性有过问题。
- Gemini CLI 后续补丁已经处理了这类响应（修复链路见文末参考）。

安装 Gemini CLI：

```bash
npm install -g @google/gemini-cli
gemini --version
```

## 在 Xcode 中打开 MCP 入口

路径（macOS）：

1. 打开 Xcode
2. `Xcode > Settings...`（快捷键 `⌘,`）
3. 进入 `Intelligence`
4. 在 `Model Context Protocol` 区域开启 `Xcode Tools`

这一步非常关键：不开启的话，后面的 CLI 就算配置正确，也看不到 Xcode 的工具能力。

## 把 Gemini CLI 连接到 Xcode MCP Bridge

进入你的项目根目录执行：

```bash
gemini mcp add xcode-tools xcrun mcpbridge
```

这会在项目内生成（或更新）配置文件：

- `.gemini/settings.json`

推荐“按项目配置”，不要全局开：

- 只在需要 Xcode 能力的仓库里启用
- 避免每次开 CLI 都弹授权确认
- 多项目切换时更干净，权限边界更清晰

## 启动一次最小可行会话

按这个顺序：

1. 先打开 Xcode 工程
2. 再在项目根目录执行 `gemini`
3. 接受 Xcode 的外部工具授权弹窗

在 CLI 内可以先看 MCP 是否正常：

```text
/mcp list
/mcp desc
```

如果你能看到 `xcode-tools` 及其工具描述，说明链路已经打通。

## 你应该形成的心智模型

这条链路本质是：

$$
\text{Gemini CLI} \xleftrightarrow[]{MCP\ via\ xcrun\ mcpbridge} \text{Xcode Tools}
$$

其中：

- Gemini 负责理解目标、规划步骤
- Xcode 提供工程级动作能力（构建、上下文、诊断）
- 你负责最终判断与验收（Human in the loop）

## 本篇小结

你现在已经完成了三件最重要的事情：

- 确认了版本前置条件
- 在 Xcode 中启用了 MCP 能力
- 用 Gemini CLI 成功连通并验证工具可见

下一篇我们直接进入实战：用一条高质量目标提示词，让 Agent 协作生成一个“可玩”的 SwiftUI + SpriteKit 小项目，并讲清楚如何让它自己修编译错误。

## 参考资料

- Peter Friese: Agentic Coding in Xcode with Gemini CLI  
  https://peterfriese.dev/blog/2026/agentic-coding-xcode-geminicli/
- Apple: Xcode 26.3 unlocks the power of agentic coding  
  https://www.apple.com/newsroom/2026/02/xcode-26-point-3-unlocks-the-power-of-agentic-coding/
- Apple Docs: Setting up coding intelligence  
  https://developer.apple.com/documentation/Xcode/setting-up-coding-intelligence
- Apple Docs: Giving external agentic coding tools access to Xcode  
  https://developer.apple.com/documentation/xcode/giving-agentic-coding-tools-access-to-xcode
- Gemini CLI release `v0.27.3`  
  https://github.com/google-gemini/gemini-cli/releases/tag/v0.27.3
