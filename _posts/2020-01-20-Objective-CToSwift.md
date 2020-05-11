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

### Modular Headers

Xcode config

    1. Defines Module(DEFINES_MODULE), Switch `YES`
    2. Module Map File(MODULEMAP_FILE). If use by LLVM control this file, will automatic file, otherwise by hand setting.

CocoaPods Config

Custom config your CocoaPods file, like podfile, podspce.

    1. podspce config, insert `DEFINES_MODULE' => 'YES` at `pod_target_xcconfig`. eg: s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
    2. podfile, open all pod config modular. use_modular_headers!
    3. special pod config on podfile. eg: :modular_headers => true

## 反射

```Objective-C

[NSClassFromString(@"ViewController") alloc] initWithNib:nil withBundle:nil];

```

``` Swift

```