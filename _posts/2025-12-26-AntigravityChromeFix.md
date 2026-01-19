---
layout: post
title: "Antigravity 中 Chrome 启动失败修复指引"
date: 2025-12-26
categories: [AI, macOS]
tags: [antigravity, chrome, macos, automation, permissions]
description: "通过终端继承权限修复 Antigravity IDE 无法拉起 Chrome 的问题，附配置参考与排查脚本。"
---

## 1. 问题描述
在 macOS 环境下使用 Antigravity IDE 进行浏览器自动化任务时，点击 Chrome 图标无响应，或无法启动浏览器窗口。

### 现象
- 点击 IDE 工具栏的 Chrome 图标没有任何反应。
- 终端运行 IDE 时可能看到 `Can’t get path` 或 `Operation not permitted` 等权限错误。
- 即使 Chrome Binary Path 配置正确，IDE 也无法拉起 Chrome 进程。

## 2. 根本原因 (Root Cause)
**macOS TCC (Transparency, Consent, and Control) 权限拦截**。

Antigravity IDE 作为一个由 Electron 构建的应用，在尝试通过 AppleEvents 或子进程调用控制 Google Chrome 时，被 macOS 的安全机制拦截。如果用户未在“隐私与安全性 -> 自动化”或“完全磁盘访问权限”中明确授权，操作将静默失败。

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
