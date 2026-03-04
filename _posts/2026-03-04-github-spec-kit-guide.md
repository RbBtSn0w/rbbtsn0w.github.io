---
title: GitHub Spec Kit 详细使用指南
date: 2026-03-04 12:15:00 +0800
categories: [Architecture, AI]
tags: [sdd, ai, spec_kit]
---

# GitHub Spec Kit 详细使用指南
## Spec-Driven Development · AI 编程工程方法
适用工具：Claude Code · GitHub Copilot · Gemini CLI · Cursor
2025 年版  ·  基于 github/spec-kit 官方文档整理

## 1. 什么是 Spec Kit？
GitHub Spec Kit 是 GitHub 于 2025 年 9 月开源的规范驱动开发（Spec-Driven Development, SDD）工具包，目前在 GitHub 上已获得超过 5 万颗 Star。它不是一个代码生成框架，而是一套结构化的提示词模板 + CLI 脚手架，让 AI 编程助手按照固定流程工作，而不是一次性"乱生成"。

### 1.1 核心理念
传统开发把代码当作"唯一真相来源"（Source of Truth），导致规范漂移（Spec Drift）——文档写完就扔，代码和意图逐渐背离。
Spec Kit 的逻辑逆转了这一点：规范是唯一真相，代码是规范编译出来的产物。当规范变了，重新让 AI 生成代码即可，而不是反向去读代码猜意图。

💡 核心比喻
把 .md 文件想象成给 AI 的"施工图"。传统开发是先盖房子再画图，SDD 是先画好图再施工——改图纸比改房子容易得多。

### 1.2 Spec Kit 适合哪些场景？
| 适用场景 | 原因 |
|---|---|
| 绿地项目（Greenfield） | 从零开始，防止 AI 走向通用解而不是你想要的解。规范确保从第一行代码起就方向正确。 |
| 遗留系统现代化 | 原始意图已随时间消失。通过 Spec Kit 重新捕获业务逻辑，设计新架构，让 AI 重建而不携带历史技术债。 |
| 复杂功能迭代 | 需求变更时，只更新 spec，重新执行 plan → tasks → implement，而不是逐行修改代码。 |
| 团队协作项目 | Constitution 保证全团队的 AI 产出风格一致，新成员读完文档就能上手。 |

### 1.3 Spec Kit 不适合的场景
- 紧急 Hotfix：修一个明确的 bug，不需要走完整 SDD 流程。直接改代码，在 changelog 里留痕即可。
- 探索性原型：完全不确定要做什么，规范无法写出来。先 Vibe Coding 探索，有了方向再补 Spec。
- 单文件小脚本：投入产出比不划算。SDD 的价值在中大型功能和长期维护的项目中才能体现。

## 2. 安装与初始化

### 2.1 前置依赖
| 依赖项 | 说明 |
|---|---|
| Python / uv | Spec Kit CLI 基于 Python uv 包管理器。推荐先安装 uv（Astral 出品的高速包管理器）。 |
| Git | 必须。Spec Kit 通过 git branch 名称自动识别当前 feature 目录。 |
| AI 编程助手 | Claude Code、GitHub Copilot、Gemini CLI、Cursor 等均支持。安装前需确认已安装对应工具。 |
| Node.js（可选） | 如果你的项目使用 npm 相关工具链，Spec Kit 在 implement 阶段会调用本地 CLI。 |

### 2.2 安装 uv 包管理器
uv 是 Spec Kit CLI 的运行基础，需要先安装：
macOS / Linux：
`curl -LsSf https://astral.sh/uv/install.sh | sh`
Windows（PowerShell）：
`powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"`

### 2.3 安装 Spec Kit CLI（推荐持久化安装）
```bash
# 持久化安装（推荐，之后可直接使用 specify 命令）
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# 验证安装
specify --version
```

