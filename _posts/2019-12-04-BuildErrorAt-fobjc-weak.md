---
layout: post
title: "XCode build error at -fobjc-weak flag"
date: 2019-03-08
categories: XCode
tags: Objtive-c,macOS,ARC
---

# XCode build error at -fobjc-weak flag

When click XCode project and upgrade the project config for old Xcode version, like manage auto release.

you will see this error on your message list.

clang: error: -fobjc-weak is not supported on the current deployment target

The reason is XCode add new command line "CLANG_ENABLE_OBJC_WEAK = YES;".

Now remove it on XCode config, and build it again.
