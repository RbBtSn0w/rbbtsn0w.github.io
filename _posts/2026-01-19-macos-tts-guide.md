---
layout: post
title: "macOS 本地文本转语音（TTS）实践：从 say 命令到音质优化"
date: 2026-01-19
categories: [macOS]
tags: [tts, say, ffmpeg, markdown, perl]
description: "在 macOS 上完全离线把 Markdown 转成高质量中文 MP3：避坑 sed 兼容性、正确语音名、Premium 声音下载与完整脚本。"
---

# macOS 本地文本转语音（TTS）实践：从 `say` 命令到音质优化

在这篇博客中，我分享一次完整的实践经历：如何利用 macOS 自带工具，将一个本地的 Markdown 中文文档转换成一个 MP3 音频文件。过程不止“能跑”，还要“好听”：我们踩过 BSD `sed` 的兼容性坑、绕过 `say` 的语音名陷阱，最后用系统“优化版”语音把音质拉满。

## 你将获得什么

- 一个在 macOS 上完全离线的 Markdown→MP3 工作流
- 避坑清单：BSD `sed` 兼容性、语音名、音质升级
- 一键脚本，可复用、可改造（支持自定义语速/停顿）

## 先决条件

- macOS（建议 macOS 13+，但更早版本亦可）
- `perl`（macOS 自带）
- `ffmpeg`（如未安装，使用 Homebrew 安装）

```bash
# 安装 ffmpeg（如尚未安装）
brew install ffmpeg
```

## 快速开始（最小可用）

把 `content.md` 转成中文 MP3（假设系统已安装中文语音“Tingting”或 Premium 语音）：

```bash
# 1) 从 Markdown 提取纯文本（使用 Perl，兼容 BSD/macOS）
perl -pe 's/^#+ //; s/\*\*(.*?)\*\*/$1/g; s/\*(.*?)\*/$1/g; s/\[(.*?)\]\(.*?\)/$1/g' content.md > /tmp/text.txt

# 2) 列出可用语音并确认中文（可选）
say -v '?' | grep 'zh'

# 3) 生成 AIFF 并转 MP3（以 Tingting 为例）
say -v "Tingting" -f /tmp/text.txt -o /tmp/out.aiff
ffmpeg -y -i /tmp/out.aiff -ar 44100 -ac 2 -b:a 192k output.mp3
```

## 常见坑与解决方案

### 1) BSD `sed` 的正则兼容性

报错示例：

```
sed: RE error: repetition-operator operand invalid
```

原因：macOS 的 `sed` 是 BSD 版本，扩展正则（如 `+`、非贪婪 `?`）在不同场景下行为与 GNU 有差异。

解决：使用更稳的 `perl` 正则处理 Markdown 到纯文本。

```bash
perl -pe 's/^#+ //; s/\*\*(.*?)\*\*/$1/g; s/\*(.*?)\*/$1/g; s/\[(.*?)\]\(.*?\)/$1/g' content.md > /tmp/text.txt
```

### 2) 中文没读出来，变成短促英文

常见原因：指定的语音名并不存在，`say` 回退到系统默认英文语音，最终音频很短或内容不完整。

排查：

```bash
say -v '?' | grep 'zh'
```

示例输出（节选）：

```
Tingting            zh_CN    # 你好！我叫婷婷。
```

注意：语音名是 `Tingting`（没有连字符）。拼写错为 `Ting-Ting` 会导致回退到英文。

### 3) 声音“机械”，缺少真实感

原因：部分旧版中文语音自然度有限。

解决：在系统设置中下载“优化版/Premium”语音，然后在 `say` 中使用该语音名。

步骤：
1. 打开“系统设置”→“辅助功能”→“朗读内容”。
2. 在“系统声音”选择“管理声音…”。
3. 找到中文条目，下载带“优化版”或带下载图标的语音。
4. 完成后再次 `say -v '?' | grep zh`，选用带 `(Premium)` 标记的高质量语音。

示例：

```
Yue (Premium)       zh_CN    # 你好！我叫月。
```

## 可复用的一键脚本（带清理与提示）

```bash
#!/bin/bash

# --- 配置 ---
# 从 `say -v "?"` 列表中选择一个高质量的中文语音
VOICE_NAME="Yue (Premium)"   # 或 "Tingting"，依据你的系统可用语音
INPUT_FILE="content.md"
OUTPUT_FILE="output.mp3"
TEMP_TEXT="/tmp/tts_text.txt"
TEMP_AIFF="/tmp/tts_out.aiff"
RATE=180  # 语速（可调），常见范围约 140–220


# --- 步骤 1: 提取纯文本 (Perl) ---
echo "1. 从 $INPUT_FILE 提取纯文本…"
perl -pe 's/^#+ //; s/\*\*(.*?)\*\*/$1/g; s/\*(.*?)\*/$1/g; s/\[(.*?)\]\(.*?\)/$1/g' "$INPUT_FILE" > "$TEMP_TEXT"
echo "   - 文本已保存到 $TEMP_TEXT"


# --- 步骤 2: 使用高质量语音生成 AIFF ---
echo "2. 使用语音 '$VOICE_NAME' 生成 AIFF 文件…"
say -r "$RATE" -v "$VOICE_NAME" -f "$TEMP_TEXT" -o "$TEMP_AIFF"
echo "   - AIFF 文件已保存到 $TEMP_AIFF"


# --- 步骤 3: 转换为 MP3 ---
echo "3. 使用 ffmpeg 转换为 MP3…"
ffmpeg -y -i "$TEMP_AIFF" -codec:a libmp3lame -q:a 2 "$OUTPUT_FILE" >/dev/null 2>&1
echo "   - MP3 文件已生成: $OUTPUT_FILE"


# --- 步骤 4: 清理临时文件 ---
echo "4. 清理临时文件…"
rm -f "$TEMP_TEXT" "$TEMP_AIFF"
echo "   - 清理完成。"

echo "任务成功！"
```

说明：上面的 MP3 转换使用 `libmp3lame` 并指定质量因子 `-q:a 2`（约等效 190–220 kbps，主观音质更稳）。如需固定码率，可用 `-b:a 192k`。

## 进阶技巧：语速与停顿更自然

- 语速：用 `-r`（每分钟词数）控制，例如 `-r 160` 更稳重、`-r 200` 更紧凑。
- 停顿：在文本中合适地加入逗号、句号能显著改善节奏；在个别场景可插入合成指令（如 `[[slnc 250]]` 表示约 250ms 静音，兼容性取决于系统语音引擎）。
- 段落：为长文分段朗读并合并音频，能更稳地控制总时长与节奏。

## 结论与启示

1. 工具在不同操作系统/实现上的差异不可忽视：BSD `sed` vs GNU `sed`。
2. 语音名要精确：`Tingting` 而不是 `Ting-Ting`。
3. 善用系统“隐藏宝藏”：下载 **Premium/优化版** 中文语音，音质直线上升。
4. 清楚工具边界：`say` 做 TTS；`ffmpeg` 做编码；正则抽取交给 `perl` 更稳。

把实践打磨成可复用脚本后，你可以很方便地在本地把 Markdown 文档转换为自然度更高的中文语音文件，完全离线、零成本。
