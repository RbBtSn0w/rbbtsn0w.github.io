# Copilot Instructions for `rbbtsn0w.github.io`

## Project architecture (Jekyll + Chirpy)
- This repo is a Jekyll blog (`Gemfile`, `_config.yml`) using `jekyll-theme-chirpy`.
- Authoring sources live in `_posts/`, `_tabs/`, `_data/`, `assets/`, and `_plugins/`.
- `_site/` is generated output. Do **not** manually edit files under `_site/`.
- `index.html` is intentionally minimal and delegates to `layout: home`.

## Content model and data flow
- Posts are Markdown files in `_posts/` with filename format `YYYY-MM-DD-title.md`.
- Keep post frontmatter aligned with existing examples, e.g. `_posts/2026-01-20-mastering-copilot-customization.md`:
  - `layout: post`, `title`, `date`, `categories`, `tags`, optional `description`, optional `mermaid: true`.
- `date` must match the filename date.
- Site metadata and integrations are centralized in `_config.yml` (SEO, analytics, comments, PWA, permalink behavior).
- Footer/social contact links come from `_data/contact.yml`.

## Custom logic and non-obvious behavior
- `_plugins/posts-lastmod-hook.rb` sets `last_modified_at` from git history using `git log`.
- Because of that plugin, preserve git history context when possible (CI already uses `fetch-depth: 0`).
- Posts default to permalink pattern `/posts/:title/` via `_config.yml` `defaults`.

## Build, test, and debug workflow
- Use Bundler-managed commands (Ruby 3.2 in CI):
  - `bundle install`
  - `bundle exec jekyll serve` (local preview)
  - `JEKYLL_ENV=production bundle exec jekyll build`
  - `bundle exec jekyll doctor`
  - `bundle exec htmlproofer _site --disable-external`
- CI/CD is defined in `.github/workflows/pages-deploy.yml`:
  - Build + HTMLProofer + `jekyll doctor` on push/PR.
  - Deploy runs only on `main`/`master`.
- Maintenance automation in `.github/workflows/maintenance.yml` checks outdated gems and link health.

## Spec-Kit-first working mode (default)
- This project uses Spec-Kit as the default execution path for most development/content tasks.
- Follow the loop documented in `README.md`: `/speckit.specify` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement` → validation/build.
- For non-trivial changes, prefer updating/creating spec artifacts under `specs/` before direct implementation.
- Keep outputs aligned with constitution-style constraints and task granularity described in the repo workflow docs.

## Repo-specific editing conventions for agents
- Prefer editing source files only; never patch generated artifacts in `_site/`.
- For new/updated posts, follow existing category/tag style (`categories` as YAML array, concise lowercase tags).
- Keep bilingual post patterns consistent when applicable (e.g., `-cn` companion files in `_posts/`).
- When changing config-driven behavior, verify effects in `_config.yml` and at least one representative post.

## AI workflow artifacts present in this repo
- Custom agent/prompt assets exist in `.github/agents/` and `.github/prompts/` (Spec-Kit-oriented workflow).
- Align generated guidance with this repository’s existing Spec-Kit and documentation-first workflow described in `README.md`.
- Long-form article writing should use the dedicated technical-writing capability:
  - Agent: `.github/agents/se-technical-writer.agent.md`
  - Skill package: `.agent/skills/se-technical-writer/`
- For article tasks, prioritize the writing workflow conventions from that capability (structure, tone, templates) while still respecting post frontmatter and Jekyll constraints in this repo.
