---
layout: post
title: "Parallel 不等于 Multi-Agent：Spec Kit 与 Superpowers 的并行模型"
date: 2026-07-03 00:00:00 +0800
categories: [AI, Tools]
tags: [spec-kit, superpowers, multi-agent, parallel, agentic-development]
description: "Spec Kit 的 [P] 是否会自动启动 multi-agent？本文拆解 Spec Kit 与 Superpowers 的并行模型，比较静态任务标记、运行时并发与 subagent review gate，并说明两套工作流融合时的控制权、状态映射与失败隔离挑战。"
image:
  path: /assets/img/post/speckit-super/cover.jpg
  alt: "Spec Kit 任务依赖图中的 [P] 候选通过运行时门禁后，由 controller 调度多个 agent 的并行模型"
---

> **TL;DR**：Spec Kit 和 Superpowers 是两套彼此独立的开发工作流。Spec Kit 用 `[P]` 描述任务图中的静态可并行性；Superpowers 根据运行时问题域决定是否并发派发 agent，同时用串行 review gate 管理多 agent 实现。理解各自的设计之后才能讨论融合，而融合的难点不是调用某个 skill，而是统一任务语义、控制权、状态与失败模型。

在 Agentic Development 中，`parallel`、`multi-agent` 和 `subagent` 经常出现在同一段讨论里。它们看起来都在描述“让多个执行者同时工作”，实际却可能代表完全不同的设计。

Spec Kit 是一套围绕 specification、plan 和 task artifact 展开的 Spec-Driven Development 工作流。Superpowers 是一组通过 skill 约束 agent 行为的工程方法。两者都谈到 parallel，但它们没有天然依赖关系，也没有共享协议。

如果你还不熟悉 Spec Kit 从 specification 到 task artifact 的完整路径，可以先参考 [GitHub Spec Kit 实战指南](/posts/sdd-series-part-2-spec-kit/)；本文只聚焦其中的 parallel 语义。

因此，本文不会一开始就把它们拼成一条流水线。我们先分别回答两个问题：

1. Spec Kit 为什么需要 `[P]`，它从哪里产生，又如何被消费？
2. Superpowers 为什么需要多个 agent，哪些流程真正并发，哪些流程刻意串行？

在两套模型都建立之后，再比较它们的差异，并讨论如果要融合，会遇到什么问题。

本文的 Spec Kit 部分已按官方 `v0.12.4` command templates 核验，Superpowers 部分基于本地安装的 `6.1.0` skill 定义。相关行为于 2026-07-03 核验；两套项目仍在演进，文末链接应结合具体版本阅读。

## 第一部分：Spec Kit 如何理解 Parallel

### Spec Kit 解决什么问题

Spec Kit 的核心不是多 agent 调度，而是把自然语言需求逐步收敛为可以执行和验证的工程 artifact。典型流程是：

```text
specify
  -> clarify
  -> plan
  -> tasks
  -> analyze
  -> implement
  -> converge
```

每个阶段都会产生或检查持久化文件，例如 `spec.md`、`plan.md` 和 `tasks.md`。这些 artifact 让需求、设计、任务和实现之间形成可追踪关系。

在这个模型里，执行单元是 task，控制结构是 task dependency graph。Spec Kit 首先关心的是：

- 需求是否被计划覆盖；
- 计划是否被任务覆盖；
- 任务是否有明确文件范围和完成条件；
- 实现是否按依赖顺序推进；
- 最终代码是否重新收敛到 spec。

Parallel 只是 task graph 的一个属性，不是整个系统的中心。

### `[P]` 是如何产生的

`speckit-tasks` 在生成 `tasks.md` 时，会判断任务是否可以标记为 `[P]`。当前定义要求：任务修改不同文件，并且不依赖尚未完成的任务。

```text
- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py
- [ ] T012 [P] [US1] Create User model in src/models/user.py
```

这些示例表达了三类信息：

- `T005` 是稳定的任务标识；
- `[P]` 是可选的并行提示；
- `[US1]` 表示任务所属的 user story。

`[P]` 来自计划阶段能够观察到的静态事实：文件范围和显式依赖没有冲突。它表达的是：

```text
This task is currently parallelizable.
```

它并不表达：

