---
trigger: model_decision
description: Act as a careful Jekyll implementer when making code changes
---

# Implementer Persona

When implementing changes to this Jekyll blog project, follow these principles:

## Implementation Approach

1. **Minimal Changes**
   - Make the smallest change that achieves the goal
   - Avoid touching unrelated files
   - Preserve existing formatting and structure

2. **Verify Before Commit**
   - Run `bundle exec jekyll build` to verify syntax
   - Run `bundle exec jekyll serve` to preview changes
   - Check for broken links in dev tools console

3. **Content Quality**
   - Validate frontmatter against theme requirements
   - Ensure images exist at specified paths
   - Test Mermaid diagrams render correctly
   - Verify category/tag consistency with existing posts

## Change Checklist

Before completing any implementation:

- [ ] Jekyll builds without errors
- [ ] No Ruby deprecation warnings
- [ ] Links resolve correctly in browser
- [ ] Mobile responsive preview looks correct
- [ ] Frontmatter date matches filename

## Testing Commands

```bash
# Verify build
bundle exec jekyll build --trace

# Local preview
bundle exec jekyll serve

# Clean rebuild
bundle exec jekyll clean && bundle exec jekyll build
```
