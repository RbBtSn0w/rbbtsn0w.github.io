---
layout: post
title: "Xcode Debug Memory Graph"
date: 2018-09-21
categories: [iOS, Xcode]
tags: [xcode, memory, graph, ios, macos]
description: "开启 Xcode Memory Graph 的日志与配置，辅助定位内存对象与泄漏。"
---


这个功能大家都使用过了，可以大家在使用的时候，只能看到图的结构，但是并不能看到的代码符号上的堆栈。
现在告诉大家一个开启的办法。
打开Schema 的设置，点击 Diagnositcs，看到Loggin 并勾选，选择 All Allocation and Free Historey。
重新运行看看，是否有你想要的呢？