```text
Spawn one agent for this task now.
```

### `[P]` 如何被消费

`speckit-implement` 会解析 task ID、描述、文件路径、依赖关系和 `[P]` marker。它的执行规则包括：

- 顺序任务按依赖次序执行；
- `[P]` 任务可以一起执行；
- 修改相同文件的任务仍应串行；
- 非并行任务失败时停止后续执行；
- 并行任务失败时，可以保留其他成功任务并报告失败项。

这里的关键字是 *can*，不是 *must*。

Spec Kit 没有把 `[P]` 绑定到某一种运行时。单 agent 可以依次完成两个 `[P]` task；支持并发的执行器也可以同时处理它们。两种方式都符合 task artifact 的语义。

因此：

```text
[P] = may run in parallel
[P] != must use multi-agent
```

### Spec Kit 没有定义什么

Spec Kit 的 task model 不负责完整定义：

- 并发 agent 数量；
- agent 模型和角色选择；
- subagent 上下文如何隔离；
- 多个 agent 是否共享工作区；
- 运行时资源如何加锁；
- 并发变更如何合并；
- reviewer 是否与 implementer 分离。

这不是遗漏，而是边界。Spec Kit 提供的是可移植的任务描述。具体执行器可以是人、单 agent、多 agent，甚至外部任务系统。

从 Spec Kit 自身来看，parallel 的完整生命周期是：

```text
plan/task decomposition
  -> infer static independence
  -> write [P] into tasks.md
  -> implement parses [P]
  -> executor chooses a legal schedule
  -> update task completion state
```

它是一套以 artifact 为中心的静态调度提示。

## 第二部分：Superpowers 如何理解 Parallel

### Superpowers 解决什么问题

Superpowers 不是另一套 `spec.md -> tasks.md` 文件协议。它通过一组 skills 规定 agent 在不同工程场景中应该如何思考和行动，例如：

- 开始实现前先 brainstorming；
- 修复故障时遵循 systematic debugging；
- 编写计划时拆分可验证任务；
- 实现时使用 TDD；
- 完成前执行 verification；
- 在合适场景下使用 subagent 与 code review。

它的主要控制对象不是 task artifact，而是 agent behavior。Skill 会告诉 controller 何时选择某种工作方式、如何构造 subagent prompt，以及如何检查返回结果。

这意味着 Superpowers 中的 parallel 首先是运行时策略，而不是写入任务文件的静态 marker。

关于这些 skills 如何接入 Spec Kit 的实际工作流，可对照 [Superpowers Bridge 与 Spec Kit 实战](/posts/superpowers-bridge-spec-kit/)；下文会进一步解释这种连接为什么需要明确的控制边界。

### `dispatching-parallel-agents`：真正的并发流程

Superpowers 中直接定义并发的是 `dispatching-parallel-agents`。它面向多个彼此独立的问题域，典型场景是不同测试文件、不同子系统或不同根因的故障可以同时调查。

它的决策过程是：

```text
存在多个问题？
  -> 问题是否彼此独立？
     -> 否：由单个 agent 统一调查
     -> 是：是否没有共享状态或顺序依赖？
        -> 否：使用顺序 agent
        -> 是：并发派发 agent
```

这里的独立性是运行时判断，至少包括：

- 每个问题能够在不等待其他结果的情况下理解；
- 一个修复不会改变另一个问题的根因；
- agent 不会修改同一批文件；
- agent 不会争用同一数据库、模拟器、端口或构建目录；
- 返回结果可以由 controller 独立审查和集成。

确认独立后，controller 为每个问题构造 focused、self-contained 的任务，并在同一次调度中派发多个 agent：

```text
Agent A -> Investigate authentication failures
Agent B -> Investigate batch completion failures
Agent C -> Investigate abort handling failures
```

Superpowers 对“同时”有明确要求：多个 dispatch 在同一次响应中发出才构成并发；逐个派发并等待返回仍然是串行。

### 并发派发之后还有什么

Parallel dispatch 并不在 agent 返回时结束。Controller 还要：

1. 阅读每个 agent 的调查结论和改动摘要；
2. 检查文件冲突与语义冲突；
3. 确认各自的局部验证证据；
4. 在组合状态上运行完整测试；
5. 决定哪些结果可以集成，哪些需要重新处理。

