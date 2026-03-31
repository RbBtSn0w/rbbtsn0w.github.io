# Research: Article Language Toggle

## Decision: Implementation Strategy

### What was chosen
- **Technology**: Google Cloud Translation API (Professional) via Client-side JavaScript.
- **UI Component**: A custom floating action button or a sidebar link (to be decided in design).
- **Persistence**: `localStorage` to remember language preference.
- **Security**: The API key will be embedded in JS but restricted to `rbbtsn0w.github.io` domain in the Google Cloud Console.

### Rationale
- The user specifically requested "Google Translate API capabilities".
- GitHub Pages is a static host, so we cannot use a backend proxy without external services (like Vercel/Netlify).
- Domain-restricting the API key is the standard "static site" security measure for Google Cloud APIs.
- Custom implementation allows for a premium, integrated feel compared to the legacy Google Translate widget.

### Alternatives Considered
- **Google Translate Element (Dropdown)**: Rejected because it's deprecated, looks "cheap," and doesn't provide the "premium" feel requested in the system prompt.
- **Jekyll-Polyglot (Manual translation)**: The user explicitly asked for "Google Translate API" to handle the translation dynamically.

## Decision: Chirpy Theme Integration

### What was chosen
- **Hook Point**: `_includes/metadata-hook.html` for loading the translation JS and CSS.
- **Article Selection**: Target the main article body (typically `.post-content` or `article` in Chirpy).
- **Button Placement**: Top of the post header (next to date/categories) or a fixed button in the sidebar.

### Rationale
- `metadata-hook.html` is the supported way for users to add custom code to Chirpy without overriding core files.
- Placing the toggle near the article title ensures high discoverability.

## Decision: Translation Logic

### What was chosen
- **Recursive DOM Walker**: A script that walks the DOM tree of the article, translating text nodes while ignoring `<code>`, `<pre>`, and Mermaid diagram blocks.
- **Loading State**: A subtle overlay or spinner on the article while the API is processing.

### Rationale
- Preserving technical content (code/diagrams) is critical (Constitution Principle I).
- Preventing layout shifts is a Success Criterion (SC-002).