⚡ 一次性使用（无需安装）
如果你只想试用，不想持久安装，可以使用 uvx 直接运行。每次都会拉取最新版：
`uvx --from git+https://github.com/github/spec-kit.git specify init my-project --ai claude`

### 2.4 初始化项目
在你的项目目录下执行初始化命令，选择你使用的 AI 助手：

```bash
# 新建项目（在当前目录创建 my-project 文件夹）
specify init my-project --ai claude

# 在已有项目的当前目录初始化
specify init . --ai claude

# 或使用 --here 标志
specify init --here --ai claude

# 其他 AI 助手选项
specify init my-project --ai copilot    # GitHub Copilot
specify init my-project --ai gemini     # Gemini CLI
specify init my-project --ai cursor     # Cursor
specify init my-project --ai windsurf   # Windsurf
```

### 2.5 初始化后的目录结构
```text
my-project/
├── .claude/                  # AI 命令文件（以 Claude 为例）
│   └── commands/
│       ├── speckit.constitution.md
│       ├── speckit.specify.md
│       ├── speckit.plan.md
│       ├── speckit.tasks.md
│       ├── speckit.implement.md
│       ├── speckit.clarify.md
│       └── speckit.analyze.md
├── .specify/
│   ├── memory/
│   │   ├── constitution.md   # 项目宪法（核心文件）
│   │   └── constitution_update_checklist.md
│   ├── templates/            # 各类 Spec 模板
│   │   ├── spec-template.md
│   │   ├── plan-template.md
│   │   └── tasks-template.md
│   └── scripts/              # 自动化脚本（bash 或 powershell）
└── specs/                    # 你的 feature spec 文件（自动创建）
```

📌 重要说明
`specify init` 只需运行一次。斜杠命令（`/speckit.*`）被永久安装在项目的 agent 文件夹中。AI 助手直接读取这些命令文件，无需重复运行 `specify`。

## 3. 核心工作流：六步完整闭环

Spec Kit 的工作流是线性推进的，每一步都有清晰的产出文件。整个流程的核心原则是：不通过当前阶段的验证，不进入下一阶段。

| 步骤 | 命令 | 产出文件 | 核心目的 |
|---|---|---|---|
| 0（一次性） | `/speckit.constitution` | `constitution.md` | 定义项目不可违反的原则 |
| 1 | `/speckit.specify` | `specs/xxx/spec.md` | 描述功能的 What & Why |
| （可选） | `/speckit.clarify` | 更新 `spec.md` | 让 AI 澄清模糊点 |
| 2 | `/speckit.plan` | `specs/xxx/plan.md` | 技术实施方案与架构决策 |
| （可选） | `/speckit.analyze` | 分析报告 | 跨文件一致性检查 |
| 3 | `/speckit.tasks` | `specs/xxx/tasks.md` | 原子化任务列表 + 依赖关系 |
| 4 | `/speckit.implement` | 源代码 | 按 tasks.md 逐步实现 |

### Step 0. `/speckit.constitution` — 建立项目宪法
一次性执行，为所有后续开发定义不可违反的原则
宪法（`constitution.md`）是项目的"基本法"。AI 在所有后续命令中都会参考这份文件，确保产出物始终符合你的技术标准和约束。

命令格式：
`/speckit.constitution <你的描述>`

```bash
# 示例 1：简单约束
/speckit.constitution 这是一个静态网站，无外部服务依赖，所有内容文件必须是 Markdown，数据文件必须是 JSON。

# 示例 2：团队规范
/speckit.constitution 这是一个 Java 17 后端项目。禁止使用 Lombok，所有金额字段必须使用 BigDecimal，
单元测试必须使用 JUnit 5 且覆盖空指针异常，REST API 响应必须统一使用 ResultWrapper 封装。

# 示例 3：前端项目
/speckit.constitution 项目使用 React + TypeScript + Vite + Tailwind CSS。
优先使用函数式组件和 Hooks，禁止 class 组件。状态管理使用 Zustand，不引入 Redux。
API 调用统一使用 React Query，不允许在组件内直接 fetch。
```

