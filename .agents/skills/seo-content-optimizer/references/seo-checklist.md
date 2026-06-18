# SEO Pre-Publish Checklist

Use this checklist before publishing any public-facing blog post or documentation page. Each item directly impacts search engine ranking or click-through rate.

---

## 1. Jekyll Publishability

- [ ] **File path**: Blog post lives at `_posts/YYYY-MM-DD-<slug>.md`
- [ ] **Filename date**: Prefix matches the intended publish date
- [ ] **Slug**: Expected URL is `/posts/<slug>/`
- [ ] **Generated output**: Local or CI build produces `_site/posts/<slug>/index.html`
- [ ] **Rendered validation**: `python3 .agent/skills/seo-content-optimizer/scripts/prepublish_check.py <post>` passes after `jekyll build`

---

## 2. Frontmatter Completeness

| Field | Requirement | Status |
|-------|-------------|--------|
| `title` | Concise, unique, accurate, and compelling for CTR | [ ] |
| `date` | Valid ISO 8601 format | [ ] |
| `description` | One or two concise sentences, accurate, contains the topic naturally | [ ] |
| `categories` | 1-2 categories from site taxonomy | [ ] |
| `tags` | 3-6 relevant tags, includes primary topic and related terms | [ ] |
| `image` | Cover image path with descriptive alt text (recommended) | [ ] |
| `mermaid` | `true` when the post body contains Mermaid diagrams | [ ] |

> See [Frontmatter Specification](frontmatter-spec.md) for detailed field-by-field guidance.

---

## 3. Content Structure

- [ ] **Single H1**: Only one H1 tag in the entire page (the post title)
- [ ] **Heading hierarchy**: H1 → H2 → H3 (no skipped levels)
- [ ] **No body H1**: Jekyll posts do not include Markdown `#` headings in the body
- [ ] **Mermaid rendering**: Posts with ` ```mermaid` fences set `mermaid: true` in frontmatter
- [ ] **Topic in H2**: At least 1-2 H2 headings naturally clarify the target topic
- [ ] **Opening relevance**: The opening paragraph quickly confirms the topic and reader value
- [ ] **Snippet-friendly**: A concise direct answer is present when it helps the reader
- [ ] **Short paragraphs**: No paragraph exceeds 4 sentences (critical for mobile UX)
- [ ] **Scannable format**: Key information in lists, tables, or bold text — not buried in prose

---

## 4. Query Vocabulary

- [ ] **Primary query/topic** identified and used naturally where it improves clarity
- [ ] **Related queries** (2-3) reflected in headings, examples, or body text when relevant
- [ ] **No keyword stuffing**: Keywords read naturally in context
- [ ] **Domain vocabulary**: Official docs and audience language are reflected without parroting source material

---

## 5. Links

### Internal Links
- [ ] ≥ 2 links to related posts on the same site
- [ ] Anchor text is descriptive (NOT "click here", "read more", "this article")
- [ ] Links point to relevant, high-value pages

### External Links
- [ ] Reference links point to authoritative, up-to-date sources
- [ ] External links use `target="_blank"` and `rel="noopener"`

### Series Links
- [ ] Navigation block present at top AND bottom (if part of a series)
- [ ] All parts of the series are linked

### Link Health
- [ ] No broken links (verify all URLs resolve)
- [ ] No orphan pages (every post is linked from at least one other post)
- [ ] Rendered HTML links are checked, not only Markdown source links

---

## 6. Multimedia & Accessibility

- [ ] **Alt text**: Every image has a descriptive `alt` attribute (include keyword where natural)
- [ ] **File naming**: Image files use descriptive, kebab-case names (e.g., `mcp-architecture-diagram.png`)
- [ ] **File location**: Images stored in `/assets/img/post/<slug>/`
- [ ] **Captions**: Complex diagrams have explanatory captions
- [ ] **File size**: Images are optimized for web (< 200KB for standard images)
- [ ] **No missing visuals**: If cover images or illustrations are unavailable, use AI generation tools (e.g., Gemini `generate_image`) to create them — no post should ship with empty placeholders

---

## 7. Technical SEO

- [ ] **Slug**: URL path is short, descriptive, and contains primary keyword
- [ ] **Canonical URL**: Correct if cross-posting to other platforms
- [ ] **Search index**: `_site/assets/js/data/search.json` includes the post URL
- [ ] **Sitemap**: `_site/sitemap.xml` includes the canonical URL
- [ ] **Open Graph**: Rendered HTML has title, description, URL, and image metadata
- [ ] **Mobile-friendly**: Short paragraphs, responsive images, no horizontal scroll
- [ ] **Page speed**: No unnecessary large assets embedded inline

---

## 8. Engagement Signals

- [ ] **Compelling title**: Would you click this in search results?
- [ ] **Meta description**: Does it promise a clear benefit?
- [ ] **TL;DR / Key takeaway**: Present for content longer than 1000 words
- [ ] **Call-to-action**: Post ends with a next step (related reading, action item, or comment prompt)