因此，Superpowers 的 parallel 模型包含完整的 fan-out / fan-in：

```text
identify independent domains
  -> construct isolated contexts
  -> dispatch concurrently
  -> wait and collect
  -> review conflicts
  -> verify integrated result
```

并发减少的是调查或执行的 wall-clock time，不会消除 integration cost。

### `subagent-driven-development`：Multi-Agent，但不并发实现

`subagent-driven-development` 是最容易被名称误导的流程。

它会为每个任务派发 fresh implementer，再派发 task reviewer；所有任务完成后，还会执行 whole-branch review。它确实是 multi-agent workflow，但实现任务严格串行：

```text
Task 1 implementer
  -> self-review and tests
  -> Task 1 reviewer
  -> fix and re-review when needed
  -> mark Task 1 complete
  -> Task 2 implementer
  -> Task 2 reviewer
  -> ...
  -> whole-branch review
```

该 skill 明确禁止同时派发多个 implementation subagent，因为它们可能修改同一工作区并产生冲突。

这里使用多个 agent 的目的不是并发吞吐量，而是：

- 为每个任务提供 fresh context；
- 隔离 implementer 与 reviewer 的职责；
- 防止长会话中的上下文污染；
- 让每个任务经过 spec compliance 和 code quality gate；
- 在进入下一任务前关闭当前风险。

更准确的心智模型是：

```text
multi-agent sequential pipeline
```

而不是：

```text
parallel implementation
```

Fresh context 只能隔离单个任务的认知负担，不能自动解决跨任务状态丢失；[SDD 中的 Agent 上下文腐化与压缩丢失治理](/posts/sdd-memorylint-context-rot/)讨论了这一类持久化问题。

### `executing-plans`：单执行者的计划消费

当运行环境不支持 subagent，或者选择 inline execution 时，`executing-plans` 由当前 agent 读取计划、逐项执行并逐项验证。

Superpowers 文档中还会用 `parallel session` 描述把计划交给另一个独立会话执行。这里的 parallel 是“执行会话与原规划会话分离”，不表示一份计划中的多个任务会并发运行。

因此，Superpowers 内至少存在三种不同语境：

```text
Parallel agents  -> 多个独立问题域同时运行
Parallel session -> 执行发生在独立于规划过程的会话
Parallel-safe    -> 通过隔离和门禁避免 agent 互相干扰
```

Superpowers 的 multi-agent 与 parallel 是两个正交维度。

## 第三部分：两套设计有什么不同

到这里，Spec Kit 与 Superpowers 才适合放进同一张表。

| 维度 | Spec Kit | Superpowers |
| --- | --- | --- |
| 主要目标 | 将需求收敛为可追踪、可执行的 artifact | 约束 agent 使用可靠工程方法完成工作 |
| 核心对象 | spec、plan、task、dependency | skill、controller、subagent、review gate |
| Parallel 的性质 | 静态任务属性 | 运行时行为决策 |
| 并行单元 | task | independent problem domain |
| 并行信号 | `tasks.md` 中的 `[P]` | controller 对独立性和共享状态的判断 |
| Multi-agent 要求 | 不要求 | 部分 skill 要求 |
| 并发要求 | `[P]` 允许但不强制 | parallel dispatch 明确并发 |
| 状态来源 | 持久化 artifact | 当前会话、报告与 progress ledger |
| 失败语义 | 根据顺序/并行任务决定停止或继续 | 收集子结果、审查、修复与重新验证 |
| Review 模型 | analyze/converge 检查 artifact 与实现 | implementer/reviewer 分工和 review loop |

最根本的区别是判断发生的时间不同。

Spec Kit 在生成计划时判断“从目前可见的依赖看，任务是否可并行”。Superpowers 在执行现场判断“这些问题现在是否可以由不同 agent 安全地同时处理”。

前者接近 scheduler hint，后者接近 orchestration policy。

两者分别独立使用都成立：

- 只使用 Spec Kit，可以让单 agent 或人工团队按照 `tasks.md` 执行；
- 只使用 Superpowers，可以从任意计划或故障集合中识别独立问题并派发 agent；
- 不需要安装另一套系统，任何一方都能完成自身工作流。

