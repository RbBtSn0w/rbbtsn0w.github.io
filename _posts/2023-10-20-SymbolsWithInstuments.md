---
layout: post
title: "dSYM(Symbols) issue with Instruments tool"
date: 2023-10-24
categories: Xcode
tags: iOS, Instruments, Symbols, Debug, dSYM
---

## Background

When you run profile on Xcode, the configuration have default values. e.g: Build Configuration( by Profile) : Release, everything will on the right, symbols will show on Instruments tool.

![Xcode](/assets/img/post/2023-10-20-SymbolsWithInstuments/2.jpg)

## What's happened

Sometime you want change the Build Configuration( by Profile) : Debug, the symbols is not support.

> Stack Track is memory address

![Instruments](/assets/img/post/2023-10-20-SymbolsWithInstuments/7.jpg)

> Error: Permission to profile this process was denied. Applications you wish to profile must be signed with a developer code

![Instruments](/assets/img/post/2023-10-20-SymbolsWithInstuments/1.jpg)

## How to fix

Why the release configuration is success?

Have two case is different setting with `Release` in `Debug` on Xcode configurations.

### generate symbol file

generate symbol file of target, by default is on release.

![Xcode](/assets/img/post/2023-10-20-SymbolsWithInstuments/3.jpg)

So let's change the Debug value: `DWARF` to `DWARF with dSYM File`.

> BTW: `DWARF with dSYM File` spend you build time.

![Xcode](/assets/img/post/2023-10-20-SymbolsWithInstuments/4.jpg)

> when you debug was finished, you need change change value to `DWARF`.

### Code sign

The issus like this case.

![Instruments](/assets/img/post/2023-10-20-SymbolsWithInstuments/1.jpg)

What's going on here?

It's code sign requirement by Identify for Instruments env.

Let's change `Code Signing Identity` value to `iOS Developer` or `Apple Developer`.

![Xcode](/assets/img/post/2023-10-20-SymbolsWithInstuments/5.jpg)

## Happy Debug

Now everything is ready, check it.

![Instruments](/assets/img/post/2023-10-20-SymbolsWithInstuments/6.jpg)