宪法通常包含以下内容：
- 技术栈强制项：必须使用哪些框架、库，禁止使用什么
- 代码质量标准：测试覆盖率要求、Lint 规则、代码风格
- 架构原则：模块化要求、分层规范、命名约定
- 安全与合规：敏感数据处理规则、日志规范、权限设计
- 性能要求：P95 响应时间、并发处理策略等

⚠️ 注意
宪法原则一旦建立应视为不可违反。如果确实需要修改，应通过正式的 Amendment（修订）流程，在 `constitution.md` 中记录修改原因和日期，而不是直接改掉。

### Step 1. `/speckit.specify` — 写功能规范
描述你要构建什么以及为什么，不涉及技术实现细节
这一步的关键原则：只说"做什么"和"为什么"，不说"怎么做"。技术细节留给 `/speckit.plan`。
AI 会根据你的描述，结合 `constitution.md` 中的约束，自动生成结构化的 `spec.md`，包含用户故事、验收标准（AC）、边界条件等。

`/speckit.specify <你的需求描述>`

```bash
# 示例 1：电商功能
/speckit.specify 为用户积分系统新增每日签到功能。用户每天可以签到一次获得积分。
要求幂等处理（同一天重复签到不重复发放积分），返回结果包含当次获得积分和累计总积分。
签到结果需支持审计追踪。性能要求 P95 < 200ms。

# 示例 2：照片管理 App
/speckit.specify 构建一个照片组织应用。照片按日期分组到相册，相册可以通过拖拽重新排序。
相册不支持嵌套。每个相册内的照片以瓦片（tile）形式展示预览。

# 示例 3：内容管理
/speckit.specify 为 Halo 博客系统新增 SystemConfig 分组列表 API，
只返回配置项的 group name，不返回配置值。需要包含分页支持和单元测试。
```

生成的 `spec.md` 通常包含：
- 用户故事（User Stories）
- 功能需求（Functional Requirements）
- 验收标准（Acceptance Criteria，每条均可测试验证）
- 范围说明（In Scope / Out of Scope）
- 约束与边界条件（含性能、安全、兼容性要求）
- 成功指标（Success Metrics）

💡 最佳实践
生成 `spec.md` 后，一定要人工 Review 并 Sign-off。重点检查：验收标准是否可测试？是否覆盖了重复请求/幂别情况？边界条件有没有遗漏？这是整个流程质量最关键的一关。

### （可选） `/speckit.clarify` — 澄清模糊需求
让 AI 主动提问，解决 spec 中的不确定性
当 spec 存在模糊点或需要进一步澄清时，使用这个命令。AI 会分析 `spec.md` 中的歧义，向你提问，并根据你的回答更新 spec 文档。

```bash
# 触发澄清流程
/speckit.clarify

# - 时区以服务端还是用户本地时间为准？
```

### Step 2. `/speckit.plan` — 技术实施方案
给出技术方向，AI 生成详细架构规划
这一步你告诉 AI 技术选型方向（tech stack、架构偏好），AI 结合 `constitution.md` 和 `spec.md` 生成完整的 `plan.md`，包含：
- 技术架构选型及理由
- 数据模型设计（Schema、字段、索引）
- 接口契约（Request / Response / Error Codes）
- 核心流程伪代码（含幂等、并发、事务边界）
- 安全要求（鉴权、输入校验、审计字段）
- 回滚与兼容性策略

`/speckit.plan <技术方向描述>`

```bash
# 示例 1：后端 API
/speckit.plan 使用 Java 17 + Spring Boot 3。幂等通过数据库唯一约束实现，
不使用 Redis 计数器（减少依赖复杂度）。服务层处理业务逻辑，Controller 层只做参数校验。

# 示例 2：前端应用
/speckit.plan 使用 Vite + 最少数量的依赖库。不引入状态管理框架，使用原生 React Hooks。

# 示例 3：全栈
/speckit.plan 前端使用 React + TypeScript，后端使用 Go + 标准库 http server，
本地存储使用 SQLite，不引入外部数据库服务。
```

