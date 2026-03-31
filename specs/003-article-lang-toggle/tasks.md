# Tasks: Article Language Toggle

**Input**: Design documents from `/specs/003-article-lang-toggle/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

## Phase 1-5: Legacy Development (MVP & Logic)
*Note: These steps established the initial interactive logic, now superseded by the GAS Pivot.*

## Phase P: GitHub Actions & GAS Pivot (Secure & Fast)

**Goal**: Move translation to build-time using GitHub Actions and a secure GAS proxy.

- [x] T021 Create `tools/translate-posts.js` for build-time Markdown-to-JSON engine
- [x] T022 Integrate translation step into `.github/workflows/pages-deploy.yml` with `GOOGLE_APPS_SCRIPT_URL` and `GOOGLE_APPS_SCRIPT_TOKEN` secrets
- [x] T023 Update `_includes/metadata-hook.html` to inject `baseurl`, `marked.js`, and `slug`
- [x] T024 Rewrite `assets/js/translation.js` to fetch pre-translated JSON and render via `marked.js`
- [x] T025 Implement token-based authorization in the GAS proxy and build script
- [x] T026 Add loading overlay support (`.translation-loading`) and fix `user-language` storage key
- [x] T027 [Polish] Remove redundant `api_key` from `_config.yml` and clean up `_includes/translation-toggle.html`

## Final Checkpoint
- [x] End-to-end verification of the GitHub Action pipeline
- [x] Verification of Markdown style preservation (via `marked.js`)
- [x] Security audit of GAS proxy access
