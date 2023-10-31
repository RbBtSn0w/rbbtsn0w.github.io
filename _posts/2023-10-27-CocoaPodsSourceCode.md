---
layout: post
title: "Read `Pods-*-resources.sh` code of CocoaPods by Static lib"
date: 2023-10-27
categories: CocoaPods
tags: iOS, CocoaPods, StaticLib, Framework
---

## Background

Will plan fix the [issues for CocoaPods static lib](https://github.com/CocoaPods/CocoaPods/issues/8431#issuecomment-1594534923)

The first things is understand the core code `Pods-*-resources.sh`.

## Detail

All commit will add on the Code

```bash
#!/bin/sh
set -e # 设置在脚本中遇到错误时立即退出。
set -u # 设置当使用未定义的变量时脚本退出。
set -o pipefail # 设置管道命令中任一命令失败时整个管道命令失败。

function on_error { # 定义一个名为on_error的函数，用于处理错误情况。
  echo "$(realpath -mq "${0}"):$1: error: Unexpected failure"
}
trap 'on_error $LINENO' ERR # 当发生错误时，执行on_error函数，并传递当前行号。

# 检查UNLOCALIZED_RESOURCES_FOLDER_PATH变量是否为空。如果为空，则表示没有资源需要复制，直接退出脚本。
if [ -z ${UNLOCALIZED_RESOURCES_FOLDER_PATH+x} ]; then 
  # If UNLOCALIZED_RESOURCES_FOLDER_PATH is not set, then there's nowhere for us to copy
  # resources to, so exit 0 (signalling the script phase was successful).
  exit 0
fi

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}" # 创建目标构建目录中的资源文件夹。

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt # 设置要复制的资源文件列表的路径。
> "$RESOURCES_TO_COPY" # 清空或创建一个空的资源文件列表。

XCASSET_FILES=() # 定义了一个空的数组变量XCASSET_FILES，用于存储.xcassets文件的路径。

# This protects against multiple targets copying the same framework dependency at the same time. The solution
# was originally proposed here: https://lists.samba.org/archive/rsync/2008-February/020158.html
RSYNC_PROTECT_TMP_FILES=(--filter "P .*.??????") # 定义了一个名为RSYNC_PROTECT_TMP_FILES的数组变量，用于保护临时文件不被复制。通过--filter选项配置了一个过滤器，用于排除以.开头、后面跟着6个字符的临时文件。

case "${TARGETED_DEVICE_FAMILY:-}" in #根据TARGETED_DEVICE_FAMILY环境变量的值，使用case语句来选择不同的逻辑分支。
  1,2)
    TARGET_DEVICE_ARGS="--target-device ipad --target-device iphone"
    ;;
  1)
    TARGET_DEVICE_ARGS="--target-device iphone"
    ;;
  2)
    TARGET_DEVICE_ARGS="--target-device ipad"
    ;;
  3)
    TARGET_DEVICE_ARGS="--target-device tv"
    ;;
  4)
    TARGET_DEVICE_ARGS="--target-device watch"
    ;;
  *)
    TARGET_DEVICE_ARGS="--target-device mac"
    ;;
esac

# 处理不同类型的资源文件
install_resource()
{
  if [[ "$1" = /* ]] ; then # 函数会判断资源文件的路径是否为绝对路径。如果是绝对路径，则直接使用该路径作为资源路径；
    RESOURCE_PATH="$1"
  else # 如果不是绝对路径，则将$1拼接到${PODS_ROOT}路径后面，作为资源路径。
    RESOURCE_PATH="${PODS_ROOT}/$1"
  fi
  if [[ ! -e "$RESOURCE_PATH" ]] ; then # 函数会检查资源路径是否存在。如果资源路径不存在，则输出错误信息并退出脚本。
    cat << EOM
error: Resource "$RESOURCE_PATH" not found. Run 'pod install' to update the copy resources script.
EOM
    exit 1
  fi
  case $RESOURCE_PATH in
    *.storyboard) # 使用 ibtool 将 .storyboard 文件编译成 .storyboardc 文件。
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc $RESOURCE_PATH --sdk ${SDKROOT} ${TARGET_DEVICE_ARGS}" || true
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc" "$RESOURCE_PATH" --sdk "${SDKROOT}" ${TARGET_DEVICE_ARGS}
      ;;
    *.xib) # 使用 ibtool 将 .xib 文件编译成 .nib 文件。
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib $RESOURCE_PATH --sdk ${SDKROOT} ${TARGET_DEVICE_ARGS}" || true
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib" "$RESOURCE_PATH" --sdk "${SDKROOT}" ${TARGET_DEVICE_ARGS}
      ;;
    *.framework) # 将 .framework 文件复制到 ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH} 目录下。
      echo "mkdir -p ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}" || true
      mkdir -p "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" $RESOURCE_PATH ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}" || true
      rsync --delete -av "${RSYNC_PROTECT_TMP_FILES[@]}" "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel) # 使用 xcrun momc 将 .xcdatamodel 文件编译成 .mom 文件。
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH"`.mom\"" || true
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld) # 使用 xcrun momc 将 .xcdatamodeld 文件编译成 .momd 文件。
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd\"" || true
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd"
      ;;
    *.xcmappingmodel) # 使用 xcrun mapc 将 .xcmappingmodel 文件编译成 .cdm 文件。
      echo "xcrun mapc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm\"" || true
      xcrun mapc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm"
      ;;
    *.xcassets) # 将 .xcassets 文件路径添加到 XCASSET_FILES 数组中。
      ABSOLUTE_XCASSET_FILE="$RESOURCE_PATH"
      XCASSET_FILES+=("$ABSOLUTE_XCASSET_FILE")
      ;;
    *) # 其他文件：将资源路径输出，并将资源路径添加到 $RESOURCES_TO_COPY 文件中。
      echo "$RESOURCE_PATH" || true
      echo "$RESOURCE_PATH" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