⚠️ 重要提示
收到 `plan.md` 后，检查是否存在过度设计（over-engineering）。如果 AI 引入了不必要的复杂性，直接提问："这里有没有更简单的实现方式？" 或 "这个组件是否可以省略？" 让 AI 简化方案后再进入下一步。

### （可选） `/speckit.analyze` — 一致性检查
在 implement 前，检查所有文档是否互相一致
这是进入实施前的最后一道防线。`/speckit.analyze` 会扫描 `constitution.md`、`spec.md`、`plan.md`，检查是否存在：
- 需求冲突（同一功能在不同文档中有不同描述）
- 覆盖缺口（spec 中有但 plan 中未覆盖的需求）
- 宪法违反（plan 中的技术选型违反了 constitution 的约束）
- 重复定义（同一需求被多次定义且措辞不同）

`/speckit.analyze`

💡 建议
对于复杂功能（超过 3 个用户故事或涉及多个系统组件），强烈建议在 implement 前跑一次 analyze。发现冲突比在代码里改问题便宜得多。

### Step 3. `/speckit.tasks` — 任务拆解
将 `plan.md` 拆解为原子化、有序的任务列表
这一步把架构方案转化为 AI 可以逐步执行的任务列表，写入 `tasks.md`。任务按用户故事分组，带有明确的依赖关系。

`/speckit.tasks`

生成的 `tasks.md` 典型结构：

```markdown
### User Story 1: 用户每日签到

#### Phase 1: Foundation
- [ ] Task 1.1: 创建 checkin_record 表（含 user_id + date 唯一约束）
- [ ] Task 1.2: 生成 CheckinRecord 实体类和 Repository

#### Phase 2: Core Logic [P]  ← [P] 表示可并行执行
- [ ] Task 2.1: 实现 PointsService.checkIn() 幂等逻辑
- [ ] Task 2.2: 实现积分发放和 ledger 写入

#### Phase 3: API Layer
- [ ] Task 3.1: 实现 CheckInController，对齐 spec 接口契约
- [ ] Task 3.2: 补充单元测试（首次签到、重复签到、非法日期）
- [ ] Task 3.3 [P]: 生成 API 文档
```

`tasks.md` 的核心价值：
- `[P]` 标记：明确哪些任务可以并行执行，优化工作流
- 依赖顺序：确保 model 先于 service，service 先于 controller
- 可替换性：任务描述足够详细，换一个 AI 模型也能 100% 正确执行

### Step 4. `/speckit.implement` — 执行实现
AI 按 `tasks.md` 逐步构建功能，你来测试和验收
这是最后一步，也是时间最长的一步。AI 会按 `tasks.md` 中的顺序逐个执行任务，生成源代码。

`/speckit.implement`

⚠️ 关键提醒
AI 在 implement 阶段会执行本地 CLI 命令（如 npm install、dotnet build、go build 等）。请确保你的机器上已安装项目所需的工具链。implement 完成后，务必在浏览器中手动测试，CLI 日志无法捕获前端运行时错误。

implement 完成后的最佳实践：
- 启动应用，手动测试主流程
- 如有运行时错误，直接把错误信息粘贴给 AI 修复（不需要回到 spec 修改）
- 对于幂等性、并发等无法手动测试的场景，确认测试用例已被 tasks 覆盖
- 代码通过验收后，提交到 feature 分支并创建 PR

## 4. 核心文件详解

### 4.1 constitution.md — 项目宪法
保存路径：`.specify/memory/constitution.md`
这是 Spec Kit 中唯一在整个项目生命周期内有效的文件。宪法的核心属性是不可违反性（Immutability）——AI 在生成 spec、plan、tasks 时都会主动检查并遵守宪法的约束。

