# Data Model: Article Language Toggle

## Description
This feature uses a lightweight client-side state model to track the current language preference. No persistent database is used; instead, `localStorage` provides cross-page persistence.

### Entities

#### LanguagePreference (Client-side)
- **Status**: The currently selected language (`'zh-CN'` or `'en'`).
- **Persistence**: Saved to `localStorage.getItem('user-language')`.
- **Relationship**: Affects the article body content in the DOM.

#### ArticleContent (DOM)
- **Source**: The original HTML between `.post-content` (source of truth).
- **Cache**: The translated HTML (stored in-memory during a session to avoid repeated API calls).

### State Transitions

| Current State | Action | Next State | Effects |
|---------------|--------|------------|---------|
| Original (CN) | Click EN | Translated (EN) | Fetches translation; Injects content; Updates icon. |
| Translated (EN)| Click CN | Original (CN) | Replaces content with original; Updates icon. |
| (Any) | Page Load | (Saved Pref) | If 'en' is saved, auto-triggers translation after body is stable. |

### Validation Rules
- **Formatting**: HTML tags MUST be preserved as-is.
- **Exclusion**: Tags matching `code`, `pre`, `math`, and classes like `mermaid` MUST NOT be translated.
- **Language Codes**: MUST be valid BCP 47 language tags (e.g., `zh-CN`, `en`).
