---
layout: post
title: "CocoaPods之post_install常用工具"
date: 2020-01-03
categories: CococaPods
tags: iOS, CococaPods, Xcode
---

整理一些日常使用的 post_install 工具。
为了方便观察日志，可以通过使用下面的命令输出到指令文件

```bash

# > 表示输出到文件 podInstall.log 中，如果文件不存在会自动创建文件
pod install > podInstall.log

```

## 常用Xcode 配置打印

```ruby

post_install do |installer|
  installer.pods_project.targets.each do |target|
    puts "#===Target==#{target}"
    target.build_configurations.each do |config|
      config.build_settings.each do |build_setting|
        puts "--#{build_setting}"
      end
    end
  end
end

```

## 关闭BitCode

```ruby

# 实现post_install Hooks
post_install do |installer|
  # 1. 遍历项目中所有target
  installer.pods_project.targets.each do |target|
    # 2. 遍历build_configurations
    target.build_configurations.each do |config|
      # 3. 修改build_settings中的ENABLE_BITCODE
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end

```

## GCC_ENABLE_OBJC_GC 修改

```ruby

#修改GCC对OBJC的支持
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['GCC_ENABLE_OBJC_GC'] = 'supported'
    end
  end
end

```

## 打印 Xcode config 信息

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    puts "#===Target==#{target}"
    target.build_configurations.each do |config|
      config.build_settings.each do |build_setting|
        puts "--#{build_setting}"
      end
    end
  end
end


```

## 手动开启 module 支持

```ruby

def generate_modulemap(name, path)
   f = File.new(File.join("#{path}/module.modulemap"), "w+")
   module_name = "#{name}"
   while(module_name["+"])
       module_name["+"] = "_"
   end
   f.puts("module XB#{module_name} {")
   f.puts("    umbrella header \"#{name}_umbrella.h\"")
   f.puts("    export *")
   f.puts("}")
end

def generate_umbrella(name, path)
   f = File.new(File.join("#{path}/#{name}_umbrella.h"), "w+")
   f.puts("#import <Foundation/Foundation.h>")
   Dir.foreach(path) do |filename|
       if filename != "." and filename != ".."
           f.puts("#import \"#{filename}\"")
       end
   end
end

post_install do |installer|
   headers_path = "#{Dir::pwd}/Pods/Headers/Public/"
   installer.pods_project.targets.each do |target|
       target_header_path = "#{headers_path}#{target.product_name}"
       puts target_header_path
       if File.exist?(target_header_path)
           filename = target.product_name
           if filename != "." and filename != ".."
               generate_umbrella(filename, target_header_path)
               generate_modulemap(filename, target_header_path)
           end
       end
   end
end

```

## 参考

[post_install hook](https://www.jianshu.com/p/d8eb397b835e)
