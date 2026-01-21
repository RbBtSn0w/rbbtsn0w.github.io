---
description: Create a new blog post with proper frontmatter and structure
---

# New Post Workflow

Use `/new-post` to create a properly formatted blog article.

## 1. Gather Requirements

Ask the user for:
- Post title
- Main topic/category
- Brief description for SEO

## 2. Create Post File

Generate filename: `YYYY-MM-DD-title-slug.md`

```bash
# Today's date
date +%Y-%m-%d
```

Create file in `_posts/` with frontmatter:

```yaml
---
layout: post
title: "Your Title Here"
date: YYYY-MM-DD
categories: [Category1, Category2]
tags: [tag1, tag2, tag3]
description: "SEO description (150-160 chars)"
---

Content goes here...
```

## 3. Set Categories and Tags

**Categories** (choose 1-2):
- `iOS`, `macOS`, `Xcode`, `CocoaPods`
- `Flutter`, `Project`, `Jekyll`
- `Crash`, `AI`

**Tags** (choose 3-8):
- All lowercase
- Hyphen-separated: `code-signing`, `state-management`
- Avoid duplicating category names

## 4. Add Content Structure

Recommended structure:
```markdown
## Introduction

Brief overview of the topic.

## Main Content

### Subsection 1

Details...

### Subsection 2

Details...

## Conclusion

Summary and takeaways.

## References

- [Link 1](url)
- [Link 2](url)
```

## 5. Verify Post

// turbo
```bash
bundle exec jekyll serve --drafts
```

Check:
- Post appears in list
- Frontmatter renders correctly
- Images display properly
- Code blocks have syntax highlighting
- Mermaid diagrams work (if used)

## 6. Finalize

// turbo
```bash
git add _posts/
git commit -m "post: [post title]"
```
