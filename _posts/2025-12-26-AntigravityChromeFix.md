---
layout: post
title: "Antigravity 中 Chrome 启动失败修复指引"
date: 2025-12-26
categories: [AI, macOS]
tags: [antigravity, chrome, macos, automation, permissions]
description: "通过终端继承权限修复 Antigravity IDE 无法拉起 Chrome 的问题，附配置参考与排查脚本。深层解析 macOS 的安全机制与 TCC 策略阻挡。"
image:
  path: /assets/img/post/2025-12/antigravity_chrome_minimalist.png
  alt: "极简适量风格的 macOS 终端窗口与浏览器解锁，标志解决浏览器自动化授权问题"
---

> **TL;DR**: 当在 macOS 系统中使用 Antigravity IDE 触发浏览器自动化节点时，经常遇到无法拉起 Chrome 并显示 `Operation not permitted` 的权限错误。这往往是因为 macOS TCC（Transparency, Consent, and Control）机制拦截。解决方法非常直接：不要对 IDE 或 Chrome 本身疯狂改权，而是利用终端 (Terminal) 的已授权的高权限体系，使用绝对路径启动 IDE 可执行文件，借由权限继承解决所有沙箱穿透难题。


## 1. 问题描述
在 macOS 环境下使用 Antigravity IDE 进行浏览器自动化任务时，点击 Chrome 图标无响应，或无法启动浏览器窗口。

### 现象
- 点击 IDE 工具栏的 Chrome 图标没有任何反应。
- 终端运行 IDE 时可能看到 `Can’t get path` 或 `Operation not permitted` 等权限错误。
- 即使 Chrome Binary Path 配置正确，IDE 也无法拉起 Chrome 进程。

## 2. 根本原因 (Root Cause)
**macOS TCC (Transparency, Consent, and Control) 权限拦截**。

Antigravity IDE 作为一个由 Electron 构建的 [智能多 Agent 系统](/posts/mastering-antigravity-agents-cn/)，在尝试通过 AppleEvents 或子进程调用控制 Google Chrome 时，被 macOS 的安全机制拦截。如果用户未在“隐私与安全性 -> 自动化”或“完全磁盘访问权限”中明确授权，操作将静默失败。

由于直接对 IDE 进行授权可能因签名或路径问题不生效，**权限继承**是更简单有效的绕过方案。

## 3. 解决方案 (Solution)

### ✅ 最佳方案：通过 Terminal 启动 IDE
利用 Terminal（终端）通常拥有较高的系统权限。通过终端启动 IDE 的核心可执行文件，可以让 IDE **继承**终端的权限，从而无需繁琐的系统设置即可成功控制 Chrome。

启动命令：
```bash
/Applications/Antigravity.app/Contents/MacOS/Electron
```
> 注意：可执行文件名为 `Electron` 而非 `Antigravity`。

### ❌ 不推荐方案
1. **手动启动 Chrome**：如果不通过 IDE 启动，会导致 IDE 试图再次启动时发生 User Data Directory 锁定冲突 (Singleton Lock)，导致无法连接。
2. **授予完全磁盘访问权限 (Full Disk Access)**：虽然有效，但权限过高，且有时因应用重签名导致授权失效。

## 4. 正确的配置参考
在修复启动方式后，请确保 IDE 中的配置如下：

- **Chrome Binary Path**:
  ```text
  /Applications/Google Chrome.app/Contents/MacOS/Google Chrome
  ```
- **User Profile Path**:
  建议使用独立目录，避免影响日常使用的 Chrome：
  ```text
  /Users/<你的用户名>/.gemini/antigravity-browser-profile
  ```

## 5. 排查工具 (备用)
如果上述方案仍无效，可使用以下脚本验证环境基础（端口 9222 和文件权限）：

```bash
# 验证端口是否被占用
lsof -i :9222

# 验证二进制路径是否存在
ls -d "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
```
