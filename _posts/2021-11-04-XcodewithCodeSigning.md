---
layout: post
title: "Xcode with Code Signing"
date: 2021-11-04
categories: [iOS, Xcode]
tags: [code-signing, provisioning, xcode, ios]
description: "Xcode 代码签名的常见问题排查与自助修复指南，含证书、私钥、描述文件与配置建议。"
---

## INFORMATION ABOUT CODE SIGNING

For more information about code signing, please review the following resources:

Xcode Help: App Signing
https://help.apple.com/xcode/mac/current/#/dev3a05256b8

Support: Code Signing
https://developer.apple.com/support/code-signing/


## SELF-HELP TROUBLESHOOTING INFORMATION

Here are some self-help resources you can use for diagnosing and resolving some common code signing problems:

❏ Use automatic code signing:
Xcode’s automatic code signing is recommended for the majority of Xcode projects. This may be available for you. Automatic code signing will manage code signing for your project, including correcting some of the code signing build errors that can occur. Please try building your project with automatic code signing enabled for all of its targets.

❏ Go through this short troubleshooting list:
Xcode Help: Signing troubleshooting
<https://help.apple.com/xcode/mac/current/index.html?localePath=en.lproj#/dev01865b392>

❏ Try using a new login account on your machine:
In your System Preferences, use the Users & Groups panel to create a new login account on your machine. Then, login as that user, copy your Xcode project to the new login account, and try to build your app. If you able to build and sign your app, then this suggests there is a problem in your original login account. You can continue using the new login account to build and sign your app while troubleshooting your original login account. Here are some troubleshooting items you can use to correct problems in your original login account:

• Search for “Development” or “Distribution“ certificates in the Keychain Access app (in /Applications/Utilities). Delete any duplicate or invalid certificates that you find (When deleting duplicate certificates, keep the certificate with the most recent expiration date).
• Continuing in Keychain Access, if any of your “Development” or “Distribution“ certificates are missing their private keys, follow these directions: <https://help.apple.com/xcode/mac/current/#/devd1432da9a>
• Temporarily, move all of the files inside of ~/Library/MobileDevice/Provisioning Profiles into a new folder and try a build.