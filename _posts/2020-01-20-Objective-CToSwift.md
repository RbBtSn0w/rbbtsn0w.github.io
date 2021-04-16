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

为了简单直接, 这里直接指出官方书籍中特别指出的观点.

#### Importing Objective-C into Swift

    “To import a set of Objective-C files in the same framework target as your Swift code, you’ll need to import those files into the Objective-C umbrella header for the framework.

    To import Objective-C code into Swift from the same framework

    Under Build Settings, in Packaging, make sure the Defines Module setting for that framework target is set to “Yes”.
    In your umbrella header file, import every Objective-C header you want to expose to Swift. For example:”

#### Importing Swift into Objective-C

    “To import a set of Swift files in the same framework target as your Objective-C code, you don’t need to import anything into the umbrella header for the framework. Instead, import the Xcode-generated header file for your Swift code into any Objective-C .m file you want to use your Swift code from.

    Because the generated header for a framework target is part of the framework’s public interface, only declarations marked with the public or open modifier appear in the generated header for a framework target.”

这个地方需要特别留意下的地方就是 .m 这个关键字.

在ObjC 项目中引入了Swift的代码, 引入相关的头文件一定要放在.m 这个原因也很简单,避免循环引用相同的头文件, 原因就是在于Module 中倒入的XXX-Swift.h 其实已经是一个Public 状态, 这过程中其实就是将一些ObjC 的文件有导出了一次.

解决办法其实有两个.

1. 采用书中提到的使用.m, 将倒入的XXX-Swift.h 放倒入ObjC 的.m文件中,降低暴露到.h, 避免Public化.
2. 如果你是CocoaPods, 是通过 Podspec 配置你的项目, 做法就是, 将相关的Public 文件, 都手动过滤出来, 然后其他的文件默认就是Project 状态(反之Private也行). 如果是Xcode Project的管理方式, 就直接修改访问权限就可以了.

> Source: Xcode Developer Library > Tools & Languages > IDEs > Project Editor Help > Setting the Visibility of a Header File

## Xcode 配置准备

如果你的工程是一个ProjectDemo 工程,配置一个framework, 对于混编,两个配置必须都要支持swift.
如ProjectDemo 工程就需要配置projectName-Bridging-Header.h 配置文件,并且导入一个.swift的文件,空的也行.
对于framework, swift 引入的任何工程中的Objective-C 代码的头文件必须写在伞文件中去import, 另外import 过去的文件确保也是public 的状态.

这样的编译才能算启动完成.说白了就是如果你的Project中下面的某个framework 用到Swift,既是工程上没使用Swift 代码,也是需要开启Swift的配置才行.

如果你的工程

### Pure Swift Project with Objective-C project build

Build for Swift Project

    1. Open your Xcode, select your build target, `Build Settings`, open `Build Libraries for Distribution`, switch to `YES` (Pure Swift Project need support LibraryEvolution [Library Evolution for Stable ABIs](https://github.com/apple/swift-evolution/blob/master/proposals/0260-library-evolution.md) ) [WWDC](https://developer.apple.com/videos/play/wwdc2019/416/).
    2. Need at `@objc` if you want share to Objective-C.
    3. Support Objective-C access. `Open`, `public`, `internal`, `fileprivate`, `private`

#### Node: Enable Library Evolution

> The legacy build system does not support building projects with Swift when SWIFT_ENABLE_LIBRARY_EVOLUTION is enabled.

``` Xcode Log

<unknown>:0: error: module compiled with Swift 5.2.4 cannot be imported by the Swift 5.1.2 compiler

```

Setting BUILT_PRODUCTS_DIR is On

### Modular Headers

Xcode config

    1. Defines Module(DEFINES_MODULE), Switch `YES`
    2. Module Map File(MODULEMAP_FILE). If use by LLVM control this file, will automatic file, otherwise by hand setting.

CocoaPods Config

Custom config your CocoaPods file, like podfile, podspce.

    1. podspce config, insert `DEFINES_MODULE' => 'YES` at `pod_target_xcconfig`. eg: s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
    2. podfile, open all pod config modular. use_modular_headers!
    3. special pod config on podfile. eg: :modular_headers => true

## 项目中实践的一些Tips

### 反射

```Objective-C

[NSClassFromString(@"ViewController") alloc] initWithNib:nil withBundle:nil];

```

``` Swift

// 依靠Mirro, 待补充

```

### Swift import

下面这个方式为了解决一下SDK中内部引入, 和pod 的源码引入导致的文件找不到的情况.

```Objective-C

#if __has_include("TargetName-Swift.h")
    #import "TargetName-Swift.h"
#else
    #import <TargetName/TargetName-Swift.h>
#endif


```

>一般在比较打的项目中,每次加入上述四行代码不麻烦, 但是后期如果涉及到相关的重构或者修改, 会带来额外的工作, 所以对我的工作而言, 引入一个新的header 文件, 专门提供给ObjC 引入 Swift 的头文件的类. 然后将上述代码包装进去, 方便了很多事情.

### @objc & NS_SWIFT_NAME

@objc 帮助你给swift的文件声明提供对Objc 的对外定义
NS_SWIFT_NAME 则相对 @objc 功能相反.
