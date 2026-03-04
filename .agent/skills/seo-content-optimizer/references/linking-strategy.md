# Linking Strategy Guide

This document defines the internal and external linking practices for blog posts on [rbbtsn0w.me](https://rbbtsn0w.me) to maximize SEO equity distribution and reader engagement.

---

## Why Linking Matters for SEO

- **Internal links** help search engines discover and rank all your pages. They distribute "link equity" (ranking power) across your site.
- **Descriptive anchor text** tells search engines what the linked page is about — it's a ranking signal.
- **External links** to authoritative sources signal content credibility and topical depth.
- **Orphan pages** (pages with zero internal links pointing to them) are nearly invisible to search engines.

---

## Internal Linking Rules

### Minimum Requirements
- Every blog post MUST contain **at least 2 internal links** to other posts on the site.
- Internal links should point to **topically related** content (not random posts).

### Anchor Text Best Practices

| ✅ Do | ❌ Don't |
|-------|---------|
| `[MCP Apps 实战指南](/posts/mcp-apps-guide/)` | `[点击这里](/posts/mcp-apps-guide/)` |
| `[如何配置 Xcode 的 Agentic Coding](/posts/agentic-coding-xcode-gemini-01-overview/)` | `[阅读更多](/posts/agentic-coding-xcode-gemini-01-overview/)` |
| `[CocoaPods 源码分析](/posts/CocoaPodsSourceCode/)` | `[这篇文章](/posts/CocoaPodsSourceCode/)` |

**Rules**:
- Anchor text MUST be descriptive — it should tell both the reader and search engines what the target page is about.
- Include a relevant keyword in the anchor text when natural.
- Never use generic phrases: "click here", "read more", "this article", "see here".
- Vary anchor text — don't use the exact same text for every link to the same page.

### Placement Strategy
- **High-value positions**: Links in the first 2-3 paragraphs carry more SEO weight.
- **Contextual relevance**: Place links where they naturally extend the reader's curiosity.
- **Avoid cluster bombing**: Don't cram all internal links into a single paragraph or footer section.

---

## Series Article Linking

For multi-part article series (e.g., the "Agentic Coding in Xcode" trilogy):

### Navigation Block (Required)
Place at **both the top and bottom** of each series post:

```markdown
**系列导航：**
- [第 1 篇：从概念到可运行环境](/posts/agentic-coding-xcode-gemini-01-overview/)
- [第 2 篇：一条 Prompt 做出可玩的 iOS Demo](/posts/agentic-coding-xcode-gemini-02-hands-on/)
- **第 3 篇（本文）：排障清单、兼容性与团队协作**
```

### Cross-referencing Rules
- Each part MUST link to all other parts in the series.
- Reference previous parts inline where concepts build on each other.
- The final part should link back to Part 1 for readers who discover the series mid-way.

---

## External Linking Rules

### When to Link Externally
- Official documentation of tools, libraries, or protocols mentioned.
- GitHub repositories, issues, or PRs that provide context.
- Research papers or blog posts that inspired the content.

### How to Link Externally
- Use `target="_blank"` and `rel="noopener"` for security and UX:
  ```markdown
  [MCP Apps 官方指南](https://modelcontextprotocol.io/docs/extensions/apps){:target="_blank" rel="noopener"}
  ```
- Link to the **most specific page** (not just the homepage).
- Prefer linking to **stable URLs** (versioned docs, permalinks) over pages that may change.

### External Link Limits
- 3-8 external links per post is typical.
- Too many external links dilute your page's authority — be selective.

---

## Topic Clusters

Organize site content into **topic clusters** to build topical authority. Each cluster has a **pillar page** (broad topic) and **cluster pages** (specific subtopics) that interlink.

### Current Site Topic Map

| Cluster | Pillar Candidate | Related Posts |
|---------|-----------------|---------------|
| **AI Coding Tools** | `mastering-antigravity-agents` | `UseAITools`, `GithubCopilot`, `mastering-copilot-customization`, `ai-coding-evolution-copilot-vs-antigravity` |
| **Agentic Coding** | `agentic-coding-xcode-gemini-01-overview` | `02-hands-on`, `03-troubleshooting`, `clawdbot-rise` |
| **MCP Ecosystem** | `mcp-apps-guide` | `mcp-registry-deployment-guide` |
| **iOS/Xcode** | `XcodewithCodeSigning` | `DebugMemoryGrahp`, `DeepMemory`, `SymbolsWithInstuments`, `TrapAndWatchDog`, `SwiftPOP`, `Objective-CToSwift` |
| **CI/CD & DevOps** | `ci-cd-best-practices` | `SemanticVersioning`, `CocoaPodsForPostInstall`, `CocoaPodsSourceCode`, `GithubFreeTLS` |

### How to Use This Map
- When writing a new post, check which cluster it belongs to and add internal links to other posts in the same cluster.
- Pillar pages should link to ALL cluster pages.
- Cluster pages should link back to the pillar page and to 1-2 sibling pages.

---

## Link Audit Reminders

Periodically (e.g., monthly or when publishing new content):
- [ ] Check for **orphan pages**: posts with zero incoming internal links
- [ ] Check for **broken links**: URLs that return 404
- [ ] Check for **outdated external links**: docs that have moved or been deprecated
- [ ] Update topic cluster map when new posts are added
