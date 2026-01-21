---
trigger: glob
globs: "{md,markdown,html,scss,css,yml,yaml,rb}"
description: Code style conventions for Markdown content and Jekyll configuration
---

# Code Style Guide

## Markdown Content

### Frontmatter Format (YAML)
```yaml
---
layout: post
title: "Article Title"
date: YYYY-MM-DD
categories: [iOS, Swift]
tags: [swift, debugging, uikit]
description: "SEO-friendly summary"
mermaid: true  # optional
---
```

### Writing Conventions
- Use ATX-style headers (`#`, `##`, `###`)
- Use fenced code blocks with language identifier
- Limit line length to 100 characters for readability
- Use reference-style links for repeated URLs
- Include alt text for all images

### Image Paths
```markdown
# Post-specific images
![Alt text](/assets/img/post/YYYY-MM-DD-title/image.png)

# Shared images
![Alt text](/assets/img/common/image.png)
```

## YAML Configuration

- Use 2-space indentation
- Quote strings containing special characters
- Use `>-` for multi-line strings without trailing newlines
- Group related settings with comments

## HTML Includes

- Use semantic HTML5 elements
- Include accessibility attributes (`aria-*`, `alt`)
- Follow Liquid template syntax: `{{ variable }}`, `{% if condition %}`

## SCSS/CSS

- Follow BEM naming convention when adding custom styles
- Place custom styles in `assets/css/style.scss`
- Use CSS custom properties for theme values
