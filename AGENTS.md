# Agent Constitution

This document serves as the shared, authoritative constitution for all AI agents (Antigravity, Claude Code, GitHub Copilot Workspace, Cursor, etc.) operating in the `rbbtsn0w.github.io` repository.

All agents MUST adhere to the principles, boundaries, and workflows defined herein without exception.

---

## 1. Core Constitutional Principles

### Law 1: Truthful Evidence & Zero Speculation
- **Evidence-backed claims only**: Never present an unverified assertion, fabricated benchmark, fake compiler output, or untested command as fact.
- **Code snippet integrity**: All code snippets (Swift, TypeScript, Python, Ruby, Shell) must be syntactically valid. Real code examples must compile or run in the target environment; conceptual architecture or pseudocode must be explicitly marked as illustrative.
- **Evidence Ladder**:
  1. *Audit & Proposal*: Read-only inspection complete; proposed structure and technical claims recorded; execution halted awaiting developer feedback.
  2. *Locally Verified*: Code examples checked, image paths verified, frontmatter validated, and Jekyll site builds cleanly (`bundle exec jekyll build`).
  3. *Pre-Publish Gate Passed*: Pre-publish script (`python3 .agents/skills/seo-content-optimizer/scripts/prepublish_check.py`) exits with code 0.
  4. *Production Verified*: Successfully rendered and served on GitHub Pages / WeChat Official Account without broken assets, layout shifts, or missing metadata.

### Law 2: Separation of Concerns & Role Handoffs
Agents operate under distinct domain roles. Downstream agents must never corrupt upstream artifacts:
- **`SE Technical Writer`**: Owns technical depth, system architecture, accuracy, code examples, diagrams, and reader flow. Hands off finished technical drafts to the SEO Optimizer.
- **`SEO Content Optimizer`**: Owns Jekyll/Chirpy metadata, single H1 hierarchy, query vocabulary, internal linking, snippet readiness, and pre-publish audit. Must never dilute technical rigor, alter code blocks, or introduce keyword stuffing.
- **`WeChat Media Producer`**: Owns downstream adaptation for WeChat Official Account publishing, including 2.35:1 frosted-glass covers, WeChat draft directory structures (`wechat-drafts/`), link adaptation (footnotes/cards), and sync via `wechat-publisher`. Must never alter canonical blog post semantics.
- **`Site Infrastructure Maintainer`**: Owns Jekyll theme configuration (`_config.yml`), Ruby dependencies (`Gemfile`), GitHub Actions (`.github/workflows/`), and platform stability.

