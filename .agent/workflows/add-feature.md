---
description: Add a new feature or component to the Jekyll blog
---

# Add Feature Workflow

Use `/add-feature` to add new functionality to the blog.

## 1. Requirements Gathering

- Clarify the feature scope with the user
- Identify affected files (config, includes, posts, assets)
- Check Chirpy theme documentation for built-in support

## 2. Plan Implementation

Document the approach:
- List files to create/modify
- Identify any new dependencies (gems)
- Note configuration changes in `_config.yml`

## 3. Implement Changes

// turbo
```bash
# Create a backup branch
git checkout -b feature/your-feature-name
```

Make changes following the style guide:
- Add new includes to `_includes/`
- Add custom styles to `assets/css/`
- Update `_config.yml` if needed

## 4. Verify Changes

// turbo
```bash
# Build the site
bundle exec jekyll build --trace
```

// turbo
```bash
# Preview locally
bundle exec jekyll serve
```

Check in browser:
- Feature works as expected
- No console errors
- Mobile responsive
- No broken links

## 5. Finalize

// turbo
```bash
# Stage and commit
git add .
git commit -m "feat: add [feature description]"
```

Provide summary to user with:
- Files changed
- How to use the new feature
- Any manual testing needed
