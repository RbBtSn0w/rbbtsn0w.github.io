---
layout: post
title: "GitHub Pages site with Free SSL/TLS"
date: 2024-03-18
categories: [Jekyll]
tags: [github-pages, https, tls, ssl, cloudflare, cname]
mermaid: true
description: "使用 Cloudflare 为 GitHub Pages 配置自定义域与免费 SSL/TLS 的完整指引。"
---

## 背景

Github Pages site 支持Custom Domain 的能力.
> Custom domains allow you to serve your site from a domain other than USERNAME.github.io.

但是，默认情况下，GitHub Pages site使用的是HTTP协议，这意味着如果您使用了自定义域名，那么您的网站将无法通过HTTPS访问。
而HTTPS证书都是收费的，所以如果您需要使用HTTPS，那么您需要购买一个证书。

行业内cloudflare提供了免费的SSL/TLS 证书方案, 可以免费使用.

而当前的域名是在GoDaddy 购买的, 所以现在需要将三者绑定在一起来用, 解决 Custom Domain + HTTPS 的问题.

## GoDaddy 的Namespace 切换到 Cloudflare提供的Nameservers

已知Cloudflare提供免费的SSL/TLS 证书, 切换到Cloudflare提供的Nameservers可以满足此功能.

当您将域名的Nameservers（名称服务器）从GoDaddy切换到Cloudflare提供的Nameservers时，在网络拓扑上会发生以下变化：

* 在GoDaddy使用GoDaddy Nameservers的情况：

  1. DNS解析权威性：当其他服务器或客户端试图找到您的域名对应的IP地址时，它们会查询GoDaddy的Nameservers来获取这些信息。GoDaddy的Nameservers是您域名DNS记录的权威来源。
  2. DNS管理：您在GoDaddy的控制面板中进行所有DNS管理操作，如添加或修改A记录、CNAME记录、MX记录等。
  3. 流量路由：用户访问您的网站时，他们的请求直接路由到您在DNS记录中指定的服务器IP地址。

* 切换到Cloudflare提供的Nameservers之后：

  1. DNS解析权威性：Cloudflare的Nameservers成为您域名DNS记录的权威来源。这意味着，当其他服务器或客户端查找您的域名时，现在他们会向Cloudflare发起查询。
  2. DNS管理：您现在在Cloudflare的控制面板中管理您的DNS记录。这包括修改或添加新的DNS记录、设置页面规则、配置SSL/TLS、管理缓存等。
  3. 流量路由和安全性：用户访问您的网站时，他们的请求会通过Cloudflare的全球网络。Cloudflare充当您的网站和访问者之间的代理，提供额外的安全性（如DDoS保护、Web应用防火墙）和性能优化（如内容分发网络CDN、智能路由）。
  4. 缓存和内容分发：Cloudflare的CDN将缓存您网站的静态资源，靠近用户的边缘节点会提供这些资源。这可以减少延迟，加快内容加载速度。
  5. 额外的功能：Cloudflare提供了许多额外的功能，如SSL证书自动化、网络分析、自定义页面规则、流量控制等，您可以在Cloudflare的控制面板中进行配置。

### 找到 Cloudflare 的Nameservers

1. 创建域名
2. DNS Records
3. 找到 Cloudflare Nameservers
4. 复制保存

### Nameservers 切换

将GoDaddy 的Nameservers 切换到 Cloudflare提供的 Nameservers

1. 登录GoDaddy
2. 进入域名管理
3. 点击 “DNS”
4. 点击 “Nameservers” -> "Change Nameservers"
5. 选择"User my own nameservers", 并将从Cloudflare获取的Nameservers 填入
6. 点击 “Save”

到此完成了域名的Nameservers 切换, 可以关闭了GoDaddy了.

## 在GitHub Pages设置自定义域名

1. 打开您的GitHub仓库，进入到“Settings”。
2. 在侧边栏中选择“Pages”。
3. 在“Custom domain”部分，输入您的GoDaddy域名，例如example.com。
4. 如果需要，勾选“Enforce HTTPS”来强制使用HTTPS连接。
5. 保存这些设置。
6. GitHub将会提供一个文件CNAME，或者您需要在仓库根目录或docs/目录中手动添加一个带有域名的CNAME文件。

## Cloudflare 添加自定义域名

在Cloudflare上为GitHub Pages配置自定义域名时，正确设置DNS记录是确保HTTPS证书正确生成的关键步骤。按照GitHub的官方文档，这里是应该如何填写CNAME以及ALIAS或ANAME记录的指南：

> Github的文档 [Configuring an apex domain](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site#configuring-an-apex-domain)

* 对于Apex域（裸域，如example.com）：

  1. A记录:
    类型: A
    名称: @ (或者您的裸域名example.com，@代表裸域)
    值: GitHub Pages的IP地址列表
  2. AAAA记录:
    类型: AAAA
    名称: @ (或者您的裸域名example.com)
    值: GitHub Pages的IPv6地址列表

  3. ALIAS或ANAME记录 (如果您的DNS提供商支持):
    类型: ALIAS 或 ANAME
    名称: @ (或者您的裸域名example.com)
    值: USERNAME.github.io 或 ORGANIZATION.github.io (替换成您的GitHub用户名或组织名)

* 对于子域（如www.example.com，blog.example.com）：

  1. CNAME记录:
    类型: CNAME
    名称: SUBDOMAIN (例如www或blog)
    值: USERNAME.github.io 或 ORGANIZATION.github.io (替换成您的GitHub用户名或组织名)
    > 这是一个可选, 如果用的裸域名example.com, 这里不需要填写, A/AAA默认用的顶级域名example.com

Cloudflare上设置DNS记录的方法如下：

1. 登录到您的Cloudflare账户。
2. 选择相关的域名。
3. 点击“DNS”选项卡。
4. 根据需要的类型（A，AAAA，CNAME，ALIAS或ANAME），点击“添加记录”按钮。
5. 填写相应的“类型”，“名称”和“值”字段。
6. 保存记录。

注意：Cloudflare不支持传统的ALIAS或ANAME记录类型。但是，Cloudflare提供了一个功能类似的记录叫做“CNAME Flattening”，它可以在根域名上工作，就像ALIAS或ANAME记录一样。如果您设置根域名的CNAME记录，Cloudflare会自动应用CNAME Flattening。

## 触发GitHub的HTTPS证书生成

 1. 如果您刚刚添加或修改了自定义域名，您可能需要在GitHub仓库的Pages设置中移除并重新添加您的自定义域名来触发GitHub的SSL证书生成过程。
 2. 转到GitHub仓库的“Settings”。
 3. 在“Pages”部分，移除当前的自定义域名，然后重新添加它，并保存。

## 测试

使用Cloudflare提供的Speed下的Observatory 可以做定期网站测试功能.
将Frequency 设置为每周即可.
