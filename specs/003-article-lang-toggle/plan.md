# Implementation Plan: Article Language Toggle

**Branch**: `003-article-lang-toggle` | **Date**: 2026-03-31 | **Spec**: [specs/003-article-lang-toggle/spec.md](file:///Users/snow/Documents/GitHub/rbbtsn0w.github.io/specs/003-article-lang-toggle/spec.md)
**Input**: Feature specification from `/specs/003-article-lang-toggle/spec.md`

## Summary

This feature adds a language translation toggle (CN/EN) to article pages on the Jekyll blog. It leverages the Google Cloud Translation API to perform dynamic, on-the-fly translation of the article body while preserving technical formatting (code blocks, Mermaid diagrams).

## Technical Context

**Language/Version**: JavaScript (ES6+), Ruby (Jekyll 4.4), Liquid.  
**Primary Dependencies**: Google Cloud Translation API v2/v3, Chirpy Theme.  
**Storage**: `localStorage` for user preference persistence.  
**Testing**: Manual cross-browser testing, Jekyll build verification.  
**Target Platform**: Web browsers (Chrome, Safari, Firefox).  
**Project Type**: Jekyll Static Blog Extension.  
**Performance Goals**: Translation initiation under 500ms; No visible layout shift on toggle.  
**Constraints**: API character limits/costs; Static site security (API key exposure).  
**Scale/Scope**: Universal across all blog posts (`_posts`).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Principle I: Content-First**: ✅ Research ensures code blocks and Mermaid diagrams are preserved.
- **Principle IV: Visual Consistency**: ✅ Button design will follow Chirpy's UI patterns (using theme variables).
- **Principle V: Performance & SEO**: ✅ Translation is dynamic (client-side), not impacting SEO indexed content (which remains original Chinese). Loading states will prevent CLS.

## Project Structure

### Documentation (this feature)

```text
specs/003-article-lang-toggle/
├── plan.md              # This file
├── research.md          # Implementation strategy & API selection
├── data-model.md        # State management (localStorage)
├── quickstart.md        # How to enable the feature
└── tasks.md             # Implementation steps
```

### Source Code (repository root)

```text
_includes/
└── metadata-hook.html   # Entry point for custom JS/CSS

assets/
├── js/
│   └── translation.js  # Translation logic & API wrapper
└── css/
    └── translation.css # Button & loading state styles
```

**Structure Decision**: Chirpy theme extension via root-level file overrides and static assets.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Client-side API usage | Static hosting (GitHub Pages) | No backend available for proxy; domain-restricting the key is the only viable alternative for "Professional API" request. |
