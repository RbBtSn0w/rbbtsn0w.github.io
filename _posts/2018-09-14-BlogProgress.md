---
layout: post
title: "Blog progress"
date: 2018-09-14
categories: Jekyll
tags: [Jekyll, tech]
---

## 背景

这个Blog 使用[Jekyll blog](https://jekyllrb.com) 搭建, 服务使用 Github.io 来做的, 跑了大概半年后，现在想给它加入 tag 功能，主要后面做下区分，也方便去做索引处理。

## 加入tags 功能

这里加入Tag 的操作，增加Plug 模块，打开 _config.yml，找到plug并在下面加入 - jekyll-archives - jekyll-sitemap 两个模块。

然后就是在_posts 目录下面的每个文件中，加入categories 和 tags 即可，多个使用空格分割。

## Post 格式

### 代码

注意点:

* 首字母小写
* `Objective-c` need replace to `objc` for code syntax.

* 常用一些 `Crash`, `堆栈信息`, 这类都统一使用`console` 即可.

> [^write-a-new-post] By default, all languages except plaintext, console, and terminal will display line numbers. When you want to hide the line number of a code block, add the class nolineno to it:

````markdown
```shell
echo 'No more line numbers!'
```
{: .nolineno }
````

更多[^code-table].

## Reverse Footnote

[^code-table]: [Supported syntax highlighting in Jekyll](https://www.fabriziomusacchio.com/blog/2021-08-11-Syntax_Highlighting_in_Jekyll/)

[^write-a-new-post]: [write-a-new-post](https://chirpy.cotes.page/posts/write-a-new-post/)