### Law 3: Canonical Blog as Single Source of Truth
- **Single Source of Truth**: The Markdown file at `_posts/YYYY-MM-DD-<slug>.md` is the canonical reference artifact.
- **Downstream Derivations**: WeChat drafts (`wechat-drafts/`), RSS feeds, social cards, and mobile previews are strictly downstream projections. Downstream platform constraints (such as WeChat's lack of arbitrary external `<a>` hyperlinks) must never compromise the canonical blog source.

### Law 4: Git Safety & Human-in-the-Loop Gate
- **Zero Destructive Git Operations**: Agents MUST NEVER execute `git push --force`, `git reset --hard`, `git rebase`, or delete published commits.
- **Zero Autonomous Merging**: Autonomous merging to `master` is strictly prohibited. Final merge and publication decisions belong exclusively to the human maintainer (`rbbtsn0w`).
- **Clean Working Tree**: Always inspect `git status` before starting work to identify and preserve uncommitted changes made by the developer.

### Law 5: High-Risk Boundary & Escalation
Explicit human confirmation is mandatory before:
- Modifying site-wide configuration files (`_config.yml`, `_data/`, `CNAME`).
- Changing package or gem dependencies (`Gemfile`, `Gemfile.lock`, `package.json`).
- Modifying deployment workflows (`.github/workflows/pages-deploy.yml`).
- Renaming, re-dating, or deleting existing published posts under `_posts/`.

---

## 2. Engineering & Content Standards by Role

### A. SE Technical Writer (`se-technical-writer`)
- **No Body-Level `#` H1**: Chirpy's layout automatically generates the page H1 from frontmatter `title`. Never include `# H1` in the post body.
- **Mermaid Flag**: If a post contains a Mermaid code block (```` ```mermaid ````), frontmatter MUST include `mermaid: true`.
- **Zero Unresolved Placeholders**: No `[TODO]`, placeholder text, or dummy data may remain in publish-ready content.
- **Explicit Language Fences**: Every code block must declare an accurate language identifier (e.g. `swift`, `typescript`, `python`, `ruby`, `bash`, `yaml`, `json`). Code blocks containing Liquid-conflicting syntax (such as GitHub Actions `${{ ... }}`) MUST be wrapped in `{% raw %}...{% endraw %}` tags to prevent Jekyll parser errors.
- **Progressive Disclosure**: Structure complex topics logically: Problem Statement → Core Architectural Concept → Implementation Details → Deep Diagnostic / Gotchas → Verification.

### B. SEO Content Optimizer (`seo-content-optimizer`)
- **Canonical Naming Convention**: Blog post files MUST strictly follow `_posts/YYYY-MM-DD-<slug>.md`. The permalink will resolve to `/posts/<slug>/`.
- **Mandatory Frontmatter Fields**:
  ```yaml
  ---
  title: "Clear, Actionable Title"
  date: YYYY-MM-DD HH:MM:SS +/-TTTT
  categories: [TopCategory, SubCategory]
  tags: [tag1, tag2, tag3]
  description: "Concise summary matching reader search intent (120-160 chars)"
  mermaid: true # when mermaid diagrams are present
  image:
    path: /assets/img/post/<slug>/cover.png
  ---
  ```
- **Heading Hierarchy**: Exactly one H1 per page (rendered from frontmatter). Body sections use `##` (H2), sub-sections use `###` (H3). Never skip levels (e.g. H2 directly to H4).
- **Descriptive Anchor Text**: Internal links must use clear contextual descriptions (e.g., `[Swift Concurrency Migration Guide](/posts/swift-6-strict-concurrency-traps/)`). Never use generic text like "click here" or "read more".
- **Validation Script**:
  ```bash
  python3 .agents/skills/seo-content-optimizer/scripts/prepublish_check.py _posts/YYYY-MM-DD-<slug>.md
  ```

### C. WeChat Media Producer (`wechat-publisher`)
- **Cover Image Standard**:
  - Aspect Ratio: 2.35:1 (e.g., 1200 × 510 px or 940 × 400 px).
  - Visual Style: Minimalist frosted-glass background, subtle Apple HIG design language, bold typography, no generic cartoon/robot AI illustrations.
  - Storage Location: `assets/img/post/<slug>/cover.png`.
- **Link Normalization**: Because WeChat blocks external HTTP hyperlinks, external URLs must be gracefully formatted as footnote references or text citations. Internal WeChat links (`mp.weixin.qq.com`) should be styled clearly.
- **Mermaid Diagram Sync**: Diagram rasterization is delegated to `@rbbtsn0w/wechat-markdown` / Kroki PNG rendering to guarantee embedded CJK font clarity before uploading to WeChat CDN.

### D. Site Infrastructure Maintainer
- **Ruby Runtime**: Ruby 3.2.x managed via `rbenv` as specified in [`.ruby-version`](file:///.ruby-version).
- **Site Build Command**:
  ```bash
  bundle exec jekyll build --future
  ```
- **Local Preview Command**:
  ```bash
  bundle exec jekyll serve --livereload
  ```

---

## 3. Pre-Flight Verification Checklist

Before declaring any post or code modification complete, agents must execute and verify the following gates:

```bash
# 1. Verify Jekyll builds without errors or missing layout dependencies
# (Use --future if validating future-dated scheduled drafts)
bundle exec jekyll build --future

# 2. Run the automated pre-publish SEO and Frontmatter check
python3 .agents/skills/seo-content-optimizer/scripts/prepublish_check.py _posts/YYYY-MM-DD-<slug>.md

# 3. Check Git status to verify clean modifications
git status
```

---

## 4. Conflict Resolution & Precedence

If instructions from user prompts, skills, or subagents conflict:
1. **Explicit Global Rules & Agent Constitution** take absolute precedence.
2. **Technical Correctness & Safety** take precedence over convenience or aesthetic brevity.
3. **Canonical Blog Integrity** takes precedence over downstream distribution hacks.

When in doubt, pause execution, present evidence and trade-offs, and request direction from the human maintainer.
