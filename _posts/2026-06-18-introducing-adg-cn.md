---
layout: post
title: "ADG 发布：将失控的 Agent Skills 纳入版本化管理体系"
date: 2026-06-18 20:00:00 +0800
categories: [Tools]
tags: [agent, cli, package-manager, adg]
description: "分散的 Agent Skills 难以管理。ADG (Agent Directory Group) 是一个统一 CLI 工具，引入了版本管理和锁文件机制，通过单一真相源彻底解决跨运行时的配置割裂问题。"
image:
  path: /assets/img/post/introducing-adg/cover.png
  alt: ADG 概念架构示意图
---

> **TL;DR**: 当你同时使用 Claude 和 Codex 时，分散的 Agent Skills 往往难以管理且无法复现。ADG (Agent Directory Group) 作为一个统一的 CLI，引入了类似 npm 的版本管理和锁文件机制。你只需维护一份清单，ADG 就会为你自动生成兼容不同运行时的配置文件，实现真正的“一次编写，随处运行”。

随着在不同 AI 助手（如 Claude 和 Codex）中使用的 Skills 和 Plugins 越来越多，你可能已经遇到了这两个痛点：**Skill 数量膨胀难以管理**，以及**不同运行时的插件规范互不兼容**。

ADG (Agent Directory Group) 正是为了解决这些混乱而诞生的。本文将直接介绍它的核心价值、设计理念以及如何快速上手。

## 我们面临的三个真实痛点

### 1. 技能爆炸 (Skill Explosion)
当前，大量的 Skill 文件通常是孤立存在的：没有版本控制、没有归属说明、也没有依赖关系管理。久而久之，它们会变成一堆难以维护的散乱脚本。ADG 将这些分散的文件组织为**有版本化、可被发现的 Plugin**，实现按逻辑分组管理，而非单纯的文件堆砌。

### 2. 运行时割裂 (Runtime Fragmentation)
不同的 AI 助手有着各自的标准：
- Claude 通过 `~/.claude/skills/<name>/` 加载，要求 Skill 名称具有命名空间。
- Codex 则直接将 `~/.agents/plugins/` 作为原生发现目录。

两套目录结构，两种清单格式。如果手动在两端同步，不仅耗费精力，还极易产生配置漂移。ADG 的解决方案是：**你只维护一份 `.agents/.plugin.json`**，而 `.claude-plugin/plugin.json` 和 `.codex-plugin/plugin.json` 都由 ADG **自动生成**。

### 3. 难以复现 (Reproducibility)
“我当前安装的到底是哪个版本？它的来源是哪里？内容被修改过吗？”
为了解答这些问题，ADG 引入了 `.plugin-lock.json`。它会为每一个安装的 Plugin 记录**来源 (Origin)、解析后的版本号 (Version) 以及 `sha256` 内容指纹**。你安装的不再是“大概某个版本的代码”，而是**经过严格校验的确定性资产**。

## 核心设计：控制面与导出的彻底分离

很多工具习惯将“自身的内部状态”与“提供给运行时的配置”混在一个文件中，导致两边的数据都不够可靠。ADG 最大的设计亮点在于将这两者**显式拆分**：

```text
 .agents/.plugin.json   ── 单一事实来源（你唯一需要手写的文件）
        │  适配 (Adapt)
        ├────────────► .claude-plugin/plugin.json   （自动生成，供 Claude 读取）
        └────────────► .codex-plugin/plugin.json     （自动生成，供 Codex 读取）

 .plugin-lock.json      ── 控制面 (Control Plane)：ADG 唯一信任的权威状态
                            (包含 provenance + sha256 + version + dependencies)
 marketplace.json       ── 导出 (Export)：按 Codex 事实标准生成的产物，ADG 不以此为准
```

- **Lock 文件是控制面，由 ADG 绝对掌控。** 任何控制流操作（如 `list`、`update`、`link`）、冲突检测和依赖解析，均以 lock 文件为准。如果尝试从**不同源**安装同名 Plugin，ADG 会将其视为冲突并直接拒绝。
- **Marketplace 是导出产物，形态由运行时决定。** 它严格按照 Codex 所消费的数据结构（包含 `{ name, source, policy, category }`）进行输出，ADG 永远将其视作**生成产物**。至于完整性、版本和来源信息——这些都会被妥善保存在 lock 文件中，不会在此暴露。