| 属性 | 说明 |
|---|---|
| 设计目的 | 对齐整个团队（和所有 AI session）的基础假设，防止每次对话重新"协商"规则 |
| 更新频率 | 极低——只在技术栈重大升级或架构原则改变时更新 |
| 更新方式 | 追加 Amendment（修订条目），记录修改原因和日期，不直接覆盖原有内容 |
| 典型内容 | 技术栈要求、代码规范、测试标准、安全原则、命名约定 |

### 4.2 spec.md — 功能规范
保存路径：`specs/<feature-name>/spec.md`
每个 feature 一份独立的 `spec.md`，对应一个 git branch。这是功能的"意图合约"，回答"我们要构建什么？用户能感知到的行为是什么？"

| 模块 | 内容说明 |
|---|---|
| User Stories | As a [角色] I want [功能] so that [价值]。每个用户故事对应 tasks.md 中的一个实施阶段。 |
| Acceptance Criteria | 每条 AC 必须可测试验证。格式：Given [前提] When [操作] Then [期望结果] |
| In/Out of Scope | 明确"不做什么"，防止范围蔓延（Scope Creep） |
| Constraints | 性能要求、安全约束、兼容性要求、灰度发布策略 |
| Success Metrics | 如何衡量功能是否成功？（可选但推荐） |

### 4.3 plan.md — 技术实施方案
保存路径：`specs/<feature-name>/plan.md`
`plan.md` 是从"做什么"到"怎么做"的桥梁，回答"技术上如何实现？有哪些取舍？"它需要足够详细，让 AI 在生成 tasks 时不需要猜测。

| 模块 | 内容说明 |
|---|---|
| 技术架构 | 选型说明 + Pros/Cons，记录"为什么选这个、为什么不选那个" |
| 数据模型 | 表结构 / Schema 定义、字段类型、索引、迁移策略 |
| 接口契约 | Request/Response 结构、Error Codes、幂等要求、版本策略 |
| 核心流程 | 伪代码描述，包含事务边界、并发处理、异常映射 |
| 安全要求 | 鉴权方式、输入校验规则、审计字段、数据脱敏 |
| 回滚策略 | 如何回滚？影响范围？回滚后的数据状态？ |

### 4.4 tasks.md — 任务列表
保存路径：`specs/<feature-name>/tasks.md`
`tasks.md` 是 AI 的"施工清单"。每个任务是一个原子操作，完成后有明确的验收状态（✅ 或 ❌）。

| 属性 | 说明 |
|---|---|
| 任务粒度 | 每个任务对应一个文件或一个方法级别的变更，不超过 100 行代码 |
| 依赖顺序 | 任务按执行顺序排列，依赖关系通过编号体现（Task 2.1 依赖 Task 1.x） |
| [P] 标记 | 可以并行执行的任务，团队多人开发时特别有用 |
| 状态跟踪 | 每个任务有 `[ ]` 待完成 / `[x]` 已完成 状态，AI 会在执行时更新 |

## 5. 实战技巧与常见问题

### 5.1 Constitution 写作技巧
好的 Constitution 应该：
- 可操作性："禁止使用 Lombok" ✅  vs  "代码要简洁" ❌
- 有边界：只写 AI 必须遵守的原则，不写显而易见的常识
- 分层清晰：技术约束、质量标准、架构原则三类分开写

实战常见 Constitution 条目：

#### 技术约束
- 语言版本：Java 17，不使用 preview 特性
- 禁止：Lombok（影响调试）、Double 用于金额（精度问题）
- 金额字段：数据库 DECIMAL(19,4)，Java BigDecimal

#### 代码质量
- 所有 public 方法必须有 Javadoc
- 单元测试覆盖率 >= 80%，必须覆盖空指针和边界条件
- 列表查询 API 必须默认包含分页参数

