---
layout: post
title: "Cocoapods 下 podfile 如何debug"
date: 2019-12-19
categories: XCode
tags: Cocoapods, Debug, Ruby
---

## Background

查了 Xcodeproj 和 Cocoapods 的文档之后我都没有得到很好的解答，所以我就想用 xcodeproj 本身的接口去处理这件事情。

## Resolve

由于 Podfile 本质上是 Ruby 脚本，所以这里我通常会使用 Ruby 的 debugger 去操作，通过 Ruby 强大的自省能力，在 debugger 里进行尝试然后找到我们需要的接口，开始之前我们需要安装一个 Ruby 的工具，步骤如下：

 首先是安装 debugger gem install pry
 接着在 Podfile 的开头导入 require 'pry'
 然后在我们想要插入断点的地方插入 binding.pry 语句就可以了
