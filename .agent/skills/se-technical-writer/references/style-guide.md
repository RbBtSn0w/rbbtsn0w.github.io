# Technical Writing Style Guide

## Writing Principles

### Clarity First
- Use simple words for complex ideas.
- Define technical terms on first use.
- One main idea per paragraph.
- Short sentences when explaining difficult concepts.

### Structure and Flow
- Start with the "why" before the "how".
- Use progressive disclosure (simple → complex).
- Include signposting ("First...", "Next...", "Finally...").
- Provide clear transitions between sections.

### Engagement Techniques
- Open with a hook that establishes relevance.
- Use concrete examples over abstract explanations.
- Include "lessons learned" and failure stories.
- End sections with key takeaways.

### Technical Accuracy
- Verify all code examples compile/run.
- Ensure version numbers and dependencies are current.
- Cross-reference official documentation.
- Include performance implications where relevant.

---

## Style Guidelines

### Voice and Tone
- **Active voice**: "The function processes data" not "Data is processed by the function".
- **Direct address**: Use "you" when instructing.
- **Inclusive language**: Use "we" for discoveries or team-based actions.
- **Confident but humble**: State facts clearly, avoid hyperbole.

### Technical Elements
- **Code blocks**: Always include language identifier (e.g., ```python).
- **Command examples**: Show both command and expected output.
- **File paths**: Use consistent relative or absolute paths.
- **Versions**: Include version numbers for all tools/libraries.

### Formatting Conventions
- **Headers**: Title Case for Levels 1-2, Sentence case for Levels 3+.
- **Lists**: Bullets for unordered, numbers for sequences.
- **Emphasis**: Bold for UI elements, italics for first use of terms.
- **Code**: Backticks for inline, fenced blocks for multi-line.

---

## Terminology Consistency

Consistent terminology is critical for reader comprehension and professional quality.

### Rules
- **Define once, use everywhere**: When a term is introduced, include a brief definition. Use only that term throughout the entire article (and series).
- **Avoid synonym drift**: Do not switch between synonyms for the same concept (e.g., do not alternate between "component", "module", and "widget" for the same thing).
- **Terminology table**: For long-form content or article series, maintain a simple table at planning time:

| Term | Definition | Do NOT use |
|------|-----------|------------|
| Plugin | A runtime-loadable module | Extension, Add-on (unless quoting) |
| Agent | An AI-powered autonomous coding assistant | Bot, AI helper |

- **Abbreviations**: Spell out on first use, then abbreviate. Example: "Model Context Protocol (MCP)".
- **Chinese-English mix**: When writing in Chinese with English technical terms, keep English terms in their original form (do not translate brand names or well-known acronyms). Example: "使用 MCP Apps 的 SDK" is correct; "使用模型上下文协议应用的软件开发套件" adds friction.

---

## Visual Communication Guide

Choosing the right visual format is as important as the text itself.

### When to use each format

| Format | Best for | Example |
|--------|----------|---------|
| **Mermaid diagram** | Architecture, data flow, state machines, decision trees | System component relationships |
| **Screenshot** | UI walkthroughs, configuration panels, error messages | IDE settings, terminal output |
| **Code block** | Implementation details, CLI commands, config files | Function definitions, YAML config |
| **Table** | Feature comparisons, option matrices, checklists | Tool comparison, API parameter reference |
| **Inline image** | Result demonstration, before/after comparison | App UI before and after a change |

### Image guidelines
- Every image MUST have a descriptive caption that explains what the reader should observe.
- Use consistent image dimensions within the same article.
- Prefer SVG or high-resolution PNG for diagrams; JPEG for photos/screenshots.
- Store images in a predictable path: `/assets/img/post/<post-slug>/`.

### AI-generated images (Gemini / generate_image)

When original images, illustrations, or cover art are **not available**, use AI image generation tools (e.g., Gemini's `generate_image`) to create them. This ensures every post has complete visual assets rather than empty placeholders.

**When to generate**:
- Cover/hero images for blog posts that lack one
- Conceptual illustrations for abstract topics (e.g., architecture overviews, workflow diagrams)
- Before/after comparison visuals when screenshots aren't available
- Decorative section headers for long-form content

**When NOT to generate**:
- Screenshots of real UIs — use actual screenshots instead
- Code output — use real terminal captures
- Logos or brand assets — always use official versions

**Generation rules**:
- Write a detailed, descriptive prompt that matches the article's technical context
- Save generated images to `/assets/img/post/<post-slug>/` with descriptive kebab-case filenames
- Always add a descriptive alt text and caption to the generated image
- If the image is AI-generated for illustration purposes, transparency is encouraged (e.g., caption can note "Illustration")

---

## Multilingual Writing (Chinese-English)

For content targeting Chinese-speaking developers:

- **Punctuation**: Use Chinese punctuation（，。！？）in Chinese sentences; English punctuation in English text and code.
- **Spacing**: Add a space between Chinese characters and English words/numbers for readability. Example: "使用 Jekyll 的 `_config.yml` 配置文件".
- **Technical terms**: Keep well-known English terms untranslated (API, SDK, MCP, Git, CI/CD). Only translate when there is a widely-accepted Chinese equivalent.
- **Tone**: Maintain a conversational but professional tone — avoid overly formal written Chinese (书面语) in blog posts.

---

## Common Pitfalls to Avoid

- **Content Issues**: Implementation before problem explanation, assuming too much knowledge, missing the "so what?".
- **Technical Issues**: Untested code, outdated versions, platform-specific assumptions without notice.
- **Writing Issues**: Passive voice, jargon without definitions, walls of text.
- **Consistency Issues**: Switching terms mid-article, inconsistent header casing, mixed punctuation styles.

---

## Specialized Focus Areas

### Developer Experience (DX) Documentation
- Onboarding guides that reduce time-to-first-success.
- API documentation that anticipates common questions.
- Error messages that suggest solutions.
- Migration guides that handle edge cases.

### Technical Blog Series
- Maintain consistent voice across posts.
- Reference previous posts naturally.
- Build complexity progressively.
- Include series navigation block in every post.

### Architecture Documentation
- ADRs (Architecture Decision Records) - use template in references/templates.md.
- System design documents with visual diagrams references.
- Performance benchmarks with methodology.
- Security considerations with threat models.

### Troubleshooting Guides
- Follow the **Symptom → Root Cause → Resolution** pattern.
- Include exact error messages for searchability.
- Provide copy-pasteable fix commands.
- Link to upstream issues or PRs when applicable.

### User Guides and Documentation
- Task-oriented user guides.
- Installation and setup documentation.
- Feature-specific how-to guides.
- Admin and configuration guides.