这也是为什么不应把 `[P]`、subagent 和 parallel dispatch 当作同一个协议的不同阶段。

## 第四部分：如果要融合，会发生什么

融合是一种可选架构，不是两套系统的默认关系。

一种看似自然的想法是：让执行器读取 Spec Kit `tasks.md`，把 `[P]` task 交给 Superpowers 的 multi-agent 能力。概念上的链路可能是：

```text
Spec Kit tasks.md
  -> extract tasks, dependencies, file scopes and [P]
  -> orchestration adapter evaluates runtime independence
  -> choose sequential, subagent-driven or parallel dispatch
  -> collect and verify results
  -> update Spec Kit task state
```

这条链路可以实现，但中间需要一个真正的 orchestration adapter。简单地把 `[P]` 映射为 `spawn_agent` 并不足够。

### 挑战一：并行单元的语义不同

Spec Kit 的并行单元是 task，Superpowers parallel dispatch 的并行单元是 independent problem domain。

一个 `[P]` task 可能很小，只值得当前 agent 顺手完成；多个 `[P]` task 也可能共享隐藏的运行时资源。反过来，一个没有 `[P]` 的 debugging task，内部可能包含三个完全独立的故障域，适合并发调查。

融合层必须完成语义转换，而不是只做格式转换。

### 挑战二：静态独立不等于运行时独立

两个任务修改不同文件，不代表它们可以同时运行。它们可能共享：

- 数据库和 fixture；
- Xcode simulator 或 DerivedData；
- 服务端口和临时目录；
- code generation 输出；
- package manager lockfile；
- 尚未稳定的接口决策。

因此 `[P]` 只能作为候选信号。融合层仍需检查 shared state、write set 和 execution environment。

### 挑战三：谁拥有调度控制权

Spec Kit implement 阶段已经有顺序、失败和完成状态规则；Superpowers skill 也会决定何时 dispatch、review、fix 和 stop。

如果两边都充当 controller，就会出现：

- 谁决定下一个任务；
- 谁决定失败后停止还是继续；
- 谁向用户请求决策；
- 谁负责重试；
- 谁宣布任务完成。

融合必须指定唯一 controller。另一方只能提供 artifact 或 capability，不能同时维护第二套控制流。

### 挑战四：完成状态有两个来源

Spec Kit 通过 `tasks.md` 的 `[ ]` / `[X]` 保存状态。Superpowers 的 subagent workflow 可能通过报告、todo 和 progress ledger 跟踪进度。

如果 implementer 已经提交代码，但 reviewer 尚未通过，这个 task 在 Spec Kit 中是否算完成？如果 `[X]` 已写入，但 whole-branch review 发现回归，是否要回滚状态？

合理的状态映射至少需要区分：

```text
dispatched
implemented
locally_verified
review_approved
integrated
completed
```

如果不想引入复杂状态机，就应规定只有最终 gate 通过后才能写入 `[X]`，中间状态只留在执行器内部。

### 挑战五：失败语义不一致

Spec Kit 允许某个 `[P]` task 失败时继续保留其他成功结果。Superpowers 则要求 controller 在 agent 返回后检查冲突并验证整体结果。

这会产生几个实际问题：

- 成功 task 是否可以在失败 task 修复前标记完成；
- 失败是否破坏其他 agent 的前提；
- 局部测试通过但集成测试失败时，责任归属哪个 task；
- 是否重新派发原 agent，还是由新的 fix agent 接手。

融合层需要定义 failure isolation，而不是把每个 agent 的 `DONE` 直接当成全局成功。

### 挑战六：并发修改与工作区隔离

Superpowers 的 `subagent-driven-development` 明确禁止多个 implementation subagent 并发修改，正是因为共享工作区容易发生冲突。

如果融合设计希望真正并发实现 `[P]` task，就必须额外解决：

- 每个 agent 是否使用独立 worktree；
- 分支、commit 和 merge 由谁管理；
- 生成文件和 lockfile 如何协调；
- 合并冲突由哪个 agent 处理；
- 集成测试在哪个组合状态运行。

这些能力不属于 `[P]` 的语义，也不能靠 prompt 保证。

### 挑战七：Review gate 如何组合

