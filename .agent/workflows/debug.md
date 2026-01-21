---
description: Debug and fix issues in the Jekyll blog
---

# Debug Workflow

Use `/debug` to troubleshoot and fix issues.

## 1. Identify Symptoms

Gather information:
- Error messages (terminal, browser console)
- When did it start happening?
- Recent changes (`git log -5 --oneline`)

## 2. Check Logs

// turbo
```bash
# Verbose Jekyll output
bundle exec jekyll build --trace
```

// turbo
```bash
# Check for Ruby issues
bundle exec jekyll doctor
```

Common error types:
- **YAML syntax**: Check frontmatter formatting
- **Liquid errors**: Check `{% %}` and `{{ }}` syntax
- **Missing files**: Verify paths in includes/assets
- **Gem conflicts**: Check Gemfile.lock

## 3. Isolate Root Cause

For build failures:
```bash
# Clean build cache
bundle exec jekyll clean
```

For rendering issues:
```bash
# Serve with minimal plugins
bundle exec jekyll serve --safe
```

For dependency issues:
```bash
# Reinstall gems
rm -rf vendor/bundle
bundle install
```

## 4. Apply Fix

Make minimal, targeted changes:
- Fix one issue at a time
- Test after each change
- Document what was wrong

## 5. Verify Fix

// turbo
```bash
# Full clean rebuild
bundle exec jekyll clean && bundle exec jekyll build --trace
```

// turbo
```bash
# Preview locally
bundle exec jekyll serve
```

Confirm:
- Original issue is resolved
- No new issues introduced
- Site builds successfully

## 6. Document Resolution

Commit with descriptive message:
```bash
git commit -m "fix: [describe what was fixed and why]"
```

Share findings with user if issue might recur.
