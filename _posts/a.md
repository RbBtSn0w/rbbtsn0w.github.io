# 使用现有 GitHub 项目 Issues 和 gh CLI 管理 LLM 对话的教程：最佳工作实践（针对项目内部集成）

基于您的澄清，您希望在现有 GitHub 项目（如名为 "key" 的仓库）中，直接利用其自带的 Issues 系统来管理 LLM（Large Language Model，如 Gemini 或 Claude）对话和内存问题，而不是创建一个独立的专用仓库。这种方法完全可行，因为 GitHub Issues 是项目原生的协作工具，可以无缝扩展到存储 LLM 会话历史、任务分解、进度跟踪和反射，从而解决 LLM 的上下文窗口限制（e.g., "内存腐烂" 或长对话信息丢失）。出发点正是从项目本身的 Issues 开始：任何与 "key" 项目相关的开发、bug 修复、特性规划或 LLM 辅助任务，都可以直接在该仓库的 Issues 中管理，形成闭环工作流。

这种方法的核心优势：
- **项目内聚**：所有内容保持在单一仓库中，避免分散管理。
- **版本控制与协作**：Issues 支持标签、里程碑、评论和历史记录，适合 LLM 的“外部大脑”角色。
- **自动化**：gh CLI 允许脚本化操作，LLM 可以读取/更新 Issues 作为提示上下文。
- **适用场景**：特别适合编码项目（如 "key"），LLM 生成的代码、分析或反思直接链接到项目文件/PR。

然而，需要注意：如果项目 Issues 已很繁杂，建议使用专用标签（如 "llm-task"）来过滤 LLM 相关内容，以防混淆。以下是重新整理的完整教程，基于行业实践（如 LangGraph 的代理工作流和 Anthropic 的 Claude Code 集成），并调整为在现有项目（如 "key"）中操作。