#### 架构原则
- 业务逻辑在 Service 层，Controller 只做参数校验
- 异常统一由 GlobalExceptionHandler 处理，禁止在 Controller 中 try-catch
- 所有接口响应统一使用 `ApiResponse<T>` 封装

### 5.2 Spec 写作技巧
验收标准（AC）是 Spec 最关键的部分，必须可测试：

#### ❌ 不好的 AC（无法测试）
- 系统性能要好
- 用户体验流畅

#### ✅ 好的 AC（可测试）
- AC1: 同一用户同一天只能签到一次，重复请求返回 ALREADY_CHECKED_IN 错误码，积分不重复发放
- AC2: 接口 P95 响应时间 < 200ms（基于现有积分查询能力）
- AC3: 签到成功时返回：是否签到、签到时间、当次积分、总积分四个字段
- AC4: 非法日期格式返回 INVALID_DATE 错误码，含详细错误信息

### 5.3 遗留项目冷启动
对于没有历史文档的遗留项目，不要试图一次性补全所有文档。从下一个真实需求开始增量建立：
- 先建立 Constitution：基于现有代码库，让 AI 分析并生成项目宪法草稿，你来修正
- 从下一个变更开始：选一个真实的 feature 或 bugfix，走完整 SDD 流程
- 每次 PR 时归档：合并代码时强制更新 `AI_CHANGELOG.md`（为什么这么改），并补充测试用例
- 文档自然生长：不把文档整理单独立项，让贴随每次迭代自然积累

💡 实战建议
遗留项目第一次使用 Spec Kit 时，可以让 AI "读取现有代码库，生成 03_implementation.md 骨架"。这比从零写更快，也更准确。然后在迭代中逐步补充和修正。

### 5.4 Bug Fix 怎么处理？
Bug fix 不必走完整 SDD 流程，但需要判断 bug 的性质：

| Bug 类型 | 处理方式 |
|---|---|
| 执行层错误（代码写错了） | 直接让 AI 生成补丁。在 `AI_CHANGELOG.md` 中记录 bug 描述和修复方式。 |
| 设计层错误（Spec 没写对） | 必须先修改 `spec.md` 或 `plan.md`，再让 AI 重新生成对应代码。先文档后代码。 |
| 反复出现的同类 bug | 在 `constitution.md` 中新增规则，防止下次重现。这是 SDD 最有价值的"复利效应"。 |

### 5.5 升级 Spec Kit

```bash
# 第 1 步：备份你定制的 constitution
cp .specify/memory/constitution.md .specify/memory/constitution-backup.md

# 第 2 步：升级 CLI
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git

# 第 3 步：更新项目文件（会覆盖 .claude/ 等 agent 文件夹）
specify init --here --force --ai claude

# 第 4 步：恢复你的 constitution
mv .specify/memory/constitution-backup.md .specify/memory/constitution.md

# 注意：specs/ 目录永远不会被升级覆盖
```

📌 说明
`specs/` 目录（你的 feature spec 文件）在升级时被完全保护，不会被修改。只有 `.claude/`、`.specify/templates/` 等工具文件会被更新。

## 6. 团队协作最佳实践

### 6.1 分工建议
Spec Kit 最大的团队价值是：每个人的 AI 使用同一份 constitution，产出风格和质量标准一致，不再因人而异。

| 角色 | 职责 |
|---|---|
| PM / 产品 | 主导 `/speckit.specify`，确保 AC 可测试。Sign-off `spec.md` 是进入 plan 的前提。 |
| 后端 TL / 架构师 | 主导 `/speckit.plan`，负责技术选型决策。在 `plan.md` 中记录技术取舍理由。 |
| 开发 | 执行 `/speckit.tasks` 和 `/speckit.implement`，每个 task 完成后更新状态。 |
| QA | 基于 `spec.md` 的 AC 编写测试用例，使用 `/speckit.analyze` 做规范一致性验证。 |
| 新成员 | 读 `constitution.md` + 最近 3 个 feature 的 `spec.md`，即可了解项目规范和设计风格。 |

