# SEO Pre-Publish Checklist

Use this checklist before publishing any public-facing blog post or documentation page. Each item directly impacts search engine ranking or click-through rate.

---

## 1. Frontmatter Completeness

| Field | Requirement | Status |
|-------|-------------|--------|
| `title` | ≤ 60 chars, contains primary keyword, compelling for CTR | [ ] |
| `date` | Valid ISO 8601 format | [ ] |
| `description` | 120-160 chars, contains primary keyword, promises value | [ ] |
| `categories` | 1-2 categories from site taxonomy | [ ] |
| `tags` | 3-6 relevant tags, includes primary + secondary keywords | [ ] |
| `image` | Cover image path with descriptive alt text (recommended) | [ ] |

> See [Frontmatter Specification](frontmatter-spec.md) for detailed field-by-field guidance.

---

## 2. Content Structure

- [ ] **Single H1**: Only one H1 tag in the entire page (the post title)
- [ ] **Heading hierarchy**: H1 → H2 → H3 (no skipped levels)
- [ ] **Keyword in H2**: At least 1-2 H2 headings naturally contain target keywords
- [ ] **First 100 words**: Primary keyword appears within the opening paragraph
- [ ] **Featured Snippet ready**: A 40-60 word paragraph directly answers the article's core question
- [ ] **Short paragraphs**: No paragraph exceeds 4 sentences (critical for mobile UX)
- [ ] **Scannable format**: Key information in lists, tables, or bold text — not buried in prose

---

## 3. Keyword Integration

- [ ] **Primary keyword** identified and naturally used 3-5 times across the article
- [ ] **Secondary keywords** (2-3) used in headings and body text
- [ ] **No keyword stuffing**: Keywords read naturally in context
- [ ] **LSI terms**: Related vocabulary strengthens topical authority

---

## 4. Links

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

---

## 5. Multimedia & Accessibility

- [ ] **Alt text**: Every image has a descriptive `alt` attribute (include keyword where natural)
- [ ] **File naming**: Image files use descriptive, kebab-case names (e.g., `mcp-architecture-diagram.png`)
- [ ] **File location**: Images stored in `/assets/img/post/<slug>/`
- [ ] **Captions**: Complex diagrams have explanatory captions
- [ ] **File size**: Images are optimized for web (< 200KB for standard images)
- [ ] **No missing visuals**: If cover images or illustrations are unavailable, use AI generation tools (e.g., Gemini `generate_image`) to create them — no post should ship with empty placeholders

---

## 6. Technical SEO

- [ ] **Slug**: URL path is short, descriptive, and contains primary keyword
- [ ] **Canonical URL**: Correct if cross-posting to other platforms
- [ ] **Mobile-friendly**: Short paragraphs, responsive images, no horizontal scroll
- [ ] **Page speed**: No unnecessary large assets embedded inline

---

## 7. Engagement Signals

- [ ] **Compelling title**: Would you click this in search results?
- [ ] **Meta description**: Does it promise a clear benefit?
- [ ] **TL;DR / Key takeaway**: Present for content longer than 1000 words
- [ ] **Call-to-action**: Post ends with a next step (related reading, action item, or comment prompt)
