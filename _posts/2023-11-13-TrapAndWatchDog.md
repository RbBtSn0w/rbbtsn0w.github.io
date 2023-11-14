---
layout: post
title: "Mark `mach_msg2_trap` and 'Watchdog'"
date: 2023-11-13
categories: Crash
tags: iOS, Crash, Mach-O, Symbols, Debug, dSYM
---


## Background

关于"mach_msg2_trap", 经常会在iOS的Crash堆栈中看到相关信息, 为了更好理解所以找了`DTS` 去了解"mach_msg2_trap" 的情况.

```Crash
Thread 0 name:
Thread 0 Crashed:
0   libsystem_kernel.dylib        	0x000000020fdb7030 mach_msg2_trap + 8
1   libsystem_kernel.dylib        	0x000000020fdc8b18 mach_msg2_internal + 76 (mach_msg.c:201)
2   libsystem_kernel.dylib        	0x000000020fdc8db8 mach_msg_overwrite + 484 (mach_msg.c:0)
3   libsystem_kernel.dylib        	0x000000020fdb7524 mach_msg + 20 (mach_msg.c:323)
4   CoreFoundation                	0x00000001d5b50148 __CFRunLoopServiceMachPort + 156 (CFRunLoop.c:2622)
5   CoreFoundation                	0x00000001d5b512e0 __CFRunLoopRun + 1208 (CFRunLoop.c:3005)
6   CoreFoundation                	0x00000001d5b55d20 CFRunLoopRunSpecific + 584 (CFRunLoop.c:3418)
7   GraphicsServices              	0x000000020c6dc998 GSEventRunModal + 160 (GSEvent.c:2196)
8   UIKitCore                     	0x00000001d7de780c -[UIApplication _run] + 868 (UIApplication.m:3782)
9   UIKitCore                     	0x00000001d7de7484 UIApplicationMain + 312 (UIApplication.m:5372)
10  Demo                        	0x000000010309b748 ApplicationMain + 160 (AppDelegate.m:40)
11  dyld                          	0x00000001f32fc344 start + 1860 (dyldMain.cpp:1165)

```

## Content

本文将深入探讨iOS中的"mach_msg2_trap"和Watchdog之间的关系。通过对这两个概念的解释和讨论，我们将深入理解它们在应用程序运行和系统监控方面的角色。本文还将提供一些与"mach_msg2_trap"和Watchdog相关的背景信息，以支持我们的观点。

### What's `mach_msg2_trap`?

"mach_msg2_trap"是一个在iOS操作系统中常见的函数。它是用于实现进程间通信（IPC）的机制之一，通过该机制可以在应用程序之间传递消息和数据。
具体而言，"mach_msg2_trap"是基于Mach消息传递机制的一种变体。Mach是苹果操作系统的内核组件之一，它提供了一种用于进程间通信的底层机制。而"mach_msg2_trap"作为Mach消息传递机制的一部分，用于在用户空间和内核空间之间传递消息。
当应用程序需要与其他进程或系统内核进行通信时，它可以使用"mach_msg2_trap"函数来发送和接收消息。应用程序可以调用该函数来指定消息的类型、目标进程或内核端口，以及传递的数据等信息。
值得注意的是，"mach_msg2_trap"函数通常不会直接在应用程序代码中出现，而是在系统库或框架中使用。应用程序开发者通常会使用更高级别的接口和框架，这些接口和框架会隐式地使用"mach_msg2_trap"来进行底层的进程间通信操作。
总结起来，"mach_msg2_trap"是iOS操作系统中用于进程间通信的一种底层机制，基于Mach消息传递技术。它允许应用程序发送和接收消息，以实现与其他进程或系统内核的交互。

### What's `WatchDog`?

> Apple's iOS watchdog system enforces performance requirements by monitoring launch times and app responsiveness. If an app takes too long to launch or is unresponsive for too long, the watchdog will automatically terminate it on the user's behalf. [Link](https://www.bugsnag.com/blog/ios-performance-monitoring-best-practices/)

来自官方的说明 [Addressing watchdog terminations](https://developer.apple.com/documentation/xcode/addressing-watchdog-terminations)

### Will trigger `WatchDog` when `mach_msg2_trap`?

>No, quite the oppposite actually.  mach_msg2_trap is the mechanism the
system uses to deliver events into your app so, so you're not really
"stuck" in it at all.  When the user touches (or otherwise interacts
with your app), your app will immediately return form "mach_msg2_trap",
since delivering those events is actually what it's "for".
>
>Similarly, the technical reason an app killed by the watchdog is that it
WASN'T blocked in "mach_msg2_trap" "often enough".  In theory it's
possible for an app to block in "mach_msg2_trap" for minutes/hours/days.
 The only reason that doesn't/wouldn't happen is that events or other
activity (like timers).
>
> However, an app blocked in the standard "mach_msg2_trap" event
loop can't really be stuttering or hung.

"mach_msg2_trap"是系统用于将事件传递到应用程序的机制，并不会让应用程序真正卡住。当用户触摸或与应用程序交互时，应用程序会立即从"mach_msg2_trap"返回，因为传递这些事件是该机制的工作核心。

* "mach_msg2_trap"不会让应用程序卡住
* Watchdog终止应用程序的技术原因是应用程序没有足够频繁地阻塞在"mach_msg2_trap"中。