这条清晰的边界带来了直接的好处：**你所信任的内部状态（lock）与你需要兼容的外部生态（marketplace）互不污染。** 更改导出格式不会影响你的核心数据，切换运行时同样游刃有余。

## 60 秒极速上手

ADG 已在 npm 发布（使用 Scope 名称 **`@rbbtsn0w/adg`**）：

```bash
# 安装稳定版
npm install -g @rbbtsn0w/adg

# 或者体验预览版
npm install -g @rbbtsn0w/adg@beta

# 也可以直接通过 npx 运行：
npx @rbbtsn0w/adg --help
```

只需三步，即可将 Marketplace 中的工具纳入全局管理，并映射到你正在使用的运行时：

```bash
# 1) 将远端库添加至全局目录 (~/.agents/plugins)
adg plugins add anthropics/knowledge-work-plugins --ref main --global

# 如果仓库过于庞大，可以仅拉取需要的子目录：
adg plugins add anthropics/knowledge-work-plugins --ref main --sparse engineering --global

# 2) 映射至当前运行时
adg plugins link --target codex  --global     # 为 Codex 建立原生发现链接
adg plugins link --target claude --global     # 为 Claude 创建符号链接 (symlink)

# 3) 保持同步与更新
adg plugins update --global
adg plugins list --global
```

`adg` 是你唯一需要记忆的命令，全局安装后即可使用，无需任何额外的 Node 构建步骤。

## 几个让你安心的技术细节

这并不是简单的功能堆砌，而是为了打消你在使用前的顾虑：

- **它只管理 `plugins/` 子目录。** 无论在哪个作用域下，ADG 仅读写 `plugins/` 目录。同层级的 `~/.agents/AGENTS.md` 和 `~/.agents/skills/` 绝不会被意外篡改。
- **符号链接不会覆盖真实目录。** 当执行 `link --target claude` 时，ADG 只会替换已过期的符号链接；如果遇到的是真实文件夹，则会立即中止操作。
- **无缝接管已有的第三方 Plugin。** 在发现阶段，`add` 命令会扫描已有的 `.codex-plugin` 或 `.claude-plugin` 原生清单，将其**反向适配**为标准的 `.agents/.plugin.json`，实现平滑纳管——无需单独执行 `import`。
- **基于 SemVer 的依赖拓扑解析。** Plugin 间的依赖关系支持通过 `^`、`~`、精确版本或 `*` 进行比较与校验，并在安装时进行拓扑排序。遇到循环依赖、缺失或版本冲突时会快速失败（Fail Fast）。你也可以使用 `--no-deps` 参数仅安装指定目标。
- **合规的 Skills 来源。** 核心的 skills 域作为 vendored fork 引入自 [vercel-labs/skills](https://github.com/vercel-labs/skills) (MIT)。`adg skills <verb>` 会透传命令，并完整保留原始的许可证及第三方声明，确保来源可查且协议合规。

## 谁最适合使用 ADG？

- **多平台深度用户**：同时在 Claude 和 Codex 运行 Skills/Plugins，苦于手动在两侧保持同步的开发者。
- **注重基础设施的团队**：在 CI 环境、团队共享服务器或审计场景下，迫切需要**可复现安装**机制的人（这就是 lock 和 `sha256` 存在的原因）。
- **工具创作者**：希望将散落的全局 Skills **打包并分发**的作者。只需一条 `import-skills` 命令，即可将 `<name>/SKILL.md` 目录转化为规范的 Plugin。

**坦诚地说**：如果你只使用单一运行时，且手头的 Skill 数量屈指可数，那么 ADG 可能会显得过度工程。它的核心价值在于化解 **Skill 数量 × 运行时数量** 所带来的复杂性。

## 下一步

- **安装体验**：执行 `npm install -g @rbbtsn0w/adg`，然后运行 `adg --help`。
- **开发你的首个 Plugin**：参考项目仓库中的 `docs/authoring.md`。
- **深入了解目录规范**：阅读 `docs/agents-spec.md`。
- **探究背后的发布工程**：如果你好奇它是如何发布到 npm 的，可以阅读这篇硬核实录 [《新 npm 包的 main + beta 双通道发布》](/posts/npm-trusted-publishing-semantic-release/)。
- **探索 Agent 生态**：想了解更多关于 Agent 生态与工具链构建的最佳实践，请参考 [Mastering Antigravity Agents](/posts/mastering-antigravity-agents-cn/)。

单一事实来源，无缝桥接两大生态，实现全面可复现——这，就是 ADG。
