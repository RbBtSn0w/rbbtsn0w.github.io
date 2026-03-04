# Jekyll/Chirpy Frontmatter Specification

This document defines the SEO-optimized Frontmatter conventions for the blog at [rbbtsn0w.me](https://rbbtsn0w.me), built with `jekyll-theme-chirpy`.

---

## Required Fields

### `layout`
- **Value**: `post` (for blog posts)
- **Note**: Inherited from `_config.yml` defaults — usually no need to set explicitly.

### `title`
- **SEO Rules**:
  - **Length**: ≤ 60 characters (Google truncates at ~60 chars in SERPs)
  - **Primary keyword**: Must appear in the title, ideally near the beginning
  - **Compelling**: Use power words or value promises to increase CTR
- **Examples**:
  - ✅ `"MCP Apps 实战：三步为工具添加交互式 UI"` (keyword upfront, value promise)
  - ❌ `"我最近试了一些新东西关于 MCP"` (vague, keyword buried)

### `date`
- **Format**: `YYYY-MM-DD` or `YYYY-MM-DD HH:MM:SS +TIMEZONE`
- **Example**: `2026-01-27 16:40:00 +0800`

### `categories`
- **Rules**:
  - Use 1-2 categories per post
  - Choose from the established site taxonomy to maintain consistency
  - Categories are used in URL generation (`/categories/:name/`)
- **Current site categories** (maintain this list):
  - `AI`, `Project`, `Xcode`, `iOS`, `Life`, `Web`, `Tools`
- **Example**: `[AI, Project]`

### `tags`
- **Rules**:
  - Use 3-6 tags per post
  - Include the primary keyword and 1-2 secondary keywords as tags
  - Use lowercase, hyphenated format for multi-word tags
  - Tags are used in archive pages (`/tags/:name/`)
- **Example**: `[mcp, mcp-apps, agentic-ui, javascript]`

### `description`
- **SEO Rules**:
  - **Length**: 120-160 characters (Google truncates meta descriptions at ~160 chars)
  - **Primary keyword**: Must appear naturally in the description
  - **Value promise**: Tell the reader exactly what they'll learn or gain
  - **Action-oriented**: Use verbs like "learn", "discover", "build", "solve"
- **Examples**:
  - ✅ `"Model Context Protocol (MCP) 迎来首个官方扩展：MCP Apps。本文将带你了解如何通过简单的步骤，为你现有的 MCP 工具添加交互式 UI。"` (154 chars, keyword present, clear promise)
  - ❌ `"这篇文章讲了一些关于 MCP 的内容。"` (vague, no value promise)

---

## Recommended Fields

### `image`
- **Purpose**: Cover image for social sharing (Open Graph) and in-post visual
- **Format**:
  ```yaml
  image:
    path: /assets/img/post/<slug>/cover.png
    alt: "Descriptive text including relevant keyword"
  ```
- **Note**: Even if not set, `jekyll-seo-tag` will fallback to site defaults. Setting it improves social sharing CTR.

### `pin`
- **Value**: `true` to pin the post to the home page
- **Use**: Only for evergreen, high-traffic content

### `math` / `mermaid`
- **Value**: `true` to enable MathJax or Mermaid rendering
- **Note**: Only set when the post actually uses these features

---

## Permalink / Slug Strategy

The site uses the permalink pattern: `/posts/:title/` (configured in `_config.yml`).

- **Slug** is derived from the filename: `YYYY-MM-DD-<slug>.md`
- **Rules**:
  - Keep the slug **short and keyword-rich**: `/posts/mcp-apps-guide/` not `/posts/my-article-about-mcp-apps-and-how-to-use-them/`
  - Use **hyphens** as separators (not underscores)
  - **Avoid dates** in the slug (the date is already in the filename)
  - **Avoid stop words** (a, the, and, or, is, in, to) unless they're part of a keyword phrase
- **Examples**:
  - ✅ `2026-01-27-mcp-apps-guide.md` → `/posts/mcp-apps-guide/`
  - ❌ `2026-01-27-my-article-about-how-to-create-mcp-apps-in-2026.md`

---

## Complete Example

```yaml
---
layout: post
title: "从文本到交互：如何将你的 MCP Server 升级为 MCP App"
date: 2026-01-27 16:40:00 +0800
categories: [AI, Project]
tags: [mcp, mcp-apps, agentic-ui, javascript]
description: "MCP 迎来首个官方扩展：MCP Apps。本文带你通过三步，为现有 MCP 工具添加交互式 UI。"
image:
  path: /assets/img/post/mcp-apps-guide/cover.png
  alt: "MCP Apps architecture showing tool-to-UI flow"
---
```

---

## Anti-Patterns

| Problem | Why it hurts SEO | Fix |
|---------|-----------------|-----|
| Title > 60 chars | Gets truncated in search results, lower CTR | Shorten and front-load keyword |
| No `description` | Google auto-generates one (often poorly) | Always write a manual description |
| Generic tags like `tech`, `blog` | Too broad, no search value | Use specific, searchable terms |
| Same categories on every post | Dilutes category archive value | Use categories that genuinely group content |
| No `image` | Poor social sharing appearance | Add cover image for public posts |