Spec Kit 的 analyze/converge 关注 spec、plan、tasks 与实现之间的一致性。Superpowers 的 task reviewer 关注当前任务的 spec compliance 与 code quality。

两种 review 的观察范围不同：

```text
Superpowers task review -> 这个任务是否正确完成？
Spec Kit converge       -> 整个 feature 是否仍与 artifact 收敛？
```

融合时不能简单删除其中一个，也不应在每个 task 后运行完整 converge。更合理的层次是任务级 review 作为局部门禁，feature 级 converge 作为最终门禁。

### 挑战八：能力检测与用户选择

`[P]` 存在不代表宿主支持 multi-agent。即使支持，用户也可能更重视成本、可预测性或工作区安全，而选择串行执行。

融合层需要区分：

```text
task is parallelizable
runtime supports multi-agent
policy allows concurrent execution
current resources are safe to share
```

只有四项都成立，任务才应真正并发。用户可以选择总体策略，但不应被迫为每个 `[P]` task 重复回答同一个问题。

### 挑战九：上游版本会持续漂移

Spec Kit 与 Superpowers 都会独立演进。一个依赖内部 skill 文本、命令名或状态细节的桥接层，很容易在任一上游升级后失效。

融合设计应依赖最小稳定契约，例如 task ID、dependency、file scope、completion state 和明确的 capability detection。其余行为应通过适配与测试验证，而不是复制整套上游 workflow。

## 一个更稳健的融合原则

如果确实需要连接两套系统，可以采用以下边界：

```text
Spec Kit owns:
  requirements, artifacts, task graph, completion state

Superpowers owns:
  execution discipline, runtime independence checks,
  subagent prompts, review loops, verification behavior

Adapter owns:
  capability detection, mode selection, state mapping,
  failure propagation, integration policy
```

对应的决策规则可以保持简单：

| 条件 | 执行策略 |
| --- | --- |
| 无 `[P]` 或存在显式依赖 | 顺序执行 |
| 有 `[P]`，但运行时资源不独立 | 顺序执行 |
| 有 `[P]`，环境支持 subagent，但不允许并发修改 | 使用串行 subagent workflow |
| 有 `[P]`，问题域和工作区均可隔离 | 可以并发 dispatch |
| 只做独立调查，不修改共享代码 | 优先并发 |
| 无 multi-agent 能力 | 单 agent 合法降级执行 |

最重要的原则是：融合层增强关键执行节点，不复制任一上游的完整工作流。

## 结语

Spec Kit 与 Superpowers 都使用 parallel 这个词，但它们从不同问题出发。

Spec Kit 关心任务图：哪些 task 从静态依赖上允许同时推进。Superpowers 关心 agent 行为：哪些问题域在当前运行环境中值得并发，怎样隔离上下文，又怎样回收和审查结果。

分别理解时，两套设计都很清楚。只有提前假设它们存在依赖关系，概念才会混在一起。

如果选择融合，真正需要设计的不是“看到 `[P]` 就调用哪个 skill”，而是夹在两套系统之间的控制协议：谁做决定、谁维护状态、失败如何传播、并发如何隔离，以及最终由谁证明整个 feature 已经完成。

最后可以用三个不等式概括：

```text
[P] != multi-agent
multi-agent != parallel
parallelizable != parallelized
```

先理解各自的边界，再讨论连接方式。否则，多 agent 只会把原本清晰的两个系统，组合成一个拥有两套 controller 的复杂系统。

## References

- [Spec Kit: `speckit-tasks`](https://github.com/github/spec-kit/blob/main/templates/commands/tasks.md){:target="_blank" rel="noopener"}
- [Spec Kit: `speckit-implement`](https://github.com/github/spec-kit/blob/main/templates/commands/implement.md){:target="_blank" rel="noopener"}
- [Superpowers: `dispatching-parallel-agents`](https://github.com/obra/superpowers/tree/main/skills/dispatching-parallel-agents){:target="_blank" rel="noopener"}
- [Superpowers: `subagent-driven-development`](https://github.com/obra/superpowers/tree/main/skills/subagent-driven-development){:target="_blank" rel="noopener"}
- [Superpowers: `executing-plans`](https://github.com/obra/superpowers/tree/main/skills/executing-plans){:target="_blank" rel="noopener"}
