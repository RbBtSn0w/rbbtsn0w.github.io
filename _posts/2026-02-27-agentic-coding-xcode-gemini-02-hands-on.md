---
layout: post
title: "Agentic Coding 在 Xcode 落地指南（中）：一条 Prompt 做出可玩的 iOS Demo"
date: 2026-02-27
categories: [AI, iOS, Xcode]
tags: [agentic-coding,swiftui,spritekit,gemini-cli,prompt-engineering]
description: "从 0 到 1 实战 Newton's Apple：用 Gemini CLI + Xcode MCP 生成可交互的 SwiftUI/SpriteKit 物理小项目，并让 Agent 自己修编译错误。"
math: true
---

> **TL;DR**: 掌握向 AI 下达精准研发指令的秘诀。作为落地的中篇，本文演示了如何用一段**目标+约束+验收标准**构成的结构化 Prompt，让 Gemini CLI 代理在 Xcode 内直接从零生成一个可互动的物理重力实验 App，并分享了如何引导 Agent 主动观察编译错误完成自我修复的“闭环”实操套路。


## 这篇你会得到什么

如果你已经完成上一篇的配置，这篇会带你跑通一条完整链路：

- 新建 iOS 工程
- 通过 Gemini CLI 下达目标型 Prompt
- 让 Agent 迭代生成代码并修复构建问题
- 在 Preview / Simulator 里验证交互

这篇核心不是“复制代码”，而是学会一套**可复用的协作套路**。

系列导航：

- [第 1 篇：从概念到可运行环境](/posts/agentic-coding-xcode-gemini-01-overview/)
- 第 2 篇（本文）：从提示词到可运行 Demo
- [第 3 篇：排障清单、兼容性与团队协作](/posts/agentic-coding-xcode-gemini-03-troubleshooting/)

## Step 1：先建一个空白 SwiftUI 工程

在 Xcode 中：

1. `File > New > Project...`
2. 选择 `iOS > App`
3. 输入项目名（例如 `NewtonsApple`）
4. 保存后先确保可编译运行

然后到项目根目录执行：

```bash
gemini mcp add xcode-tools xcrun mcpbridge
gemini
```

接受 Xcode 弹出的权限请求。

## Step 2：给 Agent 一个“可验证”的目标

建议使用下面这种“目标 + 约束 + 验收”结构，而不是一句“帮我做个动画”。

![Newton's Apple Demo Result](https://peterfriese.dev/_astro/newtons-apple.BNoUnKp9_Zm3pe1.webp)
_图：我们要构建的最终交互效果（来源：peterfriese.dev）_

可直接使用的提示词（中文改写版）：

```text
请将当前默认 SwiftUI 首页替换为 SpriteKit 场景并嵌入 SwiftUI。

目标：构建一个物理小实验。
1) 屏幕中央显示“Hello World”，并作为静态刚体。
2) 点按屏幕时，从顶部随机生成水果 emoji（🍎🍌🍇），让它们受重力下落并与文字碰撞。
3) 底部添加一个“Antigravity”按钮，按住时反转重力，松开后恢复。

约束：
- 代码拆分清晰，避免把所有逻辑塞进一个 View。
- 先保证编译通过，再优化细节。
- 每次改动后主动构建并修复报错，直到能运行。

验收标准：
- 能在 Preview 或 Simulator 中交互。
- 点按可连续生成 emoji。
- Antigravity 按住时可见明显反重力效果。
```

## Step 3：让 Agent 做“闭环”而不是“一次性生成”

你可以把会话驱动成下面节奏：

1. **先生成最小实现**
2. **立刻构建**（让 Agent 读取错误）
3. **按错误修复**（最多一次只修一类问题）
4. **再构建**
5. **最后微调体验**（碰撞参数、按钮反馈等）

这比“直接要最终完美版本”稳定得多。

## 我常用的追问模板

当它第一次生成后，不要立刻结束。继续追问：

```text
请先执行构建检查。
如果失败：列出前 3 个关键错误，按优先级逐个修复；
每修复一次就重新构建，直到通过。
```

然后再补体验层：

```text
现在做两件事：
1) 调整水果碰撞与反弹参数，让视觉更自然；
2) 给 Antigravity 按钮加按压态反馈（例如透明度或缩放）。
```

## 为什么这种方式有效？

因为我们把任务拆成了三个阶段：

$$
\text{Generate} \rightarrow \text{Build/Observe} \rightarrow \text{Fix/Refine}
$$

这会显著降低大模型一次性输出引入的“连锁错误”。

## 常见失败信号（以及你该怎么做）

### 1) 代码看起来很多，但一直编不过

做法：收敛范围。

```text
先暂停新增功能，只保留最小可运行版本。
仅修复当前编译错误，不做重构。
```

### 2) 效果能跑但交互怪异

做法：改成“可观测调参请求”。

```text
请把与物理参数相关的常量集中到一个结构体，并标注用途。
然后给出推荐参数范围与默认值。
```

### 3) Agent 改动太激进

做法：限制改动边界。

```text
只允许修改 Scene 层与按钮组件，不要改 App 入口和工程配置。
```

## 一条适合日常的“黄金法则”

把 Prompt 从“命令句”升级为“工程任务单”：

- 明确目标
- 明确约束
- 明确验收
- 明确迭代策略

这样 Agent 才会像“能执行的队友”，而不是“随机给答案的聊天机器人”。

## 本篇小结

到这里，你已经掌握了 Agentic Coding 最关键的实战动作：

- 用高质量目标描述启动任务
- 让 Agent 主动经历构建-修复闭环
- 通过边界约束减少无关改动

下一篇我们专门讲“坑”：版本兼容、授权弹窗、MCP 响应格式、以及团队在 CI/CD 和规范层面的落地建议。

## 参考资料

- Peter Friese 原文示例项目思路：  
  https://peterfriese.dev/blog/2026/agentic-coding-xcode-geminicli/
- Apple Docs（外部工具接入 Xcode）：  
  https://developer.apple.com/documentation/xcode/giving-agentic-coding-tools-access-to-xcode
- Apple Docs（Xcode 智能编码工作流）：  
  https://developer.apple.com/documentation/xcode/writing-code-with-intelligence-in-xcode
