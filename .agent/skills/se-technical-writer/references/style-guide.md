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

## Common Pitfalls to Avoid

- **Content Issues**: Implementation before problem explanation, assuming too much knowledge, missing the "so what?".
- **Technical Issues**: Untested code, outdated versions, platform-specific assumptions without notice.
- **Writing Issues**: Passive voice, jargon without definitions, walls of text.

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
- Include series navigation.

### Architecture Documentation
- ADRs (Architecture Decision Records) - use template in references/templates.md.
- System design documents with visual diagrams references.
- Performance benchmarks with methodology.
- Security considerations with threat models.

### User Guides and Documentation
- Task-oriented user guides.
- Installation and setup documentation.
- Feature-specific how-to guides.
- Admin and configuration guides.
