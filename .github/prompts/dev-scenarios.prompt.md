---
description: 'Common Jekyll development scenarios and solutions'
---

# Development Scenarios

Quick reference for common development tasks.

## Scenario 1: Add Mermaid Diagram to Post

1. Add `mermaid: true` to post frontmatter
2. Use fenced code block with `mermaid` language:
```markdown
\`\`\`mermaid
graph TD
  A[Start] --> B[Process]
  B --> C[End]
\`\`\`
```

## Scenario 2: Update Theme Version

```bash
# Check current version
bundle info jekyll-theme-chirpy

# Update to latest
bundle update jekyll-theme-chirpy

# Lock for CI
bundle lock --add-platform x86_64-linux
```

## Scenario 3: Add New Navigation Tab

1. Create file in `_tabs/` (e.g., `projects.md`)
2. Add frontmatter:
```yaml
---
layout: page
title: Projects
icon: fas fa-code
order: 4
---
```

## Scenario 4: Customize Styling

1. Create `assets/css/style.scss`:
```scss
---
---

@import "main";

// Custom styles below
.custom-class {
  color: #333;
}
```

## Scenario 5: Add Image to Post

1. Create folder: `assets/img/post/YYYY-MM-DD-title/`
2. Add images there
3. Reference in markdown:
```markdown
![Alt text](/assets/img/post/YYYY-MM-DD-title/image.png)
```

## Scenario 6: Fix Broken Internal Links

```bash
# Validate links locally
bundle exec htmlproofer _site --disable-external=true --ignore-urls "/^http:\/\/127.0.0.1/,/^http:\/\/localhost/"
```

## Scenario 7: Preview Draft Posts

1. Create file in `_drafts/` (no date prefix needed)
2. Serve with drafts: `bundle exec jekyll serve --drafts`

## Scenario 8: Add Syntax Highlighting

Use fenced code blocks with language identifier:
```markdown
\`\`\`swift
let greeting = "Hello, World!"
print(greeting)
\`\`\`
```

## Scenario 9: Create Category-Specific Feed

Categories auto-generate at `/categories/category-name/` via jekyll-archives plugin.

## Scenario 10: Optimize for CI

```bash
# Before committing
bundle lock --add-platform x86_64-linux

# Test locally what CI tests
JEKYLL_ENV=production bundle exec jekyll build
bundle exec htmlproofer _site --disable-external=true
```
