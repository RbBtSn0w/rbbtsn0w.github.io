---
layout: post
title: "Hard tab 与 Soft Tab 之争"
date: 2018-01-16
---

看到这个还是从[Atom](https://atom.io) 看到的，上次听说这事也是还是从《硅谷》第三季听到。

在[Atom](https://atom.io) 设置下，Tab type 选项的说明
> <em> Determine character inserted when Tab key is pressed. Possible values: “auto”, “soft” and “hard”. When set to “soft” or “hard”, soft tabs (spaces) or hard tabs (tab characters) are used. When set to “auto”, the editor auto-detects the tab type based on the contents of the buffer (it uses the first leading whitespace on a non-comment line), or uses the value of the Soft Tabs config setting if auto-detection fails.</em>

从这细读不难发现，在使用tab 键和spaces 键，大家本能意识上没发现有区别的，其实在文档编辑中，使用了不通占位符的。
刚好最近碰到的就是，有同学通过windows 下的编辑器编写的文档代码，传给我在MacOS 下看总是有排版不对齐，一开始以为是Atom 的问题呢。

简单看就是这两个键，在物理的角度看，Hard Tab 键占据位置依赖操作系统分配位置长度，而space 键其实就单个空格位置长度。所以最好的工作方式，就是改掉Hard Tab。

即 Soft Tab = 4 * Space 的长度。
