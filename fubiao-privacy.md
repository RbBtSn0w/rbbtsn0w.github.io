---
layout: page
title: Fubiao Privacy Policy
permalink: /fubiao/privacy/
---

Effective date: August 25, 2026

Fubiao is a local-first analytics connector for WeChat Official Accounts. This
policy explains how the macOS app and its bundled Safari Web Extension handle
data.

## Data storage and processing

Supported analytics responses captured from WeChat Official Accounts are sent
only from the bundled Safari Web Extension to Fubiao's loopback Companion
service on the same Mac. The service removes sensitive fields, validates and
normalizes the data, then stores analytics snapshots in a SQLite database inside
the app container on that Mac.

The App Group is used only for short-lived coordination between the containing
app and Safari extension. It is not the analytics database.

## Data we do not collect

Fubiao does not store WeChat cookies, AppIDs, AppSecrets, session credentials,
or browser query parameters. It does not transmit analytics snapshots to the
developer or to third parties. Fubiao does not use advertising tracking or
third-party analytics SDKs.

## Local MCP service

When enabled by the user, Fubiao provides a read-only Model Context Protocol
(MCP) endpoint bound only to `127.0.0.1`. MCP client credentials are stored
locally in the Data Protection Keychain. The app never writes another app's MCP
configuration automatically.

## Your controls

Safari connection and MCP access are opt-in. Disconnecting Safari stops the
local Companion service and revokes its browser bearer token. You can delete all
captured analytics data from Settings > Privacy & Data.

## Contact

For privacy questions, contact [support@rbbtsn0w.com](mailto:support@rbbtsn0w.com).

---

# 浮标隐私政策

生效日期：2026 年 8 月 25 日

浮标是一款面向微信公众号数据的本地优先连接器。本政策说明 macOS 应用及其内置 Safari Web Extension 如何处理数据。

## 数据存储与处理

Safari 扩展从微信公众号后台捕获的受支持分析响应，仅会发送到同一台 Mac 上浮标的回环 Companion 服务。服务会清理敏感字段、验证并归一化数据，然后将分析快照保存在该 Mac 的应用容器 SQLite 数据库中。

App Group 仅用于包含应用与 Safari 扩展之间的短期协调，不保存分析数据库。

## 我们不收集的数据

浮标不会存储微信 Cookie、AppID、AppSecret、会话凭证或浏览器查询参数；不会将分析快照传输给开发者或第三方；不使用广告跟踪或第三方分析 SDK。

## 本地 MCP 服务

在用户主动启用后，浮标会提供仅绑定到 `127.0.0.1` 的只读 Model Context Protocol（MCP）端点。MCP 客户端凭证仅保存在本机 Data Protection Keychain 中，应用不会自动写入其他应用的 MCP 配置。

## 用户控制

Safari 连接和 MCP 访问均需主动启用。断开 Safari 会停止本地 Companion 服务并撤销浏览器 Bearer Token。你可在“设置 > 隐私与数据”中删除全部已捕获的分析数据。

## 联系方式

如有隐私问题，请联系 [support@rbbtsn0w.com](mailto:support@rbbtsn0w.com)。
