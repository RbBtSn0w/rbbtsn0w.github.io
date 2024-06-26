---
layout: post
title: "Semantic Versioning"
date: 2020-05-21
categories: Project
tags: [Version Control]
---


参与项目有了10年左右的阶段, 前前后后也基础不少项目. 但是在版本上,大家的管理并没有一个统一的规范, 前段时间同事给我推荐了, Semantic Versioning, 中文: 语义化版本, 就是对软件的版本号设计了一套标准定义. 其实软件版本号的定义,各自公司都有自己情况,所以大概上有所不同.

这里就简单解释下这个内容.

版本格式：`主版本号.次版本号.修订号`，版本号递增规则如下：

* 主版本号：当你做了不兼容的 API 修改，
* 次版本号：当你做了向下兼容的功能性新增，
* 修订号：当你做了向下兼容的问题修正。

先行版本号及版本编译元数据可以加到“主版本号.次版本号.修订号”的后面，作为延伸。

> 详细解释和说明,访问官方网站 [Semantic Versioning](https://semver.org)
