---
description: 'Create a new blog post with proper frontmatter and file structure'
---

# New Blog Post Creation

Create a new blog post for this Jekyll Chirpy blog following all conventions.

## Required Information

Before creating the post, I need:
1. **Title**: The article title
2. **Category**: Choose from `iOS`, `macOS`, `Xcode`, `CocoaPods`, `Flutter`, `Project`, `Jekyll`, `Crash`, `AI`
3. **Tags**: 3-8 lowercase, hyphenated tags (e.g., `swift-concurrency`, `xcode-tips`)
4. **Description**: One-line SEO summary (optional but recommended)

## Post Template

Create file at `_posts/YYYY-MM-DD-title-slug.md`:

```yaml
---
layout: post
title: "Your Title Here"
date: YYYY-MM-DD
categories: [Category]
tags: [tag1, tag2, tag3]
description: "Brief SEO description"
---

## Introduction

[Start with level 2 heading - title is automatically h1]

## Main Content

Your content here...

## Conclusion

Summary and next steps.
```

## Checklist

- [ ] Filename matches date in frontmatter
- [ ] Body starts with `##` (not `#`)
- [ ] Categories are Title Case from approved list
- [ ] Tags are lowercase and hyphenated
- [ ] 3-8 tags included
- [ ] Description field for SEO
- [ ] Code blocks have language identifiers
