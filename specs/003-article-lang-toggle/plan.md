# Implementation Plan: Article Language Toggle

**Branch**: `003-article-lang-toggle` | **Date**: 2026-03-31 | **Spec**: [specs/003-article-lang-toggle/spec.md](spec.md)

## Summary

This feature adds an automated build-time translation pipeline to the Jekyll blog. It pre-translates Chinese articles into English JSON deltas using a private **Google Apps Script (GAS) Proxy**, ensuring high performance, zero API key exposure, and a cost-free experience for the user.

## Technical Context

- **Language/Version**: JavaScript (ES6+), Node.js (v20+), Ruby (Jekyll 4.4), Liquid.
- **Primary Dependencies**: Google Apps Script (Internal LanguageApp), GitHub Actions.
- **Architecture**: Build-time "Delta Cache" (Markdown -> GAS -> JSON).
- **Storage**: `localStorage` for user preference persistence.
- **Security**: Token-based authorization for the GAS proxy; Secrets managed via GitHub repository settings.
- **Performance**: Instant client-side switching via JSON fetching; Content hashing ensures efficient builds.

## Project Structure

### Documentation (this feature)

```text
specs/003-article-lang-toggle/
├── plan.md              # This file
├── research.md          # Implementation strategy & GAS Pivot
├── data-model.md        # State management (localStorage)
├── quickstart.md        # How to enable the feature (GAS setup)
└── tasks.md             # Implementation steps (T001-T025)
```

### Source Code (repository root)

```text
_includes/
└── metadata-hook.html   # Entry point & Config injection

assets/
├── js/
│   └── translation.js  # Toggle logic & JSON fetching
├── css/
│   └── translation.css # Button & Loading overlay styles
└── translations/
    └── [slug].json     # Pre-built translation deltas
    
tools/
└── translate-posts.js  # Node.js build-time translation engine
```

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Build-time Proxy | Security & Performance | Client-side keys are easily stolen; Real-time API calls are slow and expensive. |
| Custom Node script | Jekyll limitations | Jekyll/Liquid cannot perform external API calls during the local build phase directly. |
