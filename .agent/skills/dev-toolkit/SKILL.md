---
name: dev-toolkit
description: Development commands and utilities for Jekyll Chirpy blog
---

# Dev Toolkit

Essential CLI commands for local development, testing, building, and deployment.

## Development Server

```bash
# Start development server with live reload
bundle exec jekyll serve

# Start with drafts visible
bundle exec jekyll serve --drafts

# Use different port (default: 4000)
bundle exec jekyll serve --port 4001

# Verbose output for debugging
bundle exec jekyll serve --verbose
```

Access at: `http://localhost:4000`

## Build Commands

```bash
# Production build
JEKYLL_ENV=production bundle exec jekyll build

# Development build
bundle exec jekyll build

# Incremental build (faster for large sites)
bundle exec jekyll build --incremental

# Build with trace for debugging
bundle exec jekyll build --trace
```

## Clean & Reset

```bash
# Remove generated files
bundle exec jekyll clean

# Full reset
bundle exec jekyll clean && bundle exec jekyll build
```

## Dependency Management

```bash
# Install dependencies
bundle install

# Update all gems
bundle update

# Update specific gem
bundle update jekyll-theme-chirpy

# Check outdated gems
bundle outdated

# Add Linux platform (for GitHub Actions compatibility)
bundle lock --add-platform x86_64-linux
```

## Testing & Validation

```bash
# Run HTMLProofer (after build)
bundle exec htmlproofer ./_site \
  --disable-external \
  --allow-hash-href \
  --ignore-urls "/^http:\/\/localhost/"

# Quick syntax check
bundle exec jekyll doctor
```

## Useful Shortcuts

```bash
# Count posts
ls _posts/ | wc -l

# Find posts by category
grep -l "categories:.*iOS" _posts/*.md

# Check last modified
git log -1 --format=%cd
```

## Pre-commit Hook

The project uses pre-commit hooks. If hook fails:

```bash
# Check Ruby version
ruby -v

# Reinstall dependencies
bundle install

# Clean and rebuild
bundle exec jekyll clean && bundle exec jekyll build
```
