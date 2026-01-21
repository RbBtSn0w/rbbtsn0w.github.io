---
applyTo: '**/*.md,**/*.yml,**/*.html'
trigger: always_on
---

# Jekyll Chirpy Blog Code Style Guide

## Overview
This is a Jekyll 4.x blog using the Chirpy 7.4+ theme, deployed to GitHub Pages with Ruby 3.2+.

## File Naming Conventions

### Blog Posts
- **Location**: `_posts/`
- **Format**: `YYYY-MM-DD-title-slug.md` (lowercase, hyphen-separated)
- **Example**: `2024-03-18-flutter-state-management.md`
- **Critical**: The `date` in frontmatter MUST match the filename date

### Images
- **Location**: `assets/img/post/YYYY-MM-DD-title/`
- **Reference**: Use absolute paths: `/assets/img/post/YYYY-MM-DD-title/image.png`

## Frontmatter Standards

### Required Fields
```yaml
---
layout: post
title: "Your Title Here"
date: YYYY-MM-DD
categories: [Category1, Category2]
tags: [tag1, tag2, tag3]
---
```

### Recommended Fields
```yaml
description: "SEO-friendly description for search engines"
mermaid: true  # Enable Mermaid diagrams if used
image:
  path: /assets/img/post/YYYY-MM-DD-title/cover.png
  alt: "Image description"
```

## Content Structure Rules

### Heading Hierarchy
- **CRITICAL**: Body content MUST start with `##` (level 2)
- The `title` frontmatter renders as `<h1>` - do NOT duplicate with `#` in body
- Use sequential heading levels: `##` → `###` → `####`

### Categories (Title Case)
Approved categories: `iOS`, `macOS`, `Xcode`, `CocoaPods`, `Flutter`, `Project`, `Jekyll`, `Crash`, `AI`

### Tags (lowercase, hyphenated)
- Use 3-8 tags per post
- Format: `lowercase-hyphenated` (e.g., `code-signing`, `state-management`)
- Avoid duplicating categories as tags

## Code Examples

### Fenced Code Blocks
Always include language identifier:
```markdown
\`\`\`swift
func example() { }
\`\`\`
```

### Mermaid Diagrams
Enable in frontmatter with `mermaid: true`:
```markdown
\`\`\`mermaid
graph TD
  A[Start] --> B[Process]
  B --> C[End]
\`\`\`
```

## YAML Configuration

### _config.yml Changes
- **Always** restart dev server after modifying `_config.yml`
- Jekyll does NOT hot-reload this file

### Data Files
- Location: `_data/`
- Format: YAML or JSON
- Example: `_data/contact.yml`, `_data/share.yml`

## Forbidden Actions

1. **Never** edit files in `_site/` (generated output)
2. **Never** commit build artifacts
3. **Never** use `#` heading in post body (causes duplicate h1)
4. **Never** mix category formats like `macOS&iOS` (use array)
5. **Never** hardcode URLs that should use `{{ site.baseurl }}`
