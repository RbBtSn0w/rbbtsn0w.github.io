---
layout: post
title: "从文本到交互：如何将你的 MCP Server 升级为 MCP App"
date: 2026-01-27 16:40:00 +0800
categories: [AI, Project]
tags: [mcp, mcp-apps, agentic-ui, javascript]
description: "Model Context Protocol (MCP) 迎来首个官方扩展：MCP Apps。本文将带你了解如何通过简单的步骤，为你现有的 MCP 工具添加交互式 UI。"
---

随着 Model Context Protocol (MCP) 的快速发展，我们已经习惯了让 AI 通过工具调用来读取文件、查询数据库或执行脚本。然而，这种交互通常局限于“文本输入 -> 文本输出”的循环。

2026 年 1 月 26 日，MCP 官方宣布了首个扩展协议：**MCP Apps**。它彻底打破了文本的边界，让工具可以直接返回**交互式 UI 组件**。本文将带你快速上手，看看如何将你现有的 MCP Server 升级为具备 UI 能力的 MCP App。

## 为什么需要 MCP Apps？

想象一下你正在使用一个销售分析工具：
- **过去**：模型返回几百行销售数据，然后你得继续追问：“帮我按区域排序”，“只看上周的记录”。
- **现在 (MCP Apps)**：工具直接弹出一个交互式看板，你可以自己点击筛选、缩放图表。模型依然在后台监听你的操作，随时准备提供更深度的分析。

这就是 **Agentic UI** 的力量。

## 核心概念

MCP Apps 的实现依赖于两个关键原语：
1. **带有 UI 元数据的工具 (Tools with UI metadata)**：工具声明中包含一个 `_meta.ui.resourceUri` 字段。
2. **UI 资源 (UI Resources)**：通过 `ui://` 协议提供的静态资源（HTML/JS 捆绑包）。

## 实战：三步升级你的 MCP Server

假设你已有一个普通的 MCP Server，下面是升级步骤：

### 第一步：在工具定义中声明 UI

你需要修改你的工具注册代码，告诉宿主客户端（如 Claude 或 ChatGPT）这个工具关联了哪一个 UI 界面。

```javascript
// 修改前的工具定义
{
  name: "get_server_status",
  description: "获取服务器运行状态",
  inputSchema: { /* ... */ }
}

// 修改后的工具定义
{
  name: "get_server_status",
  description: "获取服务器运行状态，并显示交互式监控面板",
  inputSchema: { /* ... */ },
  _meta: {
    ui: {
      resourceUri: "ui://dashboard/status"
    }
  }
}
```

### 第二步：编写 UI 组件逻辑

在你的 UI 前端代码中，安装并使用官方提供的 SDK：`@modelcontextprotocol/ext-apps`。

```bash
npm install @modelcontextprotocol/ext-apps
```

然后在你的 JS 代码中建立连接：

```javascript
import { App } from "@modelcontextprotocol/ext-apps";

const app = new App();

async function init() {
  await app.connect();

  // 1. 接收来自宿主的消息（如工具调用的原始结果）
  app.ontoolresult = (result) => {
    updateDashboard(result.data);
  };

  // 2. 从 UI 中主动调用 Server 工具
  const details = await app.callServerTool({
    name: "fetch_more_logs",
    arguments: { level: "error" }
  });

  // 3. 更新模型上下文，让 AI 知道用户在 UI 里干了什么
  await app.updateModelContext({
    content: [{ type: "text", text: "用户点击了节点 A，正在查看详细错误报告" }]
  });
}

init();
```

### 第三步：提供 UI 静态资源

你的 MCP Server 现在需要实现 `resources/read` 接口，以便客户端可以通过 `ui://dashboard/status` 获取对应的 HTML 文件。通常建议将 HTML 和 JS 预先打包好。

```javascript
server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  if (request.params.uri === "ui://dashboard/status") {
    return {
      contents: [{
        uri: request.params.uri,
        mimeType: "text/html",
        text: "<html>... 这里是你的 App 代码 ...</html>"
      }]
    };
  }
  // ... 其他资源处理
});
```

## 安全与隔离

MCP Apps 运行在**沙箱化的 iframe** 中，这意味着：
- **权限受限**：App 无法直接访问用户的本地文件或敏感信息。
- **显式授权**：UI 发起的每一次工具调用都可以被宿主设置为“需用户确认”。
- **可审计**：UI 与宿主之间的所有通信（JSON-RPC）都是可记录的。

## 总结

MCP Apps 的出现标志着 AI Agent 正在从“对话框里的机器人”演变为“具备操作界面的智能助手”。通过引入 UI 协议，我们不仅提高了数据探索的效率，也为更复杂的业务流（如 3D 可视化、流程审批、地图交互）打开了大门。

如果你已经开发了 MCP Server，不妨现在就尝试引入 `ext-apps` SDK，给你的用户带来更直观的操作体验！

---

### 参考资源

- [MCP Apps 官方指南](https://modelcontextprotocol.io/docs/extensions/apps)
- [SDK 仓库: @modelcontextprotocol/ext-apps](https://github.com/modelcontextprotocol/ext-apps)
- [交互式地图示例 (Map Server)](https://github.com/modelcontextprotocol/ext-apps/tree/main/examples/map-server)
