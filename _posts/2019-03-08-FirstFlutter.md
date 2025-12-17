---
layout: post
title: "初探Flutter的外貌和特征"
date: 2019-03-08
categories: [Flutter]
tags: [flutter, dart, state-management, localization, skia]
description: "Flutter 基础概览：UI 架构、状态管理与工具链实践，入门与常见坑位。"
---

## 背景

Flutter 是谷歌的移动UI框架，可以快速在iOS和Android上构建高质量的原生用户界面。语言是用Dart编写。

## UI

UI层上，以Flutter 框架封装一层自己的UI结构，单个View成为Widget，View以状态为区分，分为stateless和stateful。

## 框架

Flutter的框架，官方给了一些设计方案，与Flutter 的背景，整个框架基于状态模式，state management，按照Flutter 提到的，分为短暂状态 ephemeral state 和app 状态，简单说，Flutter 的业务状态，如用户点击按钮更新逻辑和UI； app 自身状态，如app收到消息通知。

发现一个有趣的讨论点，讨论状态设计。如

    When asked about React’s setState versus Redux’s store, the author of Redux, Dan Abramov, replied:

    “The rule of thumb is: Do whatever is less awkward.”

[原文](https://github.com/reduxjs/redux/issues/1287#issuecomment-175351978)

为了能够简单入手，官方推荐了一些Flutter 开发的优秀框架的设计实现和案例分享，[传送门](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options)。

## 本地化

本地化，这个比较简单，Flutter 封装的一套工具类，和现在NSLocalization差不多的适用方式。

## [Tools](https://flutter.dev/docs/development/tools) & Debug

Flutter 的开发环境是另外一套环境，IDE，VS（VS code）， AS（Android Studio）可以安装对应的plug。

Debug，分为命令行和自定义。

命令行通过安装Dart Command Line 进行调试。
自定，现在是可以支持在Android Studio 上调试，而iOS 现在还不支持在Xcode 等一系列Apple 的工具进行调试。

视图界面，现在有的是基于浏览器方式；代码扫描，依赖Drat的扫描工具。整体看没有集成在一个统一环境中，前期存在一定的陡峭学习阶段。也许开发中的异常环境，可能就导致开发者折腾大半天的时间。有待改善。

## 结尾

总的来说，Flutter 是一个全新的平台（Web， Native之外），基于底层的图像引擎[Skia](https://skia.org/)做渲染交互，涉及到系统核心模块，通过互通的Native API调用。可以看到开发环境还存在很多改进的路要做，相对原始开发而言，完整的工具链，三方库，都是强大的优势。但是，Flutter 这一套设计方案，google 其实也同样在另外一个操作系统Fuchsia使用，而底层的Skia 引擎也应用在大家熟知的浏览器Chrome中。未来是Google的 “Web“ 一统江湖的平台吗？

### 更新

Flutter 在Android中至少要增加6.3MB 的包大小，在iOS中支持要增加14MB 左右。另外Flutter 由于使用独立的渲染引擎，目前内存占用的情况不是很理想，在iOS build 的版本中内存在100MB 左右，并且是单例模式，即使做了页面关闭之后没有去释放内存，对App 的性能，稳定性，体积，开发环境，都存在不足。