if [[ "$CONFIGURATION" == "Debug" ]]; then # 根据构建配置的不同，将指定的资源文件, 通过install_resource 命令将复制到目标构建目录中，以供构建进程使用。这些资源文件可能是依赖库中的资源，或者是项目中的自定义资源。
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TestLibrary/TestLibrary.bundle"
  install_resource "${PODS_ROOT}/TestLibrary2/TestLibrary2/Assets/TestLibrary2.xcassets"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets/Contents.json"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets/Name-XCAI.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets/Name-XCAI.imageset/Name-XCAI.png"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets/Name-XCAI.imageset/Name-XCAI@2x.png"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets/Name-XCAI.imageset/Name-XCAI@3x.png"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets/Name-XCAI.imageset"
fi
if [[ "$CONFIGURATION" == "Release" ]]; then
  install_resource "${PODS_CONFIGURATION_BUILD_DIR}/TestLibrary/TestLibrary.bundle"
  install_resource "${PODS_ROOT}/TestLibrary2/TestLibrary2/Assets/TestLibrary2.xcassets"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets/Contents.json"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets/Name-XCAI.imageset/Contents.json"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets/Name-XCAI.imageset/Name-XCAI.png"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets/Name-XCAI.imageset/Name-XCAI@2x.png"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets/Name-XCAI.imageset/Name-XCAI@3x.png"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets"
  install_resource "${PODS_ROOT}/../../XCAssetsIssueDemo/Assets/Resouces.xcassets/Name-XCAI.imageset"
fi

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}" # 创建目标构建目录中的资源文件夹。
rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}" # 使用rsync命令将资源文件从源位置复制到目标构建目录中。
if [[ "${ACTION}" == "install" ]] && [[ "${SKIP_INSTALL}" == "NO" ]]; then # 如果 ACTION 环境变量的值为 "install"，并且 SKIP_INSTALL 环境变量的值为 "NO"
  mkdir -p "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
rm -f "$RESOURCES_TO_COPY" # 删除之前创建的资源文件列表

# 如果存在 WRAPPER_EXTENSION 环境变量的值，并且 xcrun --find actool 命令可以找到 actool，并且 XCASSET_FILES 数组不为空
if [[ -n "${WRAPPER_EXTENSION}" ]] && [ "`xcrun --find actool`" ] && [ -n "${XCASSET_FILES:-}" ]
then
  # Find all other xcassets (this unfortunately includes those of path pods and other targets).
  OTHER_XCASSETS=$(find -L "$PWD" -iname "*.xcassets" -type d) # 查找所有的 .xcassets 文件，并将其存储在 OTHER_XCASSETS 变量中。
  while read line; do 
    if [[ $line != "${PODS_ROOT}*" ]]; then
      XCASSET_FILES+=("$line")
    fi
  done <<<"$OTHER_XCASSETS" # 遍历 OTHER_XCASSETS 中的每个文件路径，如果该文件路径不是以 ${PODS_ROOT} 开头，则将其添加到 XCASSET_FILES 数组中。

  if [ -z ${ASSETCATALOG_COMPILER_APPICON_NAME+x} ]; then #如果 ASSETCATALOG_COMPILER_APPICON_NAME 变量未定义，则调用 xcrun actool 命令来编译和压缩 .xcassets 文件，并将其输出到目标构建目录中的资源文件夹。
    printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${!DEPLOYMENT_TARGET_SETTING_NAME}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  else # 如果 ASSETCATALOG_COMPILER_APPICON_NAME 变量已定义，则在编译 .xcassets 文件时指定应用程序图标，并将相关信息输出到临时目录中的信息属性列表文件。
    printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${!DEPLOYMENT_TARGET_SETTING_NAME}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}" --app-icon "${ASSETCATALOG_COMPILER_APPICON_NAME}" --output-partial-info-plist "${TARGET_TEMP_DIR}/assetcatalog_generated_info_cocoapods.plist"
  fi
fi
```

---

explanation `[ -z ${ASSETCATALOG_COMPILER_APPICON_NAME+x} ]`

1. -z：这是条件测试运算符，用于检查给定字符串是否为空。
2. 在`${ASSETCATALOG_COMPILER_APPICON_NAME+x}`中，x是一个占位符。它可以是任何非空字符串，没有特定的含义。在这里，它被用作一个标记，用于判断环境变量ASSETCATALOG_COMPILER_APPICON_NAME是否已定义。
`${ASSETCATALOG_COMPILER_APPICON_NAME+x}`的含义是，如果ASSETCATALOG_COMPILER_APPICON_NAME已定义，那么整个表达式将被替换为x（即非空字符串），否则，整个表达式将被替换为空字符串。
使用`${variable+value}`的语法是一种扩展语法，用于在变量已定义时提供一个备用值。在这个特定的条件测试中，我们不关心实际的备用值是什么，只要它不为空即可。因此，x可以是任何非空字符串，它只是用作一个占位符，以表示变量已定义。
3. 这是条件测试结构的标记，在条件测试中使用。

---

explanation `ASSETCATALOG_COMPILER_APPICON_NAME`

ASSETCATALOG_COMPILER_APPICON_NAME 是一个环境变量，其含义可以根据上下文和使用的上游工具而有所不同。通常情况下，它用于指定应用程序在 Asset Catalog 中使用的应用程序图标的名称。

![ASSETCATALOG_COMPILER_APPICON_NAME](/assets/img/2023-10-27-CocoaPodsSourceCode1.jpg
