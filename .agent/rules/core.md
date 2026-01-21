---
trigger: always_on
description: Core project instructions for Jekyll Chirpy blog development
---

# Core Project Rules

## Tech Stack

- **Static Site Generator**: Jekyll 4.x
- **Theme**: Chirpy 7.4+ (modern responsive blog theme)
- **Language**: Ruby 3.2+
- **Package Manager**: Bundler 2.4+
- **Testing**: HTMLProofer 5.1 (link validation)
- **Deployment**: GitHub Pages + GitHub Actions
- **Content**: Markdown + Mermaid diagrams
- **CDN/SSL**: Cloudflare (custom domain)

## Architecture Patterns

1. **Jekyll Standard Structure**:
   - `_posts/` - Blog articles (YYYY-MM-DD-title.md format)
   - `_tabs/` - Navigation pages
   - `_data/` - Site data in YAML
   - `_plugins/` - Custom Ruby plugins
   - `_includes/` - Reusable HTML partials
   - `assets/` - Static files (images, CSS)

2. **Chirpy Theme Conventions**:
   - Use frontmatter for metadata (layout, title, date, categories, tags)
   - Follow category/tag taxonomy standards
   - Use `description` field for SEO

3. **Content Standards**:
   - Article filename: `YYYY-MM-DD-title.md`
   - `date` in frontmatter MUST match filename date
   - Categories: `iOS`, `macOS`, `Xcode`, `CocoaPods`, `Flutter`, `Project`, `Jekyll`, `Crash`, `AI`
   - Tags: lowercase, hyphen-separated (e.g., `code-signing`)

## Critical Constraints

- **Never** modify files in `_site/` directly (generated output)
- **Always** restart server after modifying `_config.yml`
- **Always** use `bundle exec` prefix for Jekyll commands
- Image paths start with `/assets/img/`
- Maintain 3-8 tags per article
- Avoid duplicate categories and tags