### 6.2 Git 工作流集成
推荐的分支策略：每个 feature 对应一个 git branch，branch 名即 feature 目录名（Spec Kit 自动识别）。

```bash
# 创建 feature branch（命名对应 spec 目录）
git checkout -b feature/001-user-checkin

# 完成后提交所有 spec 文件 + 代码，一起进入 PR
git add specs/ src/ tests/
git commit -m "feat: add daily check-in with spec artifacts"
```

PR Review 的新方式：Reviewer 先读 `spec.md` 理解意图，再用 `/speckit.analyze` 检查代码是否兑现了规范承诺，最后看 git diff 验证细节。

### 6.3 知识资产沉淀
除了 spec 文件，以下两类文件是团队最有价值的长期资产：

**`docs/decisions/AI_CHANGELOG.md` — 决策日志：**
```markdown
## 2026-01-15 feature-001-user-checkin
- Decision: 幂等通过数据库唯一约束（user_id + date）实现，而非 Redis 计数器
- Reason: 减少外部依赖，数据库作为最终一致性来源，简化事务处理
- Risk: 高并发写入压力需关注唯一约束的锁竞争，已验证 500 QPS 压测正常
- Related Spec: specs/feature/001-user-checkin/
```

**`docs/skills/SKILL.md` — 团队规则库（防止同类 bug 复现）：**
```markdown
### 规则 #01: 列表查询必须分页
所有返回列表的 API 接口，必须默认包含 page 和 pageSize 参数。
忘记加分页将导致大数据量下性能问题。

### 规则 #12: 时区处理
签到等与"今天"相关的业务，统一以服务端时区（UTC+8）为准，
不接受客户端传入的 date 参数作为最终依据。

### 规则 #23: BigDecimal 精度
所有涉及金额的字段：数据库 DECIMAL(19,4)，Java BigDecimal。
严禁使用 Double 或 Float，已有线上事故案例。
```

## 7. Spec Kit 的局限性与使用边界
作为实事求是的使用指南，以下是 Spec Kit 真实存在的局限，使用前需要有清醒的认知。

| 局限 | 说明 |
|---|---|
| Spec 质量依赖人的判断力 | Spec Kit 假设你能写出高质量的 Spec。如果 Spec 本身有缺陷（AC 不完整、边界遗漏），AI 只会更高效地执行一个有问题的规范。Spec Kit 是放大器，不是纠错器。 |
| 流程外变更产生漂移 | 紧急修复、实验代码、跨团队直接提交如果没有更新对应 spec，会产生 Spec Drift。文档和代码的信任关系需要团队纪律来维护，工具无法强制。 |
| 实现阶段仍可能有 bug | implement 完成并不代表功能正确。CLI 日志不能捕获运行时错误，必须手动测试。对复杂业务逻辑（并发、分布式一致性），AI 的覆盖能力有限。 |
| 有一定学习曲线 | 团队首次使用需要投入时间学习 SDD 思维和 Spec 写作。前两个 feature 会比不用 Spec Kit 更慢，从第三个 feature 开始才能体现效率优势。 |
| 对小改动投入产出比低 | 修一个明显的 typo 或 1 行代码的 hotfix，完整走 SDD 流程成本过高。建议对"复杂功能 + 长期维护"的模块使用，对明显的小修复直接改代码留痕即可。 |

📌 总结
Spec Kit 是目前 SDD 工具中规范化程度最高的开源方案，适合中大型项目和注重长期可维护性的团队。它解决了"AI 产出不可控、上下文不持久、团队协作割裂"等核心问题，但需要团队建立相应的工程文化才能充分发挥价值。

最佳使用方式：从一个真实的中型 feature 开始走完完整流程，感受 spec-driven 的闭环后，再逐步推广到团队。