## 先决条件和设置
1. **现有 GitHub 项目**：假设您的仓库是 "username/key"（替换为实际路径）。确保您有写权限，且仓库已启用 Issues（默认启用）。
2. **安装 gh CLI**：从 [cli.github.com](https://cli.github.com) 下载并安装 GitHub CLI。登录：`gh auth login`。在项目目录中运行命令时，gh 会自动识别当前仓库。
3. **LLM 工具**：使用支持 GitHub 集成的 LLM，如 Gemini CLI、`claude-code` 或 VS Code 的 Copilot。这些工具可以读取仓库 Issues（通过本地克隆或 API）。
4. **本地项目克隆**：在本地克隆仓库：`git clone https://github.com/username/key.git`，并进入目录：`cd key`。所有 gh 命令将在此运行。
5. **可选脚本环境**：使用 Bash 或 Python 脚本自动化（e.g., 一个简单的 shell 脚本封装 gh 命令）。如果 LLM 支持文件读取，确保仓库已拉取最新 Issues。

## 基本工作流步骤
流程从 LLM 对话开始，到在项目 Issues 中存储/更新，再到闭环。所有操作都在 "key" 仓库的 Issues 中进行。

1. **启动 LLM 会话并记录初始任务**：
   - 在项目目录中启动 LLM（e.g., `gemini` 或在 VS Code 中用 Copilot Chat）。
   - 描述项目相关任务，例如：“在 'key' 项目中，分析 src/main.py 的 bug 并提出修复方案。”
   - 将对话日志保存为临时 Markdown 文件（e.g., `session-log.md`），包括用户提示、LLM 响应、代码片段和初始反思。避免直接修改项目文件，直到确认。

2. **在项目 Issues 中创建新 Issue**：
   - 使用 gh CLI 创建 Issue，将日志作为主体，并关联项目上下文：
     ```
     gh issue create --title "LLM-Assisted Bug Fix in src/main.py" --body-file session-log.md --label "llm-task,bug" --assignee "@me" --project "Key Development Board"
     ```
     - `--label "llm-task"`：专用标签，用于过滤 LLM 相关 Issues。
     - `--project`：如果仓库有 GitHub Projects 看板，可关联以可视化任务流。
   - 这会生成一个 Issue ID（e.g., #123），后续所有更新都引用此 ID。Issue 主体可包含代码 diff、文件引用（e.g., `@src/main.py`）或甚至嵌入 LLM 生成的伪代码。

3. **更新 Issue 以跟踪进度和追加 LLM 输出**：
   - LLM 生成新输出（e.g., 修复代码或进一步分析）后，追加到 Issue 评论中：
     ```
     gh issue comment #123 --body "LLM 更新：修复方案包括以下代码变更：[diff 或代码块]。测试结果：..."
     ```
   - 如果涉及文件修改，LLM 可以生成 patch 文件（e.g., `fix.patch`），然后在 Issue 中附件上传或描述：`gh issue edit #123 --add-attachment fix.patch`。
   - 使用里程碑（milestones）分组：e.g., "Sprint 1 - LLM Enhancements"，将多个 LLM 任务关联。
   - 定期让 LLM “反思”：在提示中注入 Issue 历史，生成总结评论，如 “基于先前讨论，优化点包括...”。

4. **LLM 读取项目 Issue 作为上下文**：
   - 导出 Issue 内容为 JSON 或 Markdown，用于注入 LLM 提示：
     ```
     gh issue view #123 --json title,body,comments > issue-context.json
     ```
   - 在下次 LLM 会话中，使用此文件：“基于 'key' 项目 Issue #123 的历史（[注入内容]），继续优化方案。”
   - 如果 LLM 支持 GitHub API（e.g., Claude Code），可直接让 LLM 查询仓库 Issues，避免手动导出。

5. **关闭 Issue 并进行最终反思与集成**：
   - 任务完成后，关闭 Issue 并链接到 PR 或 commit：
     ```
     gh issue close #123 --comment "Resolved via PR #456. LLM 关键学习：使用外部 Issue 内存避免上下文丢失。关联文件：src/main.py。"
     ```
   - 如果 LLM 生成代码已应用，创建 PR：`gh pr create --title "LLM-Fix for Issue #123" --body "From LLM session..."`。
   - 提取通用规则保存到仓库的专用文件（如 `docs/llm-memory-bank.md`），或新建一个 “meta” Issue（如 #1: "LLM Workflow Guidelines"）来积累经验。

## 最佳实践
在现有项目中集成时，重点是保持 Issues 的整洁性和项目相关性。以下表格总结关键实践，基于 Gemini 和 Anthropic 专家的观点（如上下文分层和代理验证）：

| 实践类别          | 描述与技巧                                                                 | 益处与示例 |
|--------------------|----------------------------------------------------------------------------|------------|
| **标签与过滤**    | 使用专用标签如 "llm-task"、"memory"、"in-progress" 来标记 LLM Issues。查询：`gh issue list --label "llm-task"`。 | 避免混杂项目核心 Issues，便于搜索和 LLM 注入。 |
| **内存分层**      | 三层结构：短期（当前 LLM 会话）、工作内存（Issue 线程）、长期（仓库 docs/llm-rules.md 中的提取规则）。定期总结 Issue 以压缩上下文。 | 减少 token 消耗，防止 LLM “忘记”。如 CAMEL 框架的总结实践。 |
| **自动化脚本**    | 创建简单脚本 e.g., `llm-issue-update.sh`：接受日志文件，自动创建/更新 Issue 并注入到 LLM。集成 git hooks 在 commit 时更新 Issue。 | 加速迭代，适合并行任务。在 "key" 中测试脚本。 |
| **验证与迭代**    | 每次更新前，让 LLM 验证 Issue 内容（e.g., “检查代码一致性”）。使用仓库文件作为锚点（e.g., 引用 README）。 | 减少 hallucination，确保输出项目相关。 |
| **集成项目工具**  | 结合 git worktree（如果项目支持）：在 Issue 中记录分支，LLM 在隔离 worktree 中生成代码，然后 merge。链接到 PR/commits。 | 无缝开发流，如在 "key" 中并行 LLM 任务。 |
| **隐私与规模**    | 只存储非敏感 LLM 输出；如果 Issues 过多，使用 GitHub Projects 看板分组。限制每个 Issue 的评论数（<50）。 | 保持仓库高效，适用于中大型项目。 |
| **监控与调试**    | 使用 `gh issue list --json` 导出数据，分析 LLM 任务效率。跟踪 token 使用（via LLM 日志）。 | 优化工作流，调试如权限问题。 |

- **避免常见坑**：不要将整个仓库 dump 到 LLM 提示（使用 Issue 过滤）；如果 Issue 历史太长，创建子 Issue（如 #123.1）。确保 gh CLI 有权限（e.g., repo scope）。
- **扩展到多任务**：对于 "key" 中的多个 LLM 任务，使用里程碑或 Projects 板来可视化，如一个列为 “LLM Backlog”、另一个为 “In Review”。

## 示例： 在 "key" 项目中修复 bug 的工作流
1. LLM 会话：在 "key" 目录中，提示 “分析 src/key.py 的 bug”，输出保存到 `bug-log.md`。
2. 创建 Issue：`gh issue create --title "LLM Bug Fix in key.py" --body-file bug-log.md --label "llm-task"」。
3. 更新：LLM 生成修复，追加：`gh issue comment #10 --body "LLM 修复代码：[代码块]。"`。
4. 审阅与关闭：验证后，`gh pr create --issue #10`，然后 `gh issue close #10 --comment "Merged. 学习：Issue 作为内存桥接。"`。
5. 复用：在新任务中，提示 “从 'key' Issue #10 学习，继续...”。

## Gemini 和 Anthropic 专家观点整合
- **Gemini 视角**：适合 Gemini CLI 的文件注入，将项目 Issue 作为提示桥接多会话，避免上下文腐烂。推荐标签过滤以保持项目焦点。
- **Anthropic 视角**：Claude 视项目 Issues 为代理“检查列表”，自动生成更新以验证输出。强调在现有 repo 中积累反射，形成可靠的“生成+验证”循环。

这个工作流直接从您的出发点开始，确保一切嵌入 "key" 项目。如果项目规模大，可考虑子仓库，但当前设置已完整。如果需要脚本示例或具体调整，提供更多 "key" 项目细节！