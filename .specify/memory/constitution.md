<!--
Sync Impact Report:
- Version change: v1.0.0 -> v1.1.0
- List of modified principles:
  - II. Structured Organization: Expanded with specific YAML frontmatter and file naming rules.
  - V. Performance & SEO: Added specific alt-text and description requirements.
- Added sections: Technical Style Guide, Runtime Guidance.
- Removed sections: None.
- Templates requiring updates (✅ updated / ⚠ pending):
  - .specify/templates/plan-template.md ⚠
  - .specify/templates/tasks-template.md ⚠
- Follow-up TODOs: Update Plan and Tasks templates for Jekyll paths.
-->
# RbBtSn0w's Technical Blog Constitution

## Core Principles

### I. Content-First
Articles MUST be technically accurate and focus on iOS/macOS development, programming learning, or MTB life. High-traffic posts MUST include a `description` field in the front matter to improve SEO and social sharing. Content MUST be written in Markdown and can include Mermaid diagrams for technical illustrations.

### II. Structured Organization
The project MUST adhere to strict file naming conventions (`_posts/YYYY-MM-DD-title.md`). The `date` in front matter MUST match the filename date. Categories and tags MUST follow the established taxonomy: lowercase, hyphenated, and accurately reflecting the technical domain (3–8 tags per post).

### III. Automated Validation
Every change MUST pass the automated build and testing suite before deployment. This includes Jekyll build verification and HTMLProofer checks for link validity and content integrity. GitHub Actions serves as the definitive gate for all production deployments.

### IV. Visual Consistency
The site MUST maintain the aesthetic and functional standards of the Chirpy theme. Any customizations MUST be responsive and compatible with the theme's core structure. Static assets like images MUST be organized within dedicated, post-specific directories under `/assets/img/post/`.

### V. Performance & SEO
Site performance MUST be prioritized, including optimized asset loading and PWA support. SEO metadata MUST be maintained through correct front matter usage. Every image MUST include descriptive alt text.

## Technical Style Guide
- **Frontmatter**: MUST use 2-space indentation.
- **Headers**: MUST use ATX-style headers (`##`, `###`).
- **Code**: MUST use fenced code blocks with language identifiers.
- **Lines**: Limit line length to 100 characters where practical.
- **Includes**: Follow semantic HTML5 and Liquid template syntax.

## CI/CD & Deployment
The deployment workflow is fully automated. Push to `main` triggers the `pages-deploy` GitHub Action. Local development MUST use `bundle exec jekyll serve` to verify changes before committing.

## Runtime Guidance
Agent behaviors MUST align with the detailed rules in `.github/instructions/code-style.instructions.md`. This constitution serves as the high-level policy, while the instruction file provides granular formatting guidance.

## Governance
This constitution supersedes all other documentation in matters of core project principles. Amendments MUST be documented with a version bump. Compliance is enforced through automated CI gates and manual code reviews.

**Version**: 1.1.0 | **Ratified**: 2026-03-03 | **Last Amended**: 2026-03-03
