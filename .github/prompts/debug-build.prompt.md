---
description: 'Debug Jekyll build failures and common issues'
---

# Debug Jekyll Build Issues

Help diagnose and fix Jekyll build problems.

## Quick Diagnostics

Run these commands to identify the issue:

```bash
# Check Jekyll configuration
bundle exec jekyll doctor

# Build with detailed error trace
bundle exec jekyll build --trace

# Build with verbose output
bundle exec jekyll build --verbose
```

## Common Issues & Solutions

### 1. Port Already in Use
**Error**: `Address already in use - bind(2) for 127.0.0.1 port 4000`
```bash
# Kill existing Jekyll process
pkill -f jekyll
# Or use different port
bundle exec jekyll serve --port 4001
```

### 2. Sass/CSS Compilation Errors
**Error**: Sass deprecation warnings or compilation failures
- Update Chirpy theme: `bundle update jekyll-theme-chirpy`
- Deprecation warnings are non-fatal (theme handles them)

### 3. Liquid Template Errors
**Error**: `Liquid Exception: ...`
- Check for unclosed `{% %}` or `{{ }}` tags
- Escape literal curly braces with `{% raw %}...{% endraw %}`
- Verify variable names exist

### 4. Frontmatter Parsing Errors
**Error**: `YAML Exception reading...`
- Ensure valid YAML syntax in frontmatter
- Quote strings with special characters: `title: "Title: With Colon"`
- No tabs, only spaces for indentation

### 5. Date Mismatch
**Issue**: Post not appearing
- Verify filename date matches `date:` in frontmatter
- Future dates won't appear without `--future` flag

### 6. Missing Dependencies
**Error**: `Could not find gem...`
```bash
bundle install
# If still failing:
rm Gemfile.lock
bundle install
bundle lock --add-platform x86_64-linux
```

### 7. Config Not Reloading
**Issue**: Changes to `_config.yml` not appearing
- Jekyll does NOT hot-reload _config.yml
- Stop server (Ctrl+C) and restart: `bundle exec jekyll serve`

## Clean Rebuild

When all else fails:
```bash
bundle exec jekyll clean
rm -rf .jekyll-cache .jekyll-metadata
bundle exec jekyll build --trace
```
