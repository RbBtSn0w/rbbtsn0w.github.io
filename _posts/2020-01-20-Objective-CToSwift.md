---
layout: post
title: "Objective-C And Swift"
date: 2020-01-03
categories: iOS, Objective-C, Swift
tags: iOS, Swift
---

2020 开始将工作的中的一些项目迁移到Swift，整理一些迁移中遇见的问题和解答。

## Objective-C And Swift 混合编程的方式 官方说明

[Importing Objective-C into Swift](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis/importing_objective-c_into_swift)

[Importing Swift into Objective-C](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis/importing_swift_into_objective-c)

### Cocoa Touch Framework does not support Bridge Header

想到混合编程大家容易Bridge Header, 其实在Framework 的方式中,是不支持的, Bridge Header.

To use the Objective-C declarations in files in the same framework target as your Swift code, you’ll need to import those files into the Objective-C umbrella header—the master header for your framework. Import your Objective-C files by configuring the umbrella header:

1. Under Build Settings, in Packaging, make sure the Defines Module setting for the framework target is set to Yes.

2. In the umbrella header, import every Objective-C header you want to expose to Swift.

Swift sees every header you expose publicly in your umbrella header. The contents of the Objective-C files in that framework are automatically available from any Swift file within that framework target, with no import statements. Use classes and other declarations from your Objective-C code with the same Swift syntax you use for system classes.

## 反射

```Objective-C

[NSClassFromString(@"ViewController") alloc] initWithNib:nil withBundle:nil];

```

``` Swift

```
