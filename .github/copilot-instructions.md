# Copilot instructions for this repository

Purpose: make AI coding agents productive in this Jekyll + Chirpy blog without guesswork. Keep edits source-only and reproducible.

Big picture
- Static site built with Jekyll 4.x and theme jekyll-theme-chirpy (~> 7.4). Ruby 3.2, Bundler-managed. PWA enabled; server set to Puma.
- Source of truth lives in:
  - `_posts/` markdown posts named `YYYY-MM-DD-title.md` (front matter required).
  - `_tabs/` site pages (About, Archives, Categories, Tags).
  - `_data/` YAML for structured content (e.g., `contact.yml`, `share.yml`).
  - `assets/` for images and overrides (e.g., `assets/img/**`).
  - `_plugins/posts-lastmod-hook.rb` adds `last_modified_at` from git history.
- Generated site output is `_site/` — do not edit or rely on it for diffs. All changes must be in source folders; CI rebuilds on deploy.

Conventions that matter
- Posts use front matter defaults from `_config.yml`:
  - `layout: post`, `comments: true`, `toc: true`, `permalink: /posts/:title/`.
  - Categories and tags are archived by `jekyll-archives` at `/categories/:name/` and `/tags/:name/`.
- Front matter guidelines (see examples in `_posts/`):
  - `date` must match filename date; include `description` for SEO; optional `mermaid: true`.
  - Categories are title-cased domain buckets (e.g., `iOS`, `Jekyll`); tags are lowercase, hyphenated (e.g., `code-signing`).
- Images: prefer absolute paths under `assets/img/post/YYYY-MM-DD-title/`.
- Domain and Pages: `CNAME` and `_config.yml:url` must agree (`https://rbbtsn0w.me`).

Local dev and builds
- First-time setup: `bundle install`.
- Develop: `bundle exec jekyll serve` then browse http://localhost:4000.
- Build (production): `JEKYLL_ENV=production bundle exec jekyll build`.
- Maintenance: `bundle update`, optionally `bundle lock --add-platform x86_64-linux` when changing gems (keeps CI happy).
- If `_config.yml` changes, restart the dev server (Jekyll doesn’t hot-reload that file).

CI/CD and tests (what runs where)
- Workflow `.github/workflows/pages-deploy.yml`:
  - Ruby 3.2, Bundler cache. Builds with `bundle exec jekyll build`.
  - Validates with `htmlproofer` (internal links) and `jekyll doctor`.
  - Uploads artifact and deploys to GitHub Pages on `main`/`master`.
- Scheduled maintenance (`maintenance.yml`) checks outdated gems weekly and validates links sample.
- Failure notifications (`failure-notification.yml`) open an issue on failed deploys.

Safe change patterns for agents
- Create a new post: copy a similar file in `_posts/`, keep filename/date alignment, add categories/tags, and optional `description`/`mermaid`.
- Don’t touch `_site/`; never commit build artifacts on purpose. Edit sources only.
- For navigation pages, edit `_tabs/*.md`; for data-driven bits, edit `_data/*.yml`.
- When modifying theme behavior, prefer configuration in `_config.yml` or light CSS/JS overrides in `assets/` over vendoring theme code.
- The plugin `posts-lastmod-hook.rb` uses git history; avoid operations that erase history for posts you want accurate `last_modified_at` on.

Key files to know
- `_config.yml` — global config, archives, permalink scheme, PWA, kramdown/rouge settings.
- `Gemfile` — Jekyll/Chirpy/html-proofer dependencies.
- `_plugins/posts-lastmod-hook.rb` — auto-populates `last_modified_at`.
- `.github/workflows/*.yml` — build, deploy, maintenance, failure notification.

Example post header
```yaml
---
layout: post
title: "Your Title"
date: 2024-03-18
categories: [Jekyll]
tags: [github-pages, https]
description: "Short SEO summary"
mermaid: true
---
```

Questions for maintainers
- Is `_site/` intentionally versioned or can it be ignored going forward? (Guidance affects cleanup tasks.)
- Any additional content rules (e.g., preferred categories/tags list) beyond what’s visible now?
