---
layout: post
title: "Xcode build error at -fobjc-weak flag"
date: 2019-12-04
categories: [Xcode]
tags: [objective-c, macos, arc]
description: "修复 -fobjc-weak 在部署目标不支持时的构建错误，并说明 Xcode 配置项影响。"
---

## Background

When click Xcode project and upgrade the project config for old Xcode version, like manage auto release.

you will see this error on your message list.

clang: error: -fobjc-weak is not supported on the current deployment target

The reason is Xcode add new command line "CLANG_ENABLE_OBJC_WEAK = YES;".

## Resolve

Now remove it on Xcode config, and build it again.

"CLANG_ENABLE_OBJC_WEAK = YES;"
