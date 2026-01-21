---
name: 'Dev Toolkit'
description: 'Essential CLI commands for Jekyll Chirpy blog development, testing, and deployment'
---

# Development Toolkit

Essential commands for working with this Jekyll Chirpy blog.

## Environment Setup

```bash
# Install Ruby dependencies
bundle install

# Add Linux platform for GitHub Actions compatibility
bundle lock --add-platform x86_64-linux
```

## Local Development

```bash
# Start development server (http://localhost:4000)
bundle exec jekyll serve

# Start with live reload
bundle exec jekyll serve --livereload

# Start on different port
bundle exec jekyll serve --port 4001

# Start with verbose output for debugging
bundle exec jekyll serve --verbose

# Start with incremental builds (faster rebuilds)
bundle exec jekyll serve --incremental
```

## Building

```bash
# Development build
bundle exec jekyll build

# Production build (minified, optimized)
JEKYLL_ENV=production bundle exec jekyll build

# Build with incremental (faster, but may miss some changes)
bundle exec jekyll build --incremental

# Build with profile information
bundle exec jekyll build --profile

# Build with detailed error trace
bundle exec jekyll build --trace
```

## Cleaning

```bash
# Clean generated files and cache
bundle exec jekyll clean

# Force clean (removes all generated content)
rm -rf _site .jekyll-cache .jekyll-metadata
```

## Testing & Validation

```bash
# Check Jekyll configuration for issues
bundle exec jekyll doctor

# Validate HTML links (requires html-proofer gem)
bundle exec htmlproofer _site \
  --disable-external=true \
  --ignore-urls "/^http:\/\/127.0.0.1/,/^http:\/\/localhost/" \
  --no-enforce-https

# Validate with external links (slower, thorough)
bundle exec htmlproofer _site \
  --ignore-urls "/^http:\/\/127.0.0.1/,/^http:\/\/localhost/"
```

## Dependency Management

```bash
# Check outdated gems
bundle outdated

# Update all gems
bundle update

# Update specific gem
bundle update jekyll-theme-chirpy

# Show installed gems
bundle list

# Show gem info
bundle info jekyll-theme-chirpy
```

## Troubleshooting

```bash
# Kill stuck Jekyll process
pkill -f jekyll

# Check Ruby version
ruby -v

# Check Bundler version
bundle -v

# Reinstall dependencies (fresh start)
rm -rf vendor/bundle
bundle install

# Debug gem conflicts
bundle exec gem list
```

## Git Hooks (if using pre-commit)

```bash
# Run pre-commit checks manually
bundle exec jekyll build && bundle exec htmlproofer _site --disable-external=true
```

## Quick Reference

| Task | Command |
|------|---------|
| Start dev server | `bundle exec jekyll serve` |
| Production build | `JEKYLL_ENV=production bundle exec jekyll build` |
| Clean cache | `bundle exec jekyll clean` |
| Check config | `bundle exec jekyll doctor` |
| Update gems | `bundle update` |
